import CueKit
import SwiftUI

/// Deliberately smaller than the phone app: what's playing, transport, and the
/// crown for volume. No queue, no source picker — on a watch those are worse
/// than reaching for the phone.
struct WatchPlayerView: View {
    @EnvironmentObject private var connector: WatchConnector
    /// Drives the crown, on the protocol's 0–100 scale rather than a unit
    /// fraction. Kept in sync with the reported volume except while the user
    /// is turning it.
    @State private var crownVolume: Double = 50
    @FocusState private var crownFocused: Bool
    /// True only while the crown is genuinely being turned. Inferring intent
    /// from value changes instead was wrong: adopting the Mac's own volume
    /// also changes the value, and sending that back walked the volume away on
    /// its own — it drove a Mac to silence during testing.
    @State private var userIsTurning = false

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
            detent: $crownVolume, from: 0, through: 100, by: 2,
            sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true,
            onChange: { _ in userIsTurning = true },
            onIdle: {
                // The last value can land after the turn ends, so send it here
                // rather than risk dropping where the user actually stopped.
                if userIsTurning, payload.connected { connector.setVolume(crownVolume) }
                userIsTurning = false
            }
        )
        .onChange(of: crownVolume) { _, value in
            guard userIsTurning, payload.connected, payload.volume != nil else { return }
            connector.setVolume(value)
        }
        .onChange(of: payload.volume) { _, value in
            // Don't yank the crown out from under the user mid-turn.
            guard !userIsTurning, connector.pendingVolume == nil, let value else { return }
            crownVolume = value
        }
        .onAppear {
            crownFocused = true
            if let volume = payload.volume { crownVolume = volume }
        }
    }

    /// Laid out with flexible gaps rather than fixed ones: watch screens run
    /// from 40mm to 49mm, and the header's height changes with how many lines
    /// the title takes, so fixed spacing leaves the transport row stranded.
    private var player: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                artwork
                VStack(alignment: .leading, spacing: 1) {
                    Text(payload.title ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        // Rather than truncating a title that just misses.
                        .minimumScaleFactor(0.85)
                    if let artist = payload.artist, !artist.isEmpty {
                        Text(artist)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }

            Spacer(minLength: 7)
            progress
            Spacer(minLength: 9)

            // Spread to the edges instead of clustering around the centre,
            // which both looks intentional and widens the tap targets.
            HStack(spacing: 0) {
                transportButton("gobackward.15") { connector.send(.skipBack15) }
                Spacer(minLength: 0)
                transportButton(payload.playing ? "pause.fill" : "play.fill", large: true) {
                    connector.send(.togglePlayPause)
                }
                Spacer(minLength: 0)
                transportButton("goforward.15") { connector.send(.skipForward15) }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 5)
            volumeReadout
        }
        .padding(.horizontal, 3)
    }

    @ViewBuilder private var artwork: some View {
        if let data = payload.artworkJPEG, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary)
                .frame(width: 42, height: 42)
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
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder private var volumeReadout: some View {
        if let volume = connector.pendingVolume ?? payload.volume {
            HStack(spacing: 4) {
                Image(systemName: volume < 1 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 10))
                Text("\(Int(volume.rounded()))%")
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
                .font(.system(size: large ? 21 : 18, weight: .medium))
                .frame(width: large ? 46 : 40, height: large ? 46 : 40)
                .contentShape(Circle())
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
