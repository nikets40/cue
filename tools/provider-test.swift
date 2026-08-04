import Foundation

// Impersonates the Chrome extension: connects as a provider over loopback
// (no pairing token), pushes PageMetadata for whatever is currently playing,
// then reconnects as a controller to confirm Booth adopted the artwork and
// service.
//
//   swift tools/provider-test.swift <pairing-token>

let token = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
let url = URL(string: "ws://127.0.0.1:41952")!

func nowPlayingTitle() -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/media-control")
    process.arguments = ["get", "--no-artwork"]
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    return (json?["title"] as? String) ?? ""
}

/// 1x1 red PNG — stands in for page artwork.
let testArtwork = """
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==
"""

func send(_ task: URLSessionWebSocketTask, _ json: String) {
    let semaphore = DispatchSemaphore(value: 0)
    task.send(.string(json)) { error in
        if let error { print("SEND ERR: \(error)") }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 4)
}

func receive(_ task: URLSessionWebSocketTask, timeout: TimeInterval = 4) -> String? {
    var result: String?
    let semaphore = DispatchSemaphore(value: 0)
    task.receive { outcome in
        if case .success(.string(let text)) = outcome { result = text }
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + timeout)
    return result
}

let title = nowPlayingTitle()
print("now playing: \(title.isEmpty ? "<nothing>" : title)")

// --- provider ---
let provider = URLSession.shared.webSocketTask(with: url)
provider.resume()
send(provider, #"{"token":"","role":"provider"}"#)
let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
send(provider, """
{"title":"\(escapedTitle)","artist":"Test Artist","service":"netflix",\
"artworkBase64":"\(testArtwork)","artworkMimeType":"image/png","playing":true}
""")
print("provider: sent PageMetadata (service=netflix, 1x1 png)")
Thread.sleep(forTimeInterval: 1.0)

// --- controller ---
let controller = URLSession.shared.webSocketTask(with: url)
controller.resume()
send(controller, "{\"token\":\"\(token)\"}")
guard let snapshot = receive(controller),
      let data = snapshot.data(using: .utf8),
      let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let state = message["state"] as? [String: Any]
else {
    print("FAIL: no state snapshot (is the token right?)")
    exit(1)
}

let service = state["service"] as? String
let artwork = state["artworkBase64"] as? String
print("controller sees: service=\(service ?? "nil") artwork=\(artwork == testArtwork ? "PAGE ART ✓" : "\(artwork?.count ?? 0) chars")")

let servicePassed = service == "netflix"
let artworkPassed = artwork == testArtwork
print(servicePassed && artworkPassed ? "PASS" : "FAIL")
provider.cancel(with: .goingAway, reason: nil)
controller.cancel(with: .goingAway, reason: nil)
exit(servicePassed && artworkPassed ? 0 : 1)
