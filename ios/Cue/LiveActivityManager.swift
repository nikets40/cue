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

        if let activity = Activity<CueActivityAttributes>.activities.first {
            Task { await activity.update(ActivityContent(state: content, staleDate: nil)) }
        } else {
            _ = try? Activity.request(
                attributes: CueActivityAttributes(boothName: boothName),
                content: ActivityContent(state: content, staleDate: nil))
        }
    }

    func endAll() {
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
