import Foundation

// Usage: swift wstest.swift ws://host:port [pairing-token] ['{"action":"pause"}']
// With a token: sends ClientHello first, then expects a snapshot (or authFailed).
// Without: connects silently — the server should send nothing.
let url = URL(string: CommandLine.arguments[1])!
let token = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil
let commandJSON = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : nil

let task = URLSession.shared.webSocketTask(with: url)
let sem = DispatchSemaphore(value: 0)

func printMessage(_ text: String) {
    guard let data = text.data(using: .utf8),
          var obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { print("RECV (raw): \(text.prefix(300))"); return }
    if var state = obj["state"] as? [String: Any] {
        // Report the real length under a separate key — replacing the value
        // with a placeholder string makes len() lie about the artwork size.
        if let artwork = state["artworkBase64"] as? String {
            state["artworkBase64"] = nil
            state["artworkBase64Length"] = artwork.count
        }
        obj["state"] = state
    }
    let compact = (try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])).map {
        String(decoding: $0, as: UTF8.self)
    } ?? "\(obj)"
    print("RECV: \(compact)")
}

func receiveOnce(timeoutLabel: String) -> Bool {
    task.receive { result in
        switch result {
        case .success(.string(let text)): printMessage(text)
        case .success: print("RECV: <non-text frame>")
        case .failure(let error): print("ERR: \(error.localizedDescription)")
        }
        sem.signal()
    }
    if sem.wait(timeout: .now() + 4) == .timedOut {
        print("TIMEOUT: \(timeoutLabel)")
        return false
    }
    return true
}

func send(_ json: String) {
    task.send(.string(json)) { error in
        print(error.map { "SEND ERR: \($0)" } ?? "SENT: \(json)")
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 4)
}

task.resume()
if let token {
    send("{\"token\":\"\(token)\"}")
    guard receiveOnce(timeoutLabel: "no reply to hello") else { exit(1) }
    if let commandJSON {
        send(commandJSON)
        _ = receiveOnce(timeoutLabel: "no state update after command")
    }
} else {
    _ = receiveOnce(timeoutLabel: "server stayed silent for unauthenticated client (expected)")
}
task.cancel(with: .goingAway, reason: nil)
