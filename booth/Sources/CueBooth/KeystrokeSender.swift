import AppKit
import ApplicationServices

/// Sends real keystrokes to another app.
///
/// This exists because of a hard browser rule: Chrome grants video fullscreen
/// only to *trusted* user input. Nothing originating inside an extension
/// qualifies — `requestFullscreen()` fails with a permissions error, and a
/// scripted click on the player's own fullscreen button is ignored just the
/// same. But that restriction is about the page's own JavaScript, not about
/// the machine. A `CGEvent` posted to the HID tap enters through the OS input
/// stack, so Chrome cannot tell it from a physical keypress and honours it.
///
/// Verified on a live YouTube player: the page's own keydown listener reported
/// `isTrusted: true` and the video entered real fullscreen.
///
/// The cost is an Accessibility grant, which the user makes once in System
/// Settings and can revoke at any time.
enum KeystrokeSender {
    /// kVK_ANSI_F. "f" is the fullscreen shortcut on YouTube, Netflix, Prime
    /// Video and Hotstar alike, so one key covers every supported site.
    static let fKey: CGKeyCode = 0x03

    static var hasAccessibilityPermission: Bool { AXIsProcessTrusted() }

    /// Asks macOS to show the "grant Accessibility" prompt. Returns the
    /// current state, which is false until the user acts on the dialog — the
    /// grant never lands during this call.
    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Brings `bundleIdentifier` forward and posts `key` to it.
    ///
    /// The key goes to whatever is frontmost, so the caller must already have
    /// focused the right tab and window — otherwise the keystroke lands
    /// somewhere unintended. Returns false when Accessibility is not granted
    /// or the app isn't running.
    /// Async rather than blocking: callers run on the main actor, and sleeping
    /// there would stall the dashboard and queue every inbound websocket
    /// message behind this call.
    @discardableResult
    static func send(key: CGKeyCode, to bundleIdentifier: String) async -> Bool {
        guard hasAccessibilityPermission else { return false }
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).first else { return false }

        // Only activate when Chrome isn't already frontmost. The extension has
        // just raised the correct window, and activating again can re-raise
        // whichever window Chrome itself considers frontmost, undoing that.
        if !app.isActive {
            app.activate(options: [])
            // Activation is asynchronous; posting immediately can deliver the
            // key to the previously frontmost app.
            try? await Task.sleep(for: .milliseconds(250))
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        else { return false }
        // An event from a HID-state source inherits whatever modifiers are
        // physically held, which would turn "f" into ⌘F.
        down.flags = []
        up.flags = []
        down.post(tap: .cghidEventTap)
        try? await Task.sleep(for: .milliseconds(50))
        up.post(tap: .cghidEventTap)
        return true
    }
}
