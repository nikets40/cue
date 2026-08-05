import AppKit
import CueKit
import Foundation

/// Talks to VLC's built-in HTTP interface for the things MediaRemote can't
/// express — browsing the playlist and jumping to a specific entry.
///
/// Requires the interface to be enabled once (see tools/enable-vlc-http.sh):
///   defaults write org.videolan.vlc extraintf -string http
///   defaults write org.videolan.vlc http-password -string <password>
/// VLC authenticates with an empty username and that password.
@MainActor
final class VLCClient {
    static let bundleIdentifier = "org.videolan.vlc"

    private let host: String
    private let port: Int
    private let password: String

    init(defaults: UserDefaults) {
        host = "127.0.0.1"
        port = (UserDefaults(suiteName: "org.videolan.vlc")?.object(forKey: "http-port") as? Int) ?? 8080
        password = defaults.string(forKey: "vlcPassword") ?? ""
    }

    var isConfigured: Bool { !password.isEmpty }

    func playlist() async -> [PlaylistItem]? {
        guard let json = await get("/requests/playlist.json") else { return nil }
        var items: [PlaylistItem] = []
        collect(node: json, into: &items)
        return items
    }

    func play(id: Int) async {
        _ = await get("/requests/status.json?command=pl_play&id=\(id)")
    }

    func resume() async {
        _ = await get("/requests/status.json?command=pl_play")
    }

    /// `pl_forcepause` rather than `pl_pause`, which toggles and would start
    /// playback on an already-paused item.
    func pause() async {
        _ = await get("/requests/status.json?command=pl_forcepause")
    }

    /// VLC's web interface can't raise its window, so the app is brought
    /// forward through LaunchServices instead.
    func bringToFront() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleIdentifier)
        else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
    }

    /// What VLC currently holds, for the source list. Nil when VLC isn't
    /// running or its web interface is off.
    func status() async -> (title: String, playing: Bool)? {
        guard let json = await get("/requests/status.json") else { return nil }
        let state = json["state"] as? String ?? "stopped"
        let meta = (json["information"] as? [String: Any])
            .flatMap { $0["category"] as? [String: Any] }
            .flatMap { $0["meta"] as? [String: Any] }
        let title = (meta?["title"] as? String)
            ?? (meta?["filename"] as? String)
            ?? "VLC"
        guard state != "stopped" || meta != nil else { return nil }
        return (title, state == "playing")
    }

    // MARK: - Internals

    /// VLC returns the playlist as a tree of nodes; leaves carry the media.
    private func collect(node: [String: Any], into items: inout [PlaylistItem]) {
        if let children = node["children"] as? [[String: Any]] {
            for child in children { collect(node: child, into: &items) }
            return
        }
        guard node["type"] as? String == "leaf",
              let idString = node["id"] as? String ?? (node["id"] as? Int).map(String.init),
              let id = Int(idString)
        else { return }
        let duration = (node["duration"] as? Int).map(Double.init)
        items.append(PlaylistItem(
            id: id,
            title: node["name"] as? String ?? "Untitled",
            duration: duration.flatMap { $0 > 0 ? $0 : nil },
            isCurrent: node["current"] != nil))
        // VLC plays local files, so there's no thumbnail URL to hand over.
    }

    private func get(_ path: String) async -> [String: Any]? {
        guard isConfigured, let url = URL(string: "http://\(host):\(port)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        let credentials = Data(":\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
