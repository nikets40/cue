import Foundation

/// Wire protocol shared by Cue Booth (macOS server) and Cue (iOS client).
///
/// Transport: WebSocket text frames carrying JSON.
/// - Server → client: `ServerMessage` (full-state snapshots, never diffs).
/// - Client → server: `CueCommand`.

public enum CueProtocol {
    /// Bonjour service type Cue Booth advertises on the local network.
    public static let bonjourServiceType = "_cue._tcp"
    /// Default WebSocket port for Cue Booth.
    public static let defaultPort: UInt16 = 41952

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public struct NowPlayingState: Codable, Equatable, Sendable {
    public var title: String?
    public var artist: String?
    public var album: String?
    /// Bundle identifier of the app that owns playback (e.g. com.google.Chrome).
    public var sourceApp: String?
    public var playing: Bool
    public var duration: Double?
    /// Elapsed seconds as of `timestamp`; extrapolate with `playbackRate` while playing.
    public var elapsedTime: Double?
    public var timestamp: Date?
    public var playbackRate: Double
    public var artworkBase64: String?
    public var artworkMimeType: String?
    /// System output volume, 0–100.
    public var volume: Double
    /// Detected streaming service (e.g. "netflix", "ytmusic") for branded
    /// fallback art on the client; nil when unknown.
    public var service: String?
    /// "like", "dislike", or "indifferent" when the source exposes it.
    public var likeStatus: String?
    /// True when a richer queue is reachable (browser extension or VLC), so
    /// the client knows whether to offer playlist browsing.
    public var hasQueue: Bool

    public init(
        title: String? = nil, artist: String? = nil, album: String? = nil,
        sourceApp: String? = nil, playing: Bool = false, duration: Double? = nil,
        elapsedTime: Double? = nil, timestamp: Date? = nil, playbackRate: Double = 1,
        artworkBase64: String? = nil, artworkMimeType: String? = nil, volume: Double = 0,
        service: String? = nil, likeStatus: String? = nil, hasQueue: Bool = false
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.sourceApp = sourceApp
        self.playing = playing
        self.duration = duration
        self.elapsedTime = elapsedTime
        self.timestamp = timestamp
        self.playbackRate = playbackRate
        self.artworkBase64 = artworkBase64
        self.artworkMimeType = artworkMimeType
        self.volume = volume
        self.service = service
        self.likeStatus = likeStatus
        self.hasQueue = hasQueue
    }

    public func estimatedPosition(at date: Date = Date()) -> Double? {
        guard let elapsedTime else { return nil }
        guard playing, let timestamp else { return elapsedTime }
        let position = elapsedTime + date.timeIntervalSince(timestamp) * playbackRate
        if let duration { return min(position, duration) }
        return position
    }
}

public struct CueCommand: Codable, Equatable, Sendable {
    public enum Action: String, Codable, CaseIterable, Sendable {
        case play
        case pause
        case togglePlayPause
        case nextTrack
        case previousTrack
        case skipForward15
        case skipBack15
        /// Requires `value`: target position in seconds.
        case seek
        /// Requires `value`: system volume 0–100.
        case setVolume
        /// Ask for the current source's playlist: the browser queue when the
        /// extension is providing, otherwise VLC's.
        case requestPlaylist
        /// Requires `value`: the `PlaylistItem.id` to jump to.
        case playPlaylistItem
        /// Toggle like/dislike on the current track (YouTube Music).
        case toggleLike
        case toggleDislike
    }

    public var action: Action
    public var value: Double?

    public init(action: Action, value: Double? = nil) {
        self.action = action
        self.value = value
    }
}

public struct PlaylistItem: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var title: String
    /// Artist or byline, when the source provides one.
    public var subtitle: String?
    public var duration: Double?
    public var isCurrent: Bool
    /// Remote thumbnail the client loads directly — sending a few hundred
    /// images as data would dwarf the rest of the protocol.
    public var artworkURL: String?

    public init(
        id: Int, title: String, subtitle: String? = nil, duration: Double? = nil,
        isCurrent: Bool = false, artworkURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.isCurrent = isCurrent
        self.artworkURL = artworkURL
    }
}

public struct ServerMessage: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case state
        /// Sent when a client's `ClientHello` token is missing or wrong; the
        /// server closes the connection right after.
        case authFailed
        /// Reply to `requestPlaylist`. `playlist` is nil when the source has
        /// no reachable playlist (e.g. VLC's HTTP interface is off).
        case playlist
    }

    public var type: Kind
    public var state: NowPlayingState?
    public var playlist: [PlaylistItem]?

    public init(state: NowPlayingState) {
        self.type = .state
        self.state = state
    }

    public init(type: Kind, state: NowPlayingState? = nil, playlist: [PlaylistItem]? = nil) {
        self.type = type
        self.state = state
        self.playlist = playlist
    }
}

/// First message every client must send after the WebSocket opens. The server
/// stays silent until it receives a hello with the correct pairing token.
public struct ClientHello: Codable, Equatable, Sendable {
    public enum Role: String, Codable, Sendable {
        /// A remote (the iPhone app): receives state, sends commands.
        case controller
        /// A metadata source (the Chrome extension): sends `PageMetadata`.
        /// Accepted without a token when connecting over loopback, since it
        /// runs on the same machine as Booth and can't reach the token.
        case provider
    }

    public var token: String
    public var role: Role?

    public init(token: String, role: Role? = nil) {
        self.token = token
        self.role = role
    }
}

/// Sent by the Chrome extension: the page's own Media Session metadata, which
/// carries full-resolution artwork and an unambiguous source — both better
/// than anything MediaRemote exposes.
/// Provider → Booth messages share a `kind` discriminator; messages without
/// one predate the queue support and are treated as metadata.
public enum ProviderMessageKind: String, Codable, Sendable {
    case meta
    case queue
}

/// Booth → provider: an action for the extension to perform on the playing tab.
public struct ProviderCommand: Codable, Equatable, Sendable {
    public enum Action: String, Codable, Sendable {
        case toggleLike
        case toggleDislike
        case requestQueue
        /// Uses `index` into the queue the extension last reported.
        case playQueueItem
    }

    public var command: Action
    public var index: Int?

    public init(command: Action, index: Int? = nil) {
        self.command = command
        self.index = index
    }
}

/// Provider → Booth: the playing tab's queue.
public struct PageQueue: Codable, Equatable, Sendable {
    public var kind: ProviderMessageKind
    public var items: [PlaylistItem]

    public init(items: [PlaylistItem]) {
        self.kind = .queue
        self.items = items
    }
}

public struct PageMetadata: Codable, Equatable, Sendable {
    public var kind: ProviderMessageKind?
    public var likeStatus: String?
    public var title: String?
    public var artist: String?
    public var album: String?
    /// Slug matching the client's bundled brand cards (e.g. "netflix").
    public var service: String?
    public var artworkBase64: String?
    public var artworkMimeType: String?
    public var playing: Bool
    public var pageURL: String?
    /// Whether the page exposes a browsable queue.
    public var hasQueue: Bool?
    /// Diagnostic string from the extension, logged by Booth.
    public var debug: String?

    public init(
        title: String? = nil, artist: String? = nil, album: String? = nil,
        service: String? = nil, artworkBase64: String? = nil,
        artworkMimeType: String? = nil, playing: Bool = false, pageURL: String? = nil,
        likeStatus: String? = nil, hasQueue: Bool? = nil
    ) {
        self.kind = .meta
        self.likeStatus = likeStatus
        self.title = title
        self.artist = artist
        self.album = album
        self.service = service
        self.artworkBase64 = artworkBase64
        self.artworkMimeType = artworkMimeType
        self.playing = playing
        self.pageURL = pageURL
        self.hasQueue = hasQueue
    }
}
