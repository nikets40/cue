import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CueWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CueLiveActivity()
    }
}

struct CueLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CueActivityAttributes.self) { context in
            LockScreenCard(context: context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // The expanded presentation has a hard height budget shared by
                // the header row and the bottom region: overflow is clipped
                // from the end, so an oversized header silently eats the
                // transport row. Keep the header compact, spend the room on
                // the controls, and give them layout priority so they always
                // survive a squeeze.
                DynamicIslandExpandedRegion(.leading) {
                    ArtworkThumb(data: context.state.artworkThumb, size: 46)
                        .padding(.leading, 6)
                        .padding(.top, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(context.state.artist)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 10)
                    .padding(.top, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        TimelineRow(state: context.state)
                        TransportRow(playing: context.state.playing, glyph: 21, playGlyph: 25)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                }
            } compactLeading: {
                ArtworkThumb(data: context.state.artworkThumb, size: 22)
            } compactTrailing: {
                Image(systemName: context.state.playing ? "play.fill" : "pause.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            } minimal: {
                ArtworkThumb(data: context.state.artworkThumb, size: 22)
            }
        }
    }
}

/// Mirrors the native Now Playing card: artwork + titles + waveform up top,
/// ticking elapsed/remaining around a thin bar, plain-glyph transport row.
private struct LockScreenCard: View {
    let context: ActivityViewContext<CueActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ArtworkThumb(data: context.state.artworkThumb, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(context.state.artist) · \(context.attributes.boothName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            TimelineRow(state: context.state)
            TransportRow(playing: context.state.playing, glyph: 26, playGlyph: 32)
                .padding(.bottom, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
    }
}

/// Elapsed and remaining labels tick on their own via timer-interval text —
/// no content updates needed while playing.
private struct TimelineRow: View {
    let state: CueActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if state.playing {
                    Text(timerInterval: state.trackInterval, countsDown: false)
                } else {
                    Text(Self.format(state.elapsedTime))
                }
            }
            .frame(width: 48, alignment: .leading)

            Group {
                if state.playing {
                    ProgressView(timerInterval: state.trackInterval, countsDown: false) {
                    } currentValueLabel: {
                    }
                } else {
                    ProgressView(value: state.duration > 0 ? state.elapsedTime / state.duration : 0)
                }
            }
            .progressViewStyle(.linear)
            .tint(.white.opacity(0.85))
            .frame(height: 5)

            Group {
                if state.playing {
                    HStack(spacing: 0) {
                        Text("−")
                        Text(timerInterval: state.trackInterval, countsDown: true)
                    }
                } else {
                    Text("−" + Self.format(max(state.duration - state.elapsedTime, 0)))
                }
            }
            .frame(width: 52, alignment: .trailing)
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.white.opacity(0.6))
    }

    static func format(_ seconds: Double) -> String {
        let total = Int(max(seconds, 0).rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

private struct TransportRow: View {
    let playing: Bool
    let glyph: CGFloat
    let playGlyph: CGFloat

    var body: some View {
        HStack(spacing: 52) {
            Button(intent: PreviousTrackIntent()) {
                Image(systemName: "backward.fill").font(.system(size: glyph))
            }
            .buttonStyle(.plain)
            Button(intent: TogglePlayPauseIntent()) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: playGlyph, weight: .semibold))
                    .frame(width: playGlyph + 10)
            }
            .buttonStyle(.plain)
            Button(intent: NextTrackIntent()) {
                Image(systemName: "forward.fill").font(.system(size: glyph))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }
}

private struct ArtworkThumb: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.17, green: 0.15, blue: 0.25), Color(red: 0.09, green: 0.08, blue: 0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }
}
