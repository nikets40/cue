import CueKit
import Foundation
import UIKit
import WatchConnectivity

/// Bridges the watch to Booth. The watch can't reach the Mac itself, so the
/// phone forwards state out and commands back.
///
/// State goes out via `updateApplicationContext`, which keeps only the newest
/// value and delivers it even when the watch app isn't running — the right fit
/// for a full snapshot that supersedes whatever came before. Commands come in
/// via `sendMessage`, which is immediate and wakes this app in the background
/// if the system has suspended it.
@MainActor
final class WatchRelay: NSObject, ObservableObject {
    static let shared = WatchRelay()

    /// Set by the app so an incoming watch command reaches Booth.
    var onCommand: ((CueCommand.Action, Double?) -> Void)?
    /// Asked for the newest payload when the watch requests one directly.
    var currentPayload: (() -> WatchPayload)?

    private var lastSent: WatchPayload?
    private var lastArtworkKey: String?
    private var lastArtworkJPEG: Data?

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activate() {
        guard let session else { return }
        session.delegate = self
        session.activate()
    }

    /// Called on every Booth update. Cheap when nothing the watch cares about
    /// has changed, which is most ticks — position alone is extrapolated on the
    /// watch rather than pushed.
    func sync(state: NowPlayingState?, artwork: UIImage?, artworkKey: String?,
              connected: Bool, boothName: String?) {
        // Deliberately not gated on isWatchAppInstalled: it reports false in
        // some legitimate states, and because this is the only path that
        // populates the artwork cache, a false negative here silently stops
        // every update rather than just skipping one.
        guard let session, session.activationState == .activated, session.isPaired
        else { return }

        // Re-encoding artwork on every update would cost far more than the
        // rest of this put together, so it's cached against Booth's own key.
        // The second clause matters when the key is nil but artwork exists:
        // comparing nil to nil looks unchanged and would never encode anything.
        if artworkKey != lastArtworkKey || (lastArtworkJPEG == nil && artwork != nil) {
            lastArtworkKey = artworkKey
            lastArtworkJPEG = artwork.flatMap(Self.thumbnail)
        }
        var payload = self.payload(state: state, connected: connected, boothName: boothName)
        payload.artworkJPEG = lastArtworkJPEG

        // Position changes constantly but the watch derives its own, so
        // comparing without it avoids a transfer every second.
        if let lastSent, lastSent.withoutArtwork.matchesIgnoringPosition(payload.withoutArtwork),
           lastSent.artworkJPEG == payload.artworkJPEG {
            return
        }
        lastSent = payload

        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? session.updateApplicationContext([WatchMessage.payload: data])
    }

    /// Builds a payload from the current state. Artwork is added by `sync`,
    /// which owns the cache; a direct request reuses whatever it last encoded.
    func payload(state: NowPlayingState?, connected: Bool, boothName: String?) -> WatchPayload {
        var payload = WatchPayload()
        payload.connected = connected
        payload.boothName = boothName
        payload.artworkJPEG = lastArtworkJPEG
        guard let state else { return payload }
        payload.title = state.title
        payload.artist = state.artist
        payload.service = state.service
        payload.playing = state.playing
        payload.volume = state.volume
        payload.elapsed = state.elapsedTime
        payload.duration = state.duration
        payload.stamp = state.timestamp ?? Date()
        return payload
    }

    /// 180pt square is more than a 45mm screen resolves; JPEG because the
    /// application context has a hard size limit and album art is photographic.
    private static func thumbnail(_ image: UIImage) -> Data? {
        let side: CGFloat = 180
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side),
                                               format: format)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return scaled.jpegData(compressionQuality: 0.7)
    }
}

extension WatchPayload {
    /// Equality that ignores the clock, so a still-playing track doesn't look
    /// like a change on every tick.
    func matchesIgnoringPosition(_ other: WatchPayload) -> Bool {
        title == other.title && artist == other.artist && service == other.service
            && playing == other.playing && volume == other.volume
            && duration == other.duration && connected == other.connected
            && boothName == other.boothName
    }
}

extension WatchRelay: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    /// Reactivating is required after switching watches, or the session stays
    /// dead and the relay silently stops working.
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            if message[WatchMessage.requestState] != nil {
                guard let payload = self.currentPayload?(),
                      let data = try? JSONEncoder().encode(payload) else {
                    replyHandler([:])
                    return
                }
                replyHandler([WatchMessage.payload: data])
                return
            }
            if let raw = message[WatchMessage.command] as? String,
               let action = CueCommand.Action(rawValue: raw) {
                self.onCommand?(action, message[WatchMessage.value] as? Double)
            }
            replyHandler([:])
        }
    }
}
