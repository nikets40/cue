import AppKit
import Foundation

/// Tier-2 artwork: MediaRemote hands us a small bitmap (~120 px from
/// YouTube Music), so for music tracks we look the song up on the free
/// iTunes Search API and fetch the 600 px cover. Results (including misses)
/// are cached per title|artist for the life of the process.
@MainActor
final class ArtworkUpgrader {
    struct Upgrade {
        let key: String
        let base64: String
        let mimeType: String
        let image: NSImage
    }

    var onUpgrade: ((Upgrade) -> Void)?

    private var cache: [String: Upgrade] = [:]
    private var misses: Set<String> = []
    private var inflight: Set<String> = []

    static func key(title: String, artist: String) -> String { "\(title)|\(artist)" }

    /// Returns the cached upgrade immediately if present; otherwise starts a
    /// lookup and reports via `onUpgrade` when it lands.
    func upgrade(title: String, artist: String) -> Upgrade? {
        let key = Self.key(title: title, artist: artist)
        if let hit = cache[key] { return hit }
        guard !misses.contains(key), !inflight.contains(key) else { return nil }
        inflight.insert(key)
        Task { [weak self] in
            let result = await Self.fetch(title: title, artist: artist, key: key)
            guard let self else { return }
            self.inflight.remove(key)
            if let result {
                self.cache[key] = result
                self.onUpgrade?(result)
            } else {
                self.misses.insert(key)
            }
        }
        return nil
    }

    private static func fetch(title: String, artist: String, key: String) async -> Upgrade? {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            .init(name: "term", value: "\(artist) \(title)"),
            .init(name: "media", value: "music"),
            .init(name: "entity", value: "song"),
            .init(name: "limit", value: "1"),
        ]
        guard let searchURL = components.url,
              let (data, _) = try? await URLSession.shared.data(from: searchURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              let artworkSmall = results.first?["artworkUrl100"] as? String
        else { return nil }

        let artworkBig = artworkSmall.replacingOccurrences(of: "100x100bb", with: "600x600bb")
        guard let artURL = URL(string: artworkBig),
              let (artData, response) = try? await URLSession.shared.data(from: artURL),
              let image = NSImage(data: artData)
        else { return nil }
        let mime = (response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Type") ?? "image/jpeg"
        return Upgrade(key: key, base64: artData.base64EncodedString(), mimeType: mime, image: image)
    }
}
