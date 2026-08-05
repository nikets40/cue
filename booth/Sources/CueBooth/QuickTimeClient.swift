import AVFoundation
import AppKit
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
        var path: String?
    }

    struct Thumbnail {
        let base64: String
        let image: NSImage
    }

    enum Action {
        case play
        case pause
        case togglePlayPause
        case seek(Double)
        case skip(Double)
        /// QuickTime calls fullscreen "presenting".
        case toggleFullscreen
    }

    /// Skipped while a command is in flight so a slow AppleScript round trip
    /// can't queue up behind itself.
    private var busy = false

    func fetchState() async -> State? {
        guard !busy else { return nil }
        return await Self.run(Self.stateScript).flatMap(Self.parse)
    }

    struct Document: Equatable {
        var index: Int
        var name: String
        var playing: Bool
    }

    /// Every open document, so paused ones can still be listed and picked.
    func documents() async -> [Document] {
        guard let output = await Self.run(Self.documentsScript) else { return [] }
        return output
            .split(separator: "\n")
            .compactMap { line in
                let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: "\t")
                guard parts.count >= 3, let index = Int(parts[0]) else { return nil }
                return Document(index: index, name: parts[1], playing: parts[2] == "true")
            }
    }

    func activate(index: Int) {
        busy = true
        Task { [weak self] in
            _ = await Self.run("""
            tell application "QuickTime Player"
              activate
              if (count of documents) ≥ \(index) then play document \(index)
            end tell
            """)
            self?.busy = false
        }
    }

    private static let documentsScript = """
    tell application "QuickTime Player"
      set out to ""
      set i to 1
      repeat with d in documents
        set out to out & i & "\\t" & (name of d) & "\\t" & (playing of d) & "\\n"
        set i to i + 1
      end repeat
      return out
    end tell
    """

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
      set p to ""
      try
        set p to POSIX path of (get file of d)
      end try
      return (name of d) & "\\t" & (playing of d) & "\\t" & ((current time of d) as integer) \
        & "\\t" & ((duration of d) as integer) & "\\t" & p
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
        case .toggleFullscreen:
            body = """
            activate
            if presenting of d then
              set presenting of d to false
            else
              present d
            end if
            """
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
        let path = parts.count > 4 ? parts[4] : ""
        return State(
            title: parts[0],
            playing: parts[1] == "true",
            position: position,
            duration: duration,
            path: path.isEmpty ? nil : path)
    }

    /// A representative frame, taken 10% in so an opening fade-from-black
    /// doesn't produce an empty thumbnail. Cached per file.
    private var thumbnails: [String: Thumbnail] = [:]
    private var thumbnailMisses: Set<String> = []

    func thumbnail(for path: String) -> Thumbnail? {
        if let hit = thumbnails[path] { return hit }
        guard !thumbnailMisses.contains(path) else { return nil }
        thumbnailMisses.insert(path)  // one attempt per file
        Task { [weak self] in
            guard let made = await Self.makeThumbnail(path: path) else { return }
            self?.thumbnails[path] = made
            self?.onThumbnail?(path, made)
        }
        return nil
    }

    var onThumbnail: ((String, Thumbnail) -> Void)?

    nonisolated private static func makeThumbnail(path: String) async -> Thumbnail? {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 640, height: 640)
        guard let duration = try? await asset.load(.duration) else { return nil }
        let seconds = CMTimeGetSeconds(duration)
        guard seconds.isFinite, seconds > 0 else { return nil }
        let at = CMTime(seconds: max(1, seconds * 0.1), preferredTimescale: 600)
        guard let (cgImage, _) = try? await generator.image(at: at) else { return nil }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let jpeg = bitmap.representation(
            using: .jpeg, properties: [.compressionFactor: 0.8])
        else { return nil }
        return Thumbnail(
            base64: jpeg.base64EncodedString(),
            image: NSImage(cgImage: cgImage, size: .zero))
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
