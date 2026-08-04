import SwiftUI

@main
struct CueApp: App {
    @StateObject private var client = CueClient()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client)
                .onAppear { client.startBrowsing() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { client.reconnectIfNeeded() }
                }
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
        case .needsPairing(let name):
            PairingView(boothName: name)
        case .browsing, .failed:
            DiscoveryView()
        }
    }
}

struct PairingView: View {
    @EnvironmentObject private var client: CueClient
    @FocusState private var focused: Bool
    @State private var code = ""

    let boothName: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.radiowaves.forward.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Pair with \(boothName)").font(.title3.bold())
            Text("Enter the 6-digit pairing code shown in the Cue Booth window on your Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            TextField("000000", text: $code)
                .keyboardType(.numberPad)
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .multilineTextAlignment(.center)
                .focused($focused)
                .frame(width: 200)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
            Button("Pair") { client.submitPairingCode(code) }
                .buttonStyle(.borderedProminent)
                .disabled(code.trimmingCharacters(in: .whitespaces).count != 6)
        }
        .padding(32)
        .onAppear { focused = true }
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
