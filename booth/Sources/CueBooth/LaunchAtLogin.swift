import Foundation

/// Launch-at-login via a user LaunchAgent. SMAppService needs an app bundle,
/// which this SPM executable doesn't have, so a LaunchAgent plist pointing at
/// the current binary is used instead. Re-toggle after moving the binary.
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
        let binaryPath = ProcessInfo.processInfo.arguments[0]
        let plist: [String: Any] = [
            "Label": Self.label,
            "ProgramArguments": [(binaryPath as NSString).standardizingPath],
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
