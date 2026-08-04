import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var media: MediaState
    @State private var seekPreview: Double?
    @State private var showRawEvent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            nowPlayingCard
            progressSection
            transportSection
            volumeSection
            rawEventSection
        }
        .padding(20)
        .frame(width: 440)
    }

    private var header: some View {
        HStack {
            Text("Cue Booth").font(.title2.bold())
            Spacer()
            Label(
                media.streamAlive ? "adapter streaming" : "adapter offline",
                systemImage: media.streamAlive ? "dot.radiowaves.left.and.right" : "exclamationmark.triangle"
            )
            .font(.caption)
            .foregroundStyle(media.streamAlive ? .green : .red)
        }
    }

    private var nowPlayingCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Group {
                if let artwork = media.nowPlaying.artwork {
                    Image(nsImage: artwork).resizable().aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Rectangle().fill(.quaternary)
                        Image(systemName: "music.note").font(.largeTitle).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                if media.nowPlaying.isEmpty {
                    Text("Nothing playing").font(.headline).foregroundStyle(.secondary)
                    Text("Play something in Chrome, VLC, or Music to see it here.")
                        .font(.caption).foregroundStyle(.tertiary)
                } else {
                    Text(media.nowPlaying.title ?? "Untitled")
                        .font(.headline).lineLimit(2)
                    if let artist = media.nowPlaying.artist {
                        Text(artist).font(.subheadline).foregroundStyle(.secondary)
                    }
                    if let album = media.nowPlaying.album {
                        Text(album).font(.caption).foregroundStyle(.tertiary)
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 6) {
                        Image(systemName: media.nowPlaying.playing ? "play.fill" : "pause.fill")
                        Text(media.nowPlaying.playing ? "Playing" : "Paused")
                        if let bundle = media.nowPlaying.bundleIdentifier {
                            Text("· \(bundle)").foregroundStyle(.tertiary)
                        }
                    }
                    .font(.caption)
                }
            }
            Spacer()
        }
    }

    private var progressSection: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = media.nowPlaying.duration ?? 0
            let position = seekPreview
                ?? media.nowPlaying.estimatedPosition(at: context.date)
                ?? 0
            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: { duration > 0 ? min(position, duration) : 0 },
                        set: { seekPreview = $0 }
                    ),
                    in: 0...max(duration, 1),
                    onEditingChanged: { editing in
                        if !editing, let target = seekPreview {
                            media.seek(to: target)
                            // Keep showing the target until the stream reports the new position.
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
        HStack(spacing: 24) {
            Spacer()
            transportButton("gobackward.15") { media.send("go-back-fifteen-seconds") }
            transportButton("backward.fill") { media.send("previous-track") }
            transportButton(media.nowPlaying.playing ? "pause.circle.fill" : "play.circle.fill", size: 44) {
                media.send("toggle-play-pause")
            }
            transportButton("forward.fill") { media.send("next-track") }
            transportButton("goforward.15") { media.send("skip-fifteen-seconds") }
            Spacer()
        }
    }

    private func transportButton(
        _ symbol: String, size: CGFloat = 22, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size))
        }
        .buttonStyle(.plain)
    }

    private var volumeSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.2.fill").foregroundStyle(.secondary)
            Slider(
                value: Binding(
                    get: { media.volume },
                    set: { media.setVolume($0) }
                ),
                in: 0...100,
                onEditingChanged: { media.suppressVolumePolling = $0 }
            )
            Text("\(Int(media.volume.rounded()))%")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var rawEventSection: some View {
        DisclosureGroup("Raw adapter payload", isExpanded: $showRawEvent) {
            ScrollView {
                Text(media.rawEvent)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            .padding(8)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .font(.caption)
    }

    private static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        if total >= 3600 {
            return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
        }
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
