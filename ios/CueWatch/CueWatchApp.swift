import SwiftUI

@main
struct CueWatchApp: App {
    @StateObject private var connector = WatchConnector()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchPlayerView()
                .environmentObject(connector)
                .onAppear { connector.activate() }
                // The watch app is suspended aggressively, and the application
                // context it holds can be several tracks out of date by the
                // time it comes back.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { connector.refresh() }
                }
        }
    }
}
