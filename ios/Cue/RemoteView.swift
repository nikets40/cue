import CueKit
import SwiftUI

struct RemoteView: View {
    @EnvironmentObject private var client: CueClient
    @State private var seekPreview: Double?
    @State private var volumePreview: Double?

    private var state: NowPlayingState { client.state ?? NowPlayingState() }

    var body: some View {
        VStack(spacing: 28) {
            header
            Spacer(minLength: 0)
            artworkCard
            trackInfo
            progressSection
            transportSection
            volumeSection
            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private var header: some View {
        HStack {
            if case .connected(let name) = client.phase {
                Label(name, systemImage: "desktopcomputer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Disconnect") { client.disconnect() }
                .font(.footnote)
        }
    }

    private var artworkCard: some View {
        Group {
            if let artwork = client.artwork {
                Image(uiImage: artwork).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(.quaternary)
                    Image(systemName: "music.note").font(.system(size: 56)).foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 260, height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 12, y: 6)
    }

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(state.title ?? "Nothing playing")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(state.artist ?? state.sourceApp ?? " ")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var progressSection: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = state.duration ?? 0
            let position = seekPreview ?? state.estimatedPosition(at: context.date) ?? 0
            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: { duration > 0 ? min(position, duration) : 0 },
                        set: { seekPreview = $0 }
                    ),
                    in: 0...max(duration, 1),
                    onEditingChanged: { editing in
                        if !editing, let target = seekPreview {
                            client.send(.seek, value: target)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { seekPreview = nil }
                        }
                    }
                )
                .disabled(duration <= 0)
                HStack {
                    Text(Self.timeString(position))
                    Spacer()
                    Text(Self.timeString(duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }

    private var transportSection: some View {
        HStack(spacing: 30) {
            transportButton("gobackward.15", size: 24) { client.send(.skipBack15) }
            transportButton("backward.fill", size: 30) { client.send(.previousTrack) }
            transportButton(state.playing ? "pause.circle.fill" : "play.circle.fill", size: 72) {
                client.send(.togglePlayPause)
            }
            transportButton("forward.fill", size: 30) { client.send(.nextTrack) }
            transportButton("goforward.15", size: 24) { client.send(.skipForward15) }
        }
    }

    private func transportButton(
        _ symbol: String, size: CGFloat, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size))
        }
        .buttonStyle(.plain)
    }

    private var volumeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill").foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { volumePreview ?? state.volume },
                    set: { value in
                        volumePreview = value
                        client.send(.setVolume, value: value)
                    }
                ),
                in: 0...100,
                onEditingChanged: { editing in
                    if !editing {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { volumePreview = nil }
                    }
                }
            )
            Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
        }
    }

    static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
