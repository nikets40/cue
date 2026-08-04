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
                .activityBackgroundTint(Color(red: 0.09, green: 0.08, blue: 0.13).opacity(0.92))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ArtworkThumb(data: context.state.artworkThumb, size: 52)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .lineLimit(1)
                        Text("\(context.state.artist) · \(context.attributes.boothName)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ControlButtons(playing: context.state.playing)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TrackProgress(state: context.state)
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                }
            } compactLeading: {
                ArtworkThumb(data: context.state.artworkThumb, size: 22)
            } compactTrailing: {
                Image(systemName: context.state.playing ? "waveform" : "pause.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            } minimal: {
                ArtworkThumb(data: context.state.artworkThumb, size: 22)
            }
        }
    }
}

private struct LockScreenCard: View {
    let context: ActivityViewContext<CueActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ArtworkThumb(data: context.state.artworkThumb, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(1)
                    Text("\(context.state.artist) · \(context.attributes.boothName)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ControlButtons(playing: context.state.playing)
            }
            TrackProgress(state: context.state)
        }
        .padding(14)
        .foregroundStyle(.white)
    }
}

private struct ControlButtons: View {
    let playing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button(intent: TogglePlayPauseIntent()) {
                ZStack {
                    Circle().fill(.white).frame(width: 34, height: 34)
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.09, green: 0.08, blue: 0.13))
                }
            }
            .buttonStyle(.plain)
            Button(intent: NextTrackIntent()) {
                ZStack {
                    Circle().fill(.white.opacity(0.16)).frame(width: 34, height: 34)
                    Image(systemName: "forward.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct TrackProgress: View {
    let state: CueActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.playing {
                ProgressView(timerInterval: state.trackInterval, countsDown: false) {
                } currentValueLabel: {
                }
            } else {
                ProgressView(value: max(state.duration, 1) > 0 ? state.elapsedTime / max(state.duration, 1) : 0)
            }
        }
        .progressViewStyle(.linear)
        .tint(Color(red: 1.0, green: 0.62, blue: 0.42))
        .frame(height: 6)
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
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
    }
}
