import Foundation

/// QuickTime Player doesn't register with macOS Now Playing at all — nothing
/// about it reaches MediaRemote — so it's driven entirely through AppleScript.
/// Requires the one-time Automation approval ("Cue Booth wants to control
/// QuickTime Player"); until it's granted every call simply returns nil.
@MainActor
final class QuickTimeClient {
    static let bundleIdentifier = "com.apple.QuickTimePlayerX"

    struct State: Equatable {
        var title: String
        var playing: Bool
        var position: Double
        var duration: Double
    }

    enum Action {
        case play
        case pause
        case togglePlayPause
        case seek(Double)
        case skip(Double)
    }

    /// Skipped while a command is in flight so a slow AppleScript round trip
    /// can't queue up behind itself.
    private var busy = false

    func fetchState() async -> State? {
        guard !busy else { return nil }
        return await Self.run(Self.stateScript).flatMap(Self.parse)
    }

    func perform(_ action: Action) {
        busy = true
        Task { [weak self] in
            _ = await Self.run(Self.script(for: action))
            self?.busy = false
        }
    }

    // MARK: - Scripts

    /// One round trip for everything the client needs; `playing` is reported
    /// as a rate, since a paused document still answers most properties.
    private static let stateScript = """
    tell application "QuickTime Player"
      if (count of documents) is 0 then return "none"
      set d to document 1
      return (name of d) & "\\t" & (playing of d) & "\\t" & ((current time of d) as integer) \
        & "\\t" & ((duration of d) as integer)
    end tell
    """

    private static func script(for action: Action) -> String {
        let body: String
        switch action {
        case .play:
            body = "play d"
        case .pause:
            body = "pause d"
        case .togglePlayPause:
            // AppleScript has no single-line if/else form; it must be a block.
            body = """
            if playing of d then
              pause d
            else
              play d
            end if
            """
        case .seek(let seconds):
            body = "set current time of d to \(max(0, Int(seconds)))"
        case .skip(let delta):
            body = """
            set target to ((current time of d) as integer) + (\(Int(delta)))
            if target < 0 then set target to 0
            if target > ((duration of d) as integer) then set target to ((duration of d) as integer)
            set current time of d to target
            """
        }
        return """
        tell application "QuickTime Player"
          if (count of documents) is 0 then return "none"
          set d to document 1
          \(body)
        end tell
        """
    }

    private static func parse(_ output: String) -> State? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != "none" else { return nil }
        let parts = trimmed.components(separatedBy: "\t")
        guard parts.count >= 4, let position = Double(parts[2]), let duration = Double(parts[3])
        else { return nil }
        return State(
            title: parts[0],
            playing: parts[1] == "true",
            position: position,
            duration: duration)
    }

    nonisolated private static func run(_ source: String) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", source]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                guard (try? process.run()) != nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: String(decoding: data, as: UTF8.self))
            }
        }
    }
}
