import AppKit
import SwiftUI

@main
struct CueBoothApp: App {
    @StateObject private var media = MediaState()

    init() {
        // Running from `swift run` there is no app bundle, so macOS treats us as a
        // background process; promote to a regular app so the window appears focused.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup("Cue Booth") {
            DashboardView()
                .environmentObject(media)
                .onAppear { media.start() }
        }
        .windowResizability(.contentSize)
    }
}
