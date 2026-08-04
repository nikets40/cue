import Foundation

/// Launch-at-login via a user LaunchAgent pointing at the running executable.
/// Works both for `swift run` (debug binary path) and for the packaged
/// Cue Booth.app; re-toggle after moving or repackaging the app.
@MainActor
final class LaunchAtLogin: ObservableObject {
    static let label = "com.niket.cuebooth"

    @Published private(set) var enabled: Bool

    private static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    init() {
        enabled = FileManager.default.fileExists(atPath: Self.plistURL.path)
    }

    func toggle() {
        enabled ? disable() : enable()
    }

    private func enable() {
        // Inside a bundle, launch via the bundle so LaunchServices treats it
        // as the app (stable identity for TCC) rather than a loose binary.
        let arguments: [String]
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension == "app" {
            arguments = ["/usr/bin/open", "-a", bundleURL.path]
        } else {
            let binaryPath = (ProcessInfo.processInfo.arguments[0] as NSString).standardizingPath
            arguments = [URL(fileURLWithPath: binaryPath).standardizedFileURL.path]
        }
        let plist: [String: Any] = [
            "Label": Self.label,
            "ProgramArguments": arguments,
            "RunAtLoad": true,
        ]
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try FileManager.default.createDirectory(
                at: Self.plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: Self.plistURL)
            enabled = true
        } catch {
            enabled = false
        }
    }

    private func disable() {
        launchctl("bootout", "gui/\(getuid())/\(Self.label)")
        try? FileManager.default.removeItem(at: Self.plistURL)
        enabled = false
    }

    private func launchctl(_ arguments: String...) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        try? process.run()
        process.waitUntilExit()
    }
}
