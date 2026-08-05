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
    /// Network failures aren't cached as misses (the title may well exist), so
    /// a cooldown keeps a flaky connection from being retried on every media
    /// event until it recovers.
    private var retryAfter: [String: Date] = [:]
    private static let retryCooldown: TimeInterval = 60

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
        if let next = retryAfter[key], next > Date() { return nil }
        inflight.insert(key)
        Task { [weak self] in
            guard let self else { return }
            let outcome = await Self.fetch(title: title, key: key, credential: self.credential)
            self.inflight.remove(key)
            switch outcome {
            case .poster(let poster):
                self.retryAfter[key] = nil
                self.cache[key] = poster
                self.onPoster?(poster)
            case .notFound:
                self.misses.insert(key)
            case .unreachable:
                self.retryAfter[key] = Date().addingTimeInterval(Self.retryCooldown)
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

    /// Distinguishes "TMDB says there's nothing" from "the request never got
    /// there" — the API is intermittently unreachable on some networks, and a
    /// transient failure must not be remembered as a miss.
    enum SearchOutcome {
        case found(path: String, name: String?)
        case noResult
        case unreachable
    }

    enum FetchOutcome {
        case poster(Poster)
        case notFound
        case unreachable
    }

    private static func fetch(title: String, key: String, credential: String) async -> FetchOutcome {
        var sawNetworkFailure = false
        for variant in searchVariants(of: title) {
            var hit: (path: String, name: String?)?
            // Retry around flaky connectivity before giving up on this variant.
            for attempt in 0..<3 {
                switch await search(variant, credential: credential) {
                case .found(let path, let name):
                    hit = (path, name)
                case .noResult:
                    hit = nil
                case .unreachable:
                    sawNetworkFailure = true
                    if attempt < 2 {
                        try? await Task.sleep(for: .milliseconds(400 * (attempt + 1)))
                        continue
                    }
                }
                break
            }
            guard let hit else { continue }
            guard let url = URL(string: "https://image.tmdb.org/t/p/w780\(hit.path)"),
                  let (data, response) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data)
            else { continue }
            let mime = (response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Type") ?? "image/jpeg"
            return .poster(Poster(
                key: key, base64: data.base64EncodedString(), mimeType: mime,
                image: image, title: hit.name))
        }
        if sawNetworkFailure {
            log("TMDB unreachable for \"\(title)\" — retrying in \(Int(retryCooldown))s")
            return .unreachable
        }
        return .notFound
    }

    private static func search(_ query: String, credential: String) async -> SearchOutcome {
        var components = URLComponents(string: "https://api.themoviedb.org/3/search/multi")!
        var items = [URLQueryItem(name: "query", value: query),
                     URLQueryItem(name: "include_adult", value: "false")]
        let usesBearer = credential.hasPrefix("ey")
        if !usesBearer { items.append(URLQueryItem(name: "api_key", value: credential)) }
        components.queryItems = items
        guard let url = components.url else { return .noResult }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        if usesBearer {
            request.setValue("Bearer \(credential)", forHTTPHeaderField: "Authorization")
        }
        guard let (data, response) = try? await URLSession.shared.data(for: request) else {
            return .unreachable
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        // 5xx and rate limiting are worth retrying; a bad key is not.
        if status >= 500 || status == 429 { return .unreachable }
        guard status == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]]
        else {
            if status == 401 { log("TMDB rejected the key (401)") }
            return .noResult
        }

        for result in results {
            let type = result["media_type"] as? String
            guard type == "tv" || type == "movie" else { continue }
            guard let path = result["poster_path"] as? String, !path.isEmpty else { continue }
            return .found(
                path: path,
                name: result["name"] as? String ?? result["title"] as? String)
        }
        return .noResult
    }
}
