import ActivityKit
import CueKit
import Foundation
import UIKit

/// Starts, updates, and ends the now-playing Live Activity while the app is
/// running. While backgrounded the card's progress bar advances on its own
/// (timer interval); content refreshes happen when the app runs or when a
/// card button fires an intent (see QuickCommand).
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var lastThumbSource: String?
    private var cachedThumb: Data?
    /// The last state actually pushed, so repeats can be skipped. See
    /// `differsMeaningfully`.
    private var lastPushed: CueActivityAttributes.ContentState?

    /// Forgets what was last pushed, so the next sync definitely sends.
    ///
    /// `lastPushed` records what was *handed to* ActivityKit, not what the
    /// system actually applied. After a reconnection or a return to the
    /// foreground the card may be showing something older than that, and
    /// without this the next sync would compare equal and skip — leaving the
    /// stale card in place.
    func invalidateCache() {
        lastPushed = nil
    }

    func sync(state: NowPlayingState?, artwork: UIImage?, artworkKey: String?, boothName: String?) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard let state, let boothName, let title = state.title else {
            endAll()
            return
        }

        let content = CueActivityAttributes.ContentState(
            title: title,
            artist: state.artist ?? state.sourceApp ?? "",
            playing: state.playing,
            elapsedTime: state.elapsedTime ?? 0,
            duration: state.duration ?? 0,
            timestamp: state.timestamp ?? Date(),
            artworkThumb: thumb(from: artwork, key: artworkKey))

        // Booth broadcasts up to eight times a second, but the card's progress
        // runs off a timer interval and needs no help to keep moving. Pushing
        // every one of those burns ActivityKit's update budget, and once it's
        // spent the system stops applying updates at all — which is exactly
        // how the card ends up frozen on a finished track until the app is
        // opened by hand.
        if let lastPushed, !Self.differsMeaningfully(content, lastPushed) { return }
        lastPushed = content

        // If updates ever do stop landing, let the card show as stale rather
        // than presenting a long-finished track as though it were current.
        let staleDate = content.playing
            ? content.trackInterval.upperBound.addingTimeInterval(30)
            : nil

        if let activity = Activity<CueActivityAttributes>.activities.first {
            Task { await activity.update(ActivityContent(state: content, staleDate: staleDate)) }
        } else {
            _ = try? Activity.request(
                attributes: CueActivityAttributes(boothName: boothName),
                content: ActivityContent(state: content, staleDate: staleDate))
        }
    }

    /// Whether a new state is worth spending an update on. Elapsed time alone
    /// isn't: it advances by design between pushes, and the views extrapolate
    /// it. What matters is the track's fixed start point, which only moves on
    /// a seek.
    private static func differsMeaningfully(
        _ new: CueActivityAttributes.ContentState,
        _ old: CueActivityAttributes.ContentState
    ) -> Bool {
        if new.title != old.title || new.artist != old.artist { return true }
        if new.playing != old.playing { return true }
        if new.duration != old.duration { return true }
        if new.artworkThumb != old.artworkThumb { return true }
        let newStart = new.timestamp.addingTimeInterval(-max(new.elapsedTime, 0))
        let oldStart = old.timestamp.addingTimeInterval(-max(old.elapsedTime, 0))
        // Tolerance covers ordinary jitter in the reported position; a real
        // seek moves this far further.
        return abs(newStart.timeIntervalSince(oldStart)) > 2
    }

    func endAll() {
        // Without this, resuming the same track would match the last pushed
        // state and be skipped — leaving no card at all.
        lastPushed = nil
        for activity in Activity<CueActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }

    /// ~64 px JPEG kept under ActivityKit's payload budget; cached per artwork.
    private func thumb(from image: UIImage?, key: String?) -> Data? {
        guard let image else { return nil }
        if key == lastThumbSource, let cachedThumb { return cachedThumb }
        let side: CGFloat = 64
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
            .image { _ in
                let scale = max(side / image.size.width, side / image.size.height)
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let origin = CGPoint(x: (side - size.width) / 2, y: (side - size.height) / 2)
                image.draw(in: CGRect(origin: origin, size: size))
            }
        var quality: CGFloat = 0.6
        var data = rendered.jpegData(compressionQuality: quality)
        while let candidate = data, candidate.count > 3000, quality > 0.2 {
            quality -= 0.15
            data = rendered.jpegData(compressionQuality: quality)
        }
        lastThumbSource = key
        cachedThumb = data
        return data
    }
}
