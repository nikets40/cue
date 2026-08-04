import Foundation

/// Figures out which streaming service owns the current track. Non-browser
/// sources map straight from their bundle ID. For Chrome, the now-playing
/// title is matched against open tab titles via AppleScript (may show a
/// one-time Automation permission prompt); failure degrades to nil.
@MainActor
final class ServiceDetector {
    var onDetect: ((_ trackKey: String, _ service: String) -> Void)?

    private var cache: [String: String?] = [:]
    private var inflight: Set<String> = []

    nonisolated private static let hostMap: [(fragment: String, service: String)] = [
        ("music.youtube.", "ytmusic"),
        ("youtube.", "youtube"),
        ("netflix.", "netflix"),
        ("primevideo.", "prime"),
        ("amazon.", "prime"),
        ("hotstar.", "hotstar"),
        ("spotify.", "spotify"),
    ]

    func detect(trackKey: String, title: String, bundleIdentifier: String) -> String? {
        switch bundleIdentifier {
        case "org.videolan.vlc": return "vlc"
        case "com.spotify.client": return "spotify"
        case "com.google.Chrome": break
        default: return nil
        }
        if let cached = cache[trackKey] { return cached }
        guard !inflight.contains(trackKey) else { return nil }
        inflight.insert(trackKey)
        Task.detached { [weak self] in
            let service = Self.detectViaChromeTabs(title: title)
            Task { @MainActor in
                guard let self else { return }
                self.inflight.remove(trackKey)
                self.cache[trackKey] = service
                if let service { self.onDetect?(trackKey, service) }
            }
        }
        return nil
    }

    nonisolated private static func detectViaChromeTabs(title: String) -> String? {
        let script = """
        tell application "Google Chrome"
            set out to ""
            repeat with w in windows
                repeat with t in tabs of w
                    set out to out & (URL of t) & tab & (title of t) & linefeed
                end repeat
            end repeat
        end tell
        return out
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        let needle = title.lowercased()
        var fallbackHost: String?
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1)
            guard let url = parts.first.map(String.init),
                  let host = URL(string: url)?.host?.lowercased()
            else { continue }
            let tabTitle = parts.count > 1 ? String(parts[1]).lowercased() : ""
            guard let match = hostMap.first(where: { host.contains($0.fragment) })?.service
            else { continue }
            if !needle.isEmpty, tabTitle.contains(needle) { return match }
            if fallbackHost == nil { fallbackHost = match }
        }
        // No title match — if exactly one known service is open, assume it.
        return fallbackHost
    }
}
