import AppKit
import Combine
import CueKit
import Foundation

struct NowPlaying: Equatable {
    var title: String?
    var artist: String?
    var album: String?
    var bundleIdentifier: String?
    var playing = false
    var duration: Double?
    var elapsedTime: Double?
    var timestamp: Date?
    var playbackRate: Double = 1
    var artwork: NSImage?

    var isEmpty: Bool { title == nil && bundleIdentifier == nil }

    /// Elapsed time extrapolated from the last update — the stream only emits
    /// position on change, not continuously.
    func estimatedPosition(at date: Date = Date()) -> Double? {
        guard let elapsedTime else { return nil }
        guard playing, let timestamp else { return elapsedTime }
        let position = elapsedTime + date.timeIntervalSince(timestamp) * playbackRate
        if let duration { return min(position, duration) }
        return position
    }
}

@MainActor
final class MediaState: ObservableObject {
    /// Shared so startup doesn't depend on a window appearing — as a menu bar
    /// app, Booth may never show one.
    static let shared = MediaState()

    @Published private(set) var nowPlaying = NowPlaying()
    @Published private(set) var rawEvent = "(no events yet)"
    @Published private(set) var streamAlive = false
    @Published var volume: Double = 0 // 0–100
    var suppressVolumePolling = false

    let server = CueServer()
    private(set) var pairingToken = ""
    /// Detected streaming service for the current track (see ServiceDetector).
    @Published private(set) var currentService: String?

    private let artworkUpgrader = ArtworkUpgrader()
    private let serviceDetector = ServiceDetector()
    private lazy var vlc = VLCClient(defaults: Self.defaults)
    private var currentTrackKey = ""
    private var upgraded: ArtworkUpgrader.Upgrade?
    /// Metadata from the Chrome extension, keyed by normalized title. Every
    /// media tab reports, so this is a small cache rather than one slot —
    /// otherwise a paused tab reporting last would displace the playing one.
    private var pageMetadata: [String: PageMetadata] = [:]

    /// Both paths resolve to the same `com.niket.cuebooth` domain, so the
    /// pairing token survives moving between `swift run` and the packaged app.
    /// `UserDefaults(suiteName:)` returns nil when the suite matches the
    /// running bundle's own identifier — which is exactly the case once Booth
    /// is packaged, so standard defaults are used there.
    private static let defaults: UserDefaults = {
        let domain = "com.niket.cuebooth"
        if Bundle.main.bundleIdentifier == domain { return .standard }
        return UserDefaults(suiteName: domain) ?? .standard
    }()

    private var payload: [String: Any] = [:]
    private var cachedArtworkData: String?
    private var artworkMimeType: String?
    private var cancellables = Set<AnyCancellable>()
    private var streamProcess: Process?
    private var lineBuffer = Data()
    private var volumeTimer: Timer?
    private var started = false

    static let mediaControlPath: String = {
        // Prefer the copy vendored inside Cue Booth.app so a packaged build
        // doesn't depend on the user's Homebrew install; fall back to brew
        // when running from `swift run`.
        var candidates: [String] = []
        if let bundled = Bundle.main.resourceURL?
            .appendingPathComponent("media-control/bin/media-control").path {
            candidates.append(bundled)
        }
        candidates += ["/opt/homebrew/bin/media-control", "/usr/local/bin/media-control"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) } ?? "media-control"
    }()

    func start() {
        guard !started else { return }
        started = true
        startStream()
        pollVolume()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollVolume() }
        }

        if let stored = Self.defaults.string(forKey: "pairingToken"), !stored.isEmpty {
            pairingToken = stored
        } else {
            pairingToken = String(format: "%06d", Int.random(in: 0...999_999))
            Self.defaults.set(pairingToken, forKey: "pairingToken")
        }
        server.pairingToken = pairingToken
        server.onCommand = { [weak self] command in self?.handle(command) }
        server.onPageQueue = { [weak self] items in
            self?.server.sendPlaylist(items)
        }
        server.onPageMetadata = { [weak self] metadata in
            guard let self, let title = metadata.title else { return }
            let key = Self.normalize(title)
            guard !key.isEmpty else { return }
            if self.pageMetadata.count > 20 { self.pageMetadata.removeAll() }
            self.pageMetadata[key] = metadata
            self.rebuildNowPlaying()
        }
        server.start()

        artworkUpgrader.onUpgrade = { [weak self] upgrade in
            guard let self, upgrade.key == self.currentTrackKey else { return }
            self.upgraded = upgrade
            self.rebuildNowPlaying()
        }
        serviceDetector.onDetect = { [weak self] trackKey, service in
            guard let self, trackKey == self.currentTrackKey else { return }
            self.currentService = service
        }

        // Throttle, not debounce: debounce only emits after a lull, and with
        // both the media stream and the Chrome extension pushing updates there
        // may never be one — which silently starved every broadcast.
        Publishers.CombineLatest3(
            $nowPlaying.removeDuplicates(), $volume.removeDuplicates(),
            $currentService.removeDuplicates())
            .throttle(for: .milliseconds(120), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.server.broadcast(self.snapshot())
            }
            .store(in: &cancellables)
    }

    func snapshot() -> NowPlayingState {
        NowPlayingState(
            title: nowPlaying.title,
            artist: nowPlaying.artist,
            album: nowPlaying.album,
            sourceApp: nowPlaying.bundleIdentifier,
            playing: nowPlaying.playing,
            duration: nowPlaying.duration,
            elapsedTime: nowPlaying.elapsedTime,
            timestamp: nowPlaying.timestamp,
            playbackRate: nowPlaying.playbackRate,
            artworkBase64: livePageMetadata(for: nowPlaying.title)?.artworkBase64
                ?? upgraded?.base64 ?? cachedArtworkData,
            artworkMimeType: livePageMetadata(for: nowPlaying.title)?.artworkMimeType
                ?? upgraded?.mimeType ?? artworkMimeType,
            volume: volume,
            service: currentService,
            likeStatus: livePageMetadata(for: nowPlaying.title)?.likeStatus,
            hasQueue: useProviderQueue
                || nowPlaying.bundleIdentifier == VLCClient.bundleIdentifier)
    }

    func handle(_ command: CueCommand) {
        switch command.action {
        case .play: send("play")
        case .pause: send("pause")
        case .togglePlayPause: send("toggle-play-pause")
        case .nextTrack: send("next-track")
        case .previousTrack: send("previous-track")
        case .skipForward15: skip(by: 15)
        case .skipBack15: skip(by: -15)
        case .seek: if let value = command.value { seek(to: value) }
        case .setVolume: if let value = command.value { setVolume(value) }
        case .requestPlaylist:
            // Prefer the browser queue when the extension is providing for the
            // current source; the reply arrives asynchronously as a PageQueue.
            if useProviderQueue, server.sendToProvider(ProviderCommand(command: .requestQueue)) {
                return
            }
            Task { [weak self] in
                guard let self else { return }
                self.server.sendPlaylist(await self.vlc.playlist())
            }
        case .playPlaylistItem:
            guard let value = command.value else { return }
            if useProviderQueue,
               server.sendToProvider(ProviderCommand(command: .playQueueItem, index: Int(value))) {
                return
            }
            Task { [weak self] in await self?.vlc.play(id: Int(value)) }
        case .toggleLike:
            server.sendToProvider(ProviderCommand(command: .toggleLike))
        case .toggleDislike:
            server.sendToProvider(ProviderCommand(command: .toggleDislike))
        }
    }

    /// The extension only controls browser tabs, so route queue actions to it
    /// only while the browser owns playback.
    private var useProviderQueue: Bool {
        server.providerConnected && nowPlaying.bundleIdentifier == "com.google.Chrome"
    }

    // MARK: - Now-playing stream

    private func startStream() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.mediaControlPath)
        process.arguments = ["stream"]
        let pipe = Pipe()
        process.standardOutput = pipe
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            Task { @MainActor in self?.consume(chunk) }
        }
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.streamAlive = false
                // Auto-restart: the adapter occasionally exits when the media app quits.
                try? await Task.sleep(for: .seconds(2))
                self?.startStream()
            }
        }
        do {
            try process.run()
            streamProcess = process
            streamAlive = true
            log("stream started: \(Self.mediaControlPath)")
        } catch {
            rawEvent = "Failed to launch \(Self.mediaControlPath): \(error.localizedDescription)"
            streamAlive = false
        }
    }

    private func consume(_ chunk: Data) {
        lineBuffer.append(chunk)
        while let newline = lineBuffer.firstIndex(of: UInt8(ascii: "\n")) {
            let line = lineBuffer.prefix(upTo: newline)
            lineBuffer.removeSubrange(...newline)
            if !line.isEmpty { apply(line: Data(line)) }
        }
    }

    private func apply(line: Data) {
        guard let event = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
              event["type"] as? String == "data",
              let eventPayload = event["payload"] as? [String: Any]
        else { return }

        if event["diff"] as? Bool == true {
            for (key, value) in eventPayload {
                if value is NSNull { payload.removeValue(forKey: key) } else { payload[key] = value }
            }
        } else {
            payload = eventPayload
        }
        rebuildNowPlaying()
        rawEvent = Self.prettyEvent(payload)
    }

    private func rebuildNowPlaying() {
        var state = NowPlaying()
        state.title = payload["title"] as? String
        state.artist = payload["artist"] as? String
        state.album = payload["album"] as? String
        state.bundleIdentifier = payload["bundleIdentifier"] as? String
        state.playing = payload["playing"] as? Bool ?? false
        state.duration = payload["duration"] as? Double
        state.elapsedTime = payload["elapsedTime"] as? Double
        state.playbackRate = payload["playbackRate"] as? Double ?? 1
        if let timestamp = payload["timestamp"] as? String {
            state.timestamp = ISO8601DateFormatter().date(from: timestamp)
        }
        artworkMimeType = payload["artworkMimeType"] as? String
        let artworkData = payload["artworkData"] as? String
        if artworkData == cachedArtworkData {
            state.artwork = nowPlaying.artwork
        } else if let artworkData, let data = Data(base64Encoded: artworkData) {
            state.artwork = NSImage(data: data)
        }
        cachedArtworkData = artworkData

        let trackKey = "\(state.title ?? "")|\(state.artist ?? "")"
        if trackKey != currentTrackKey {
            currentTrackKey = trackKey
            upgraded = nil
            currentService = nil
        }
        if let title = state.title, let artist = state.artist, !artist.isEmpty,
           upgraded == nil {
            upgraded = artworkUpgrader.upgrade(title: title, artist: artist)
        }
        if let upgraded { state.artwork = upgraded.image }

        // Artwork priority: the page's own art (exact source) beats the
        // iTunes lookup, which beats MediaRemote's thumbnail.
        if let page = livePageMetadata(for: state.title) {
            if let base64 = page.artworkBase64, let data = Data(base64Encoded: base64),
               let image = NSImage(data: data) {
                state.artwork = image
            }
            if let service = page.service { currentService = service }
        }
        if currentService == nil, let title = state.title, let bundle = state.bundleIdentifier {
            currentService = serviceDetector.detect(
                trackKey: trackKey, title: title, bundleIdentifier: bundle)
        }
        nowPlaying = state
    }

    static func normalize(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// The extension reports every media tab; only the entry whose title
    /// matches the system's now-playing track describes what's audible.
    private func livePageMetadata(for title: String?) -> PageMetadata? {
        guard let title else { return nil }
        let key = Self.normalize(title)
        guard !key.isEmpty else { return nil }
        if let exact = pageMetadata[key] { return exact }
        // Sites sometimes decorate the title ("Song (Official Video)"), so
        // fall back to a containment match.
        return pageMetadata.first { key.contains($0.key) || $0.key.contains(key) }?.value
    }

    private static func prettyEvent(_ payload: [String: Any]) -> String {
        var display = payload
        if let artwork = display["artworkData"] as? String {
            display["artworkData"] = "<\(artwork.count) chars base64>"
        }
        guard let data = try? JSONSerialization.data(
            withJSONObject: display, options: [.prettyPrinted, .sortedKeys])
        else { return "\(display)" }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Commands

    func send(_ command: String) { runMediaControl([command]) }

    func seek(to seconds: Double) { runMediaControl(["seek", String(format: "%.2f", seconds)]) }

    /// MediaRemote's native skip commands are ignored by most Chrome sites,
    /// so skip is implemented as a relative seek instead.
    func skip(by seconds: Double) {
        guard let position = nowPlaying.estimatedPosition() else { return }
        var target = max(position + seconds, 0)
        if let duration = nowPlaying.duration { target = min(target, max(duration - 0.5, 0)) }
        seek(to: target)
    }

    private func runMediaControl(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.mediaControlPath)
        process.arguments = arguments
        try? process.run()
    }

    // MARK: - Volume (CoreAudio; see SystemVolume)

    private var lastVolumeSetAt = Date.distantPast

    func setVolume(_ value: Double) {
        volume = value
        lastVolumeSetAt = Date()
        SystemVolume.set(value)
    }

    private func pollVolume() {
        // Don't overwrite the UI mid-drag or right after a set: reading back
        // too soon can race the hardware and make the slider snap backwards.
        // The 1.5 tolerance absorbs CoreAudio quantizing to hardware steps —
        // without it every set is followed by a spurious "correction"
        // broadcast that nudges remote sliders.
        guard !suppressVolumePolling,
              Date().timeIntervalSince(lastVolumeSetAt) > 2,
              let value = SystemVolume.get()
        else { return }
        if abs(value - volume) > 1.5 { volume = value }
    }
}
