import CueKit
import SwiftUI

/// Streaming services with bundled fallback logo cards (asset catalog,
/// Brands/). Backdrop and card colors approximate each brand's ground.
enum ServiceBrand: String {
    case netflix, youtube, ytmusic, vlc, spotify, prime, hotstar

    var asset: String { "brand-\(rawValue)" }

    var tint: Color {
        switch self {
        case .netflix: Color(red: 0.90, green: 0.04, blue: 0.08)
        case .youtube, .ytmusic: Color(red: 0.95, green: 0.05, blue: 0.07)
        case .vlc: Color(red: 1.00, green: 0.53, blue: 0.00)
        case .spotify: Color(red: 0.12, green: 0.72, blue: 0.36)
        case .prime: Color(red: 0.00, green: 0.66, blue: 0.88)
        case .hotstar: Color(red: 0.15, green: 0.30, blue: 0.85)
        }
    }

    var card: Color {
        switch self {
        case .netflix: Color(red: 0.08, green: 0.08, blue: 0.08)
        case .youtube, .ytmusic: Color(red: 0.10, green: 0.10, blue: 0.10)
        case .vlc: Color(red: 0.12, green: 0.12, blue: 0.14)
        case .spotify: Color(red: 0.06, green: 0.09, blue: 0.07)
        case .prime: Color(red: 0.06, green: 0.09, blue: 0.12)
        case .hotstar: Color(red: 0.04, green: 0.06, blue: 0.11)
        }
    }
}

struct RemoteView: View {
    @EnvironmentObject private var client: CueClient
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var seekPreview: Double?
    @State private var volumePreview: Double?

    private var state: NowPlayingState { client.state ?? NowPlayingState() }
    private var brand: ServiceBrand? { state.service.flatMap(ServiceBrand.init(rawValue:)) }

    var body: some View {
        ZStack {
            BackdropView(artwork: client.artwork, brand: brand)
            if verticalSizeClass == .compact { landscape } else { portrait }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Layouts

    private var portrait: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 12)
            CoverView(artwork: client.artwork, brand: brand)
                .frame(maxWidth: 330)
                .padding(.horizontal, 30)
            trackInfo
                .padding(.top, 24)
            Spacer(minLength: 12)
            controls
        }
        .padding(22)
    }

    private var landscape: some View {
        HStack(spacing: 34) {
            CoverView(artwork: client.artwork, brand: brand)
                .frame(maxHeight: .infinity)
            VStack(spacing: 0) {
                header
                Spacer(minLength: 6)
                trackInfo
                Spacer(minLength: 6)
                controls
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 18)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            if case .connected(let name) = client.phase {
                HStack(spacing: 7) {
                    Circle().fill(Color(red: 0.43, green: 0.91, blue: 0.63)).frame(width: 7, height: 7)
                    Text(name)
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            Button("Disconnect") { client.disconnect() }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var trackInfo: some View {
        VStack(spacing: 5) {
            Text(state.title ?? "Nothing playing")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(state.artist ?? state.sourceApp ?? " ")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            progressSection
            transportSection
            volumeSection
        }
    }

    private var progressSection: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let duration = state.duration ?? 0
            let position = seekPreview ?? state.estimatedPosition(at: context.date) ?? 0
            VStack(spacing: 0) {
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
                .tint(.white)
                .disabled(duration <= 0)
                HStack {
                    Text(Self.timeString(position))
                    Spacer()
                    Text(Self.timeString(duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var transportSection: some View {
        HStack(spacing: 26) {
            transportButton("gobackward.15", size: 21) { client.send(.skipBack15) }
            transportButton("backward.fill", size: 27) { client.send(.previousTrack) }
            Button { client.send(.togglePlayPause) } label: {
                ZStack {
                    Circle().fill(.white).frame(width: 66, height: 66)
                    Image(systemName: state.playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(red: 0.09, green: 0.08, blue: 0.12))
                }
            }
            .buttonStyle(.plain)
            transportButton("forward.fill", size: 27) { client.send(.nextTrack) }
            transportButton("goforward.15", size: 21) { client.send(.skipForward15) }
        }
    }

    private func transportButton(
        _ symbol: String, size: CGFloat, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundStyle(.white.opacity(0.9))
        }
        .buttonStyle(.plain)
    }

    private var volumeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
            Slider(
                value: Binding(
                    get: { volumePreview ?? state.volume },
                    set: { value in
                        volumePreview = value
                        client.send(.setVolume, value: value)
                    }
                ),
                in: 0...100
            )
            .tint(.white)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.6))
        }
        .onChange(of: client.state?.volume) { _, echoed in
            if let preview = volumePreview, let echoed, abs(echoed - preview) < 1 {
                volumePreview = nil
            }
        }
        .onChange(of: volumePreview) { _, preview in
            guard preview != nil else { return }
            let captured = preview
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if volumePreview == captured { volumePreview = nil }
            }
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

/// Full-screen atmosphere: blurred artwork wash when art exists, brand-tinted
/// stage when only the service is known, plain stage otherwise.
struct BackdropView: View {
    let artwork: UIImage?
    let brand: ServiceBrand?

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.15, green: 0.13, blue: 0.22), Color(red: 0.06, green: 0.055, blue: 0.09)],
                center: .top, startRadius: 0, endRadius: 900)
            if let artwork {
                GeometryReader { geo in
                    Image(uiImage: artwork)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .saturation(1.35)
                        .blur(radius: 46, opaque: true)
                        .scaleEffect(1.35)
                }
            } else if let brand {
                RadialGradient(
                    colors: [brand.tint.opacity(0.5), .clear],
                    center: .init(x: 0.25, y: 0.1), startRadius: 0, endRadius: 700)
            }
            LinearGradient(
                colors: [.black.opacity(0.16), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

/// The crisp square: artwork, or a branded logo card, or the stage tile.
struct CoverView: View {
    let artwork: UIImage?
    let brand: ServiceBrand?

    var body: some View {
        Group {
            if let artwork {
                Color.clear.overlay(
                    Image(uiImage: artwork).resizable().scaledToFill())
            } else if let brand {
                ZStack {
                    brand.card
                    Image(brand.asset)
                        .resizable()
                        .scaledToFit()
                        .padding(34)
                }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.17, green: 0.15, blue: 0.25), Color(red: 0.09, green: 0.08, blue: 0.12)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note")
                        .font(.system(size: 52))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
    }
}
