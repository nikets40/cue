import SwiftUI

@main
struct CueApp: App {
    @StateObject private var client = CueClient()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client)
                .onAppear { client.startBrowsing() }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var client: CueClient

    var body: some View {
        switch client.phase {
        case .connected:
            RemoteView()
        case .connecting(let name):
            VStack(spacing: 12) {
                ProgressView()
                Text("Connecting to \(name)…").foregroundStyle(.secondary)
            }
        case .browsing, .failed:
            DiscoveryView()
        }
    }
}

struct DiscoveryView: View {
    @EnvironmentObject private var client: CueClient

    var body: some View {
        NavigationStack {
            List {
                if case .failed(let message) = client.phase {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
                Section("Found on your network") {
                    if client.booths.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Looking for Cue Booth…").foregroundStyle(.secondary)
                        }
                    }
                    ForEach(client.booths) { booth in
                        Button {
                            client.connect(to: booth)
                        } label: {
                            Label(booth.name, systemImage: "desktopcomputer")
                        }
                    }
                }
            }
            .navigationTitle("Cue")
        }
    }
}
