import Foundation

/// What the phone forwards to the watch, and what the watch sends back.
///
/// The watch has no route to Booth of its own: it talks to the phone over
/// WatchConnectivity, and the phone relays. That means every payload has to
/// survive the phone being asleep and the watch missing updates, so this is a
/// whole snapshot rather than a change — the same reasoning behind Booth's own
/// wire format.
struct WatchPayload: Codable, Equatable {
    var title: String?
    var artist: String?
    /// Brand slug ("netflix", "ytmusic"), for the fallback glyph.
    var service: String?
    var playing = false
    var volume: Double?
    /// Position when `stamp` was taken; the watch extrapolates from there
    /// rather than being told every second.
    var elapsed: Double?
    var duration: Double?
    var stamp: Date?
    /// False when the phone isn't connected to Booth, so the watch can say so
    /// instead of showing stale controls that quietly do nothing.
    var connected = false
    var boothName: String?
    /// Downscaled artwork. Full-resolution art would blow the
    /// application-context size limit, and the watch can't show that detail.
    var artworkJPEG: Data?

    /// Position brought up to date, the way the phone's scrubber does it.
    func position(at date: Date = Date()) -> Double? {
        guard let elapsed else { return nil }
        guard playing, let stamp else { return elapsed }
        let position = elapsed + date.timeIntervalSince(stamp)
        if let duration { return min(position, duration) }
        return position
    }

    /// Everything except artwork, for deciding whether an update is worth
    /// sending. Artwork is compared separately by cache key, since re-encoding
    /// it on every tick would be wasteful.
    var withoutArtwork: WatchPayload {
        var copy = self
        copy.artworkJPEG = nil
        return copy
    }
}

/// Keys for the WatchConnectivity dictionaries. Both sides read these, so they
/// live here rather than being spelled out at each call site.
enum WatchMessage {
    static let payload = "payload"
    static let command = "command"
    static let value = "value"
    /// Watch → phone on launch: the application context may predate the watch
    /// app starting, so it asks for the current state outright.
    static let requestState = "requestState"
}
