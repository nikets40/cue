import Foundation

// Usage: swift wstest.swift ws://host:port ['{"action":"pause"}']
let url = URL(string: CommandLine.arguments[1])!
let commandJSON = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : nil

let task = URLSession.shared.webSocketTask(with: url)
let sem = DispatchSemaphore(value: 0)

func printState(_ text: String) {
    guard let data = text.data(using: .utf8),
          var obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { print("RECV (raw): \(text.prefix(300))"); return }
    if var state = obj["state"] as? [String: Any] {
        if let artwork = state["artworkBase64"] as? String {
            state["artworkBase64"] = "<\(artwork.count) chars>"
        }
        obj["state"] = state
    }
    let compact = (try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys])).map {
        String(decoding: $0, as: UTF8.self)
    } ?? "\(obj)"
    print("RECV: \(compact)")
}

func receiveOnce() {
    task.receive { result in
        switch result {
        case .success(.string(let text)): printState(text)
        case .success: print("RECV: <non-text frame>")
        case .failure(let error): print("ERR: \(error.localizedDescription)")
        }
        sem.signal()
    }
}

task.resume()
receiveOnce()
if sem.wait(timeout: .now() + 5) == .timedOut { print("TIMEOUT waiting for snapshot"); exit(1) }

if let commandJSON {
    task.send(.string(commandJSON)) { error in
        print(error.map { "SEND ERR: \($0)" } ?? "SENT: \(commandJSON)")
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 5)
    receiveOnce() // state update triggered by the command
    if sem.wait(timeout: .now() + 5) == .timedOut { print("TIMEOUT waiting for update") }
}
task.cancel(with: .goingAway, reason: nil)
