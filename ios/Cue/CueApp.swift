import SwiftUI

@main
struct CueApp: App {
    @StateObject private var client = CueClient()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(client)
                .onAppear {
                    client.startBrowsing()
                    client.onStateUpdate = { [weak client] in
                        guard let client else { return }
                        var boothName: String?
                        if case .connected(let name) = client.phase { boothName = name }
                        LiveActivityManager.shared.sync(
                            state: client.state, artwork: client.artwork,
                            artworkKey: client.artworkCacheKey, boothName: boothName)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { client.reconnectIfNeeded() }
                }
                .onChange(of: client.phase) { _, phase in
                    switch phase {
                    case .connected:
                        BackgroundKeepAlive.shared.start()
                    case .connecting:
                        break
                    default:
                        BackgroundKeepAlive.shared.stop()
                        LiveActivityManager.shared.endAll()
                    }
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
            StageScreen {
                VStack(spacing: 16) {
                    ProgressView().tint(.white)
                    Text("Connecting to \(name)…")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
        case .needsPairing(let name):
            PairingView(boothName: name)
        case .browsing, .failed:
            DiscoveryView()
        }
    }
}

/// Shared stage-dark chrome for the pre-connection screens.
struct StageScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            BackdropView(artwork: nil, brand: nil)
            content
        }
        .preferredColorScheme(.dark)
    }
}

/// The C-Play mark drawn live, for screens without artwork to carry them.
struct CueMark: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.105, to: 0.895)
                .stroke(.white, style: StrokeStyle(lineWidth: size * 0.14, lineCap: .round))
                .padding(size * 0.12)
            Image(systemName: "play.fill")
                .font(.system(size: size * 0.3, weight: .bold))
                .offset(x: size * 0.045)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct PairingView: View {
    @EnvironmentObject private var client: CueClient
    @FocusState private var focused: Bool
    @State private var code = ""

    let boothName: String

    var body: some View {
        StageScreen {
            VStack(spacing: 20) {
                Image(systemName: "key.radiowaves.forward.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.6))
                Text("Pair with \(boothName)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enter the 6-digit pairing code shown in the Cue Booth window on your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                TextField("000000", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(size: 34, weight: .semibold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .focused($focused)
                    .foregroundStyle(.white)
                    .frame(width: 200)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Pair") { client.submitPairingCode(code) }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    .disabled(code.trimmingCharacters(in: .whitespaces).count != 6)
            }
            .padding(32)
        }
        .onAppear { focused = true }
    }
}

struct DiscoveryView: View {
    @EnvironmentObject private var client: CueClient

    var body: some View {
        StageScreen {
            VStack(spacing: 0) {
                Spacer()
                CueMark(size: 88)
                Text("Cue")
                    .font(.system(size: 40, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.top, 16)
                Text("Remote for your Mac")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 2)

                VStack(spacing: 12) {
                    if case .failed(let message) = client.phase {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.42))
                    }
                    if client.booths.isEmpty {
                        HStack(spacing: 12) {
                            ProgressView().tint(.white.opacity(0.7))
                            Text("Looking for Cue Booth…")
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    ForEach(client.booths) { booth in
                        Button {
                            client.connect(to: booth)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 19))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(booth.name)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("Tap to connect")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            .padding(14)
                            .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 44)
                Spacer()
                Text("Cue Booth must be running on your Mac")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 28)
        }
    }
}
