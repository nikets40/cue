import AppKit
import Foundation

/// Finds show/film posters for video services, where neither MediaRemote nor
/// the page gives usable art. TMDB is used because the keyless alternative
/// (iTunes Search) only covers Apple's catalogue — it has no Netflix or Prime
/// originals and little non-Western content.
///
/// Inert until a key is present:
///   defaults write com.niket.cuebooth tmdbApiKey -string "<key>"
/// Accepts a v3 API key or a v4 bearer token.
@MainActor
final class PosterLookup {
    struct Poster {
        let key: String
        let base64: String
        let mimeType: String
        let image: NSImage
        let title: String?
    }

    /// Services whose artwork is worth looking up; music services already get
    /// real cover art from the page or iTunes.
    static let videoServices: Set<String> = ["netflix", "prime", "hotstar"]

    var onPoster: ((Poster) -> Void)?

    private let credential: String
    private var cache: [String: Poster] = [:]
    private var misses: Set<String> = []
    private var inflight: Set<String> = []

    init(defaults: UserDefaults) {
        credential = defaults.string(forKey: "tmdbApiKey") ?? ""
    }

    var isConfigured: Bool { !credential.isEmpty }

    func poster(for title: String) -> Poster? {
        guard isConfigured else { return nil }
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        if let hit = cache[key] { return hit }
        guard !misses.contains(key), !inflight.contains(key) else { return nil }
        inflight.insert(key)
        Task { [weak self] in
            guard let self else { return }
            let result = await Self.fetch(title: title, key: key, credential: self.credential)
            self.inflight.remove(key)
            if let result {
                self.cache[key] = result
                self.onPoster?(result)
            } else {
                self.misses.insert(key)
            }
        }
        return nil
    }

    /// Player titles carry episode detail ("Show: Season 2: Episode 3"), which
    /// TMDB won't match, so progressively shorter prefixes are tried.
    static func searchVariants(of title: String) -> [String] {
        var variants: [String] = []
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { variants.append(trimmed) }
        for separator in [":", " - ", " | ", " – "] {
            if let range = trimmed.range(of: separator) {
                let head = String(trimmed[..<range.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if head.count >= 2, !variants.contains(head) { variants.append(head) }
            }
        }
        return variants
    }

    private static func fetch(title: String, key: String, credential: String) async -> Poster? {
        for variant in searchVariants(of: title) {
            guard let hit = await search(variant, credential: credential) else { continue }
            guard let url = URL(string: "https://image.tmdb.org/t/p/w780\(hit.path)"),
                  let (data, response) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data)
            else { continue }
            let mime = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type") ?? "image/jpeg"
            return Poster(
                key: key, base64: data.base64EncodedString(), mimeType: mime,
                image: image, title: hit.name)
        }
        return nil
    }

    private static func search(
        _ query: String, credential: String
    ) async -> (path: String, name: String?)? {
        var components = URLComponents(string: "https://api.themoviedb.org/3/search/multi")!
        var items = [URLQueryItem(name: "query", value: query),
                     URLQueryItem(name: "include_adult", value: "false")]
        let usesBearer = credential.hasPrefix("ey")
        if !usesBearer { items.append(URLQueryItem(name: "api_key", value: credential)) }
        components.queryItems = items
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        if usesBearer {
            request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else { return nil }

        for result in results {
            let type = result["media_type"] as? String
            guard type == "tv" || type == "movie" else { continue }
            guard let path = result["poster_path"] as? String, !path.isEmpty else { continue }
            return (path, result["name"] as? String ?? result["title"] as? String)
        }
        return nil
    }
}
