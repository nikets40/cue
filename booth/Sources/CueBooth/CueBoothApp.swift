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

        MenuBarExtra("Cue Booth", systemImage: "music.note.tv") {
            MenuBarView()
                .environmentObject(media)
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject private var media: MediaState

    var body: some View {
        if media.nowPlaying.isEmpty {
            Text("Nothing playing")
        } else {
            Text("\(media.nowPlaying.title ?? "Untitled") — \(media.nowPlaying.artist ?? "")")
            Button(media.nowPlaying.playing ? "Pause" : "Play") {
                media.send("toggle-play-pause")
            }
            Button("Next track") { media.send("next-track") }
        }
        Divider()
        Button("Quit Cue Booth") { NSApp.terminate(nil) }
    }
}
