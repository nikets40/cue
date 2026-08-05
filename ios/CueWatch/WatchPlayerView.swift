import CueKit
import SwiftUI

/// Deliberately smaller than the phone app: what's playing, transport, and the
/// crown for volume. No queue, no source picker — on a watch those are worse
/// than reaching for the phone.
struct WatchPlayerView: View {
    @EnvironmentObject private var connector: WatchConnector
    /// Drives the crown. Kept in sync with the reported volume except while
    /// the user is turning it.
    @State private var crownVolume: Double = 0.5
    @FocusState private var crownFocused: Bool

    private var payload: WatchPayload { connector.payload }

    var body: some View {
        Group {
            if !connector.hasReceived {
                WatchMessageView(symbol: "iphone.gen3", text: "Connecting to iPhone")
            } else if !payload.connected {
                WatchMessageView(symbol: "wifi.slash", text: "iPhone isn't connected to Cue Booth")
            } else if payload.title == nil {
                WatchMessageView(symbol: "music.note", text: "Nothing playing")
            } else {
                player
            }
        }
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $crownVolume, from: 0, through: 1, by: 0.02,
            sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownVolume) { _, value in
            guard payload.connected, payload.volume != nil else { return }
            connector.setVolume(value)
        }
        .onChange(of: payload.volume) { _, value in
            // Don't yank the crown out from under the user mid-turn.
            guard connector.pendingVolume == nil, let value else { return }
            crownVolume = value
        }
        .onAppear {
            crownFocused = true
            if let volume = payload.volume { crownVolume = volume }
        }
    }

    private var player: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                artwork
                VStack(alignment: .leading, spacing: 1) {
                    Text(payload.title ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                    if let artist = payload.artist, !artist.isEmpty {
                        Text(artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            progress

            HStack(spacing: 14) {
                transportButton("gobackward.15") { connector.send(.skipBack15) }
                transportButton(payload.playing ? "pause.fill" : "play.fill", large: true) {
                    connector.send(.togglePlayPause)
                }
                transportButton("goforward.15") { connector.send(.skipForward15) }
            }
            .padding(.top, 2)

            volumeReadout
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder private var artwork: some View {
        if let data = payload.artworkJPEG, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.quaternary)
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "music.note").font(.system(size: 16))
                    .foregroundStyle(.secondary))
        }
    }

    /// A bar rather than timestamps: at this size the position matters more as
    /// a sense of progress than as a number.
    @ViewBuilder private var progress: some View {
        if let duration = payload.duration, duration > 0,
           let position = payload.position() {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(.primary)
                        .frame(width: geometry.size.width * min(max(position / duration, 0), 1))
                }
            }
            .frame(height: 3)
        }
    }

    @ViewBuilder private var volumeReadout: some View {
        if let volume = connector.pendingVolume ?? payload.volume {
            HStack(spacing: 4) {
                Image(systemName: volume < 0.01 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 10))
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
        }
    }

    private func transportButton(_ symbol: String, large: Bool = false,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: large ? 22 : 17, weight: .medium))
                .frame(width: large ? 48 : 38, height: large ? 48 : 38)
        }
        .buttonStyle(.plain)
        .background(large ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.clear), in: Circle())
    }
}

/// Shared empty/error state, so every non-playing case looks deliberate.
private struct WatchMessageView: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
    }
}
