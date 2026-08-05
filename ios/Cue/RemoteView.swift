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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var hardwareVolume = HardwareVolumeSync()
    @State private var seekPreview: Double?
    @State private var volumePreview: Double?
    @State private var showPlaylist = false

    private var state: NowPlayingState { client.state ?? NowPlayingState() }
    private var brand: ServiceBrand? { state.service.flatMap(ServiceBrand.init(rawValue:)) }

    var body: some View {
        ZStack {
            BackdropView(
                artwork: client.artwork, brand: brand,
                backdropURL: state.backdropURL)
            if verticalSizeClass == .compact { landscape } else { portrait }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hardwareVolume.onVolumeStep = { delta in
                let current = volumePreview ?? client.state?.volume ?? 50
                let target = min(max(current + delta, 0), 100)
                volumePreview = target
                client.send(.setVolume, value: target)
            }
            if scenePhase == .active { hardwareVolume.start() }
        }
        .onDisappear { hardwareVolume.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { hardwareVolume.start() } else { hardwareVolume.stop() }
        }
        .sheet(isPresented: $showPlaylist) {
            PlaylistSheet()
                .environmentObject(client)
        }
    }

    // MARK: - Layouts

    // Pre-redesign rhythm: one centered stack with even gaps and breathing
    // room top and bottom — controls never pinned to the bottom edge.
    private var portrait: some View {
        VStack(spacing: 28) {
            header
            Spacer(minLength: 0)
            // A square cover fills the width; a taller poster is bounded by
            // height so it can't push the controls off screen.
            CoverView(artwork: client.artwork, brand: brand)
                .frame(maxWidth: 260, maxHeight: 300)
            trackInfo
            progressSection
            transportSection
            volumeSection
                .padding(.top, 18)
            Spacer(minLength: 0)
                .frame(maxHeight: 10)
        }
        .padding(24)
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
            if state.hasQueue {
                Button {
                    client.requestPlaylist()
                    showPlaylist = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.trailing, 14)
            }
            Button("Disconnect") { client.disconnect() }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private var trackInfo: some View {
        VStack(spacing: 4) {
            Text(state.title ?? "Nothing playing")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(state.artist ?? state.sourceApp ?? " ")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(1)
            if state.likeStatus != nil {
                HStack(spacing: 26) {
                    rateButton("hand.thumbsdown", active: state.likeStatus == "dislike") {
                        client.send(.toggleDislike)
                    }
                    rateButton("hand.thumbsup", active: state.likeStatus == "like") {
                        client.send(.toggleLike)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func rateButton(
        _ symbol: String, active: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: active ? "\(symbol).fill" : symbol)
                .font(.system(size: 17))
                .foregroundStyle(active ? .white : .white.opacity(0.55))
        }
        .buttonStyle(.plain)
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
    /// A wide 16:9 still, when the source has one. It covers the screen far
    /// better than a blurred portrait poster, which has to be scaled hard to
    /// fill and washes out at the edges.
    var backdropURL: String?

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(red: 0.15, green: 0.13, blue: 0.22), Color(red: 0.06, green: 0.055, blue: 0.09)],
                center: .top, startRadius: 0, endRadius: 900)
            if let backdropURL, let url = URL(string: backdropURL) {
                GeometryReader { geo in
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .saturation(1.2)
                                .blur(radius: 40, opaque: true)
                                .scaleEffect(1.2)
                        } else if let artwork {
                            blurred(artwork, in: geo.size)
                        }
                    }
                }
            } else if let artwork {
                GeometryReader { geo in blurred(artwork, in: geo.size) }
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

    private func blurred(_ image: UIImage, in size: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: size.width, height: size.height)
            .clipped()
            .saturation(1.35)
            .blur(radius: 46, opaque: true)
            .scaleEffect(1.35)
    }
}

/// The crisp cover: artwork, or a branded logo card, or the stage tile.
/// Takes the artwork's own shape rather than forcing a square — film and show
/// posters are 2:3, and cropping them to a square cuts off the title.
struct CoverView: View {
    let artwork: UIImage?
    let brand: ServiceBrand?

    private var aspectRatio: CGFloat {
        guard let artwork, artwork.size.width > 0, artwork.size.height > 0 else { return 1 }
        return artwork.size.width / artwork.size.height
    }

    var body: some View {
        Group {
            if let artwork {
                Image(uiImage: artwork).resizable().scaledToFit()
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
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
    }
}
