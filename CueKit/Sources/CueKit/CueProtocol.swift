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

    public init(
        title: String? = nil, artist: String? = nil, album: String? = nil,
        sourceApp: String? = nil, playing: Bool = false, duration: Double? = nil,
        elapsedTime: Double? = nil, timestamp: Date? = nil, playbackRate: Double = 1,
        artworkBase64: String? = nil, artworkMimeType: String? = nil, volume: Double = 0
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
    }

    public var action: Action
    public var value: Double?

    public init(action: Action, value: Double? = nil) {
        self.action = action
        self.value = value
    }
}

public struct ServerMessage: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case state
        /// Sent when a client's `ClientHello` token is missing or wrong; the
        /// server closes the connection right after.
        case authFailed
    }

    public var type: Kind
    public var state: NowPlayingState?

    public init(state: NowPlayingState) {
        self.type = .state
        self.state = state
    }

    public init(type: Kind, state: NowPlayingState? = nil) {
        self.type = type
        self.state = state
    }
}

/// First message every client must send after the WebSocket opens. The server
/// stays silent until it receives a hello with the correct pairing token.
public struct ClientHello: Codable, Equatable, Sendable {
    public var token: String

    public init(token: String) {
        self.token = token
    }
}
