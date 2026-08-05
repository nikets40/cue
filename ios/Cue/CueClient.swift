import Combine
import CueKit
import Foundation
import Network
import UIKit

/// Discovers Cue Booth instances via Bonjour and speaks the CueKit WebSocket
/// protocol over an NWConnection opened directly against the Bonjour endpoint
/// (no manual host/port resolution needed).
///
/// Connection lifecycle: connect → send `ClientHello` with the stored pairing
/// token → server replies with a state snapshot (paired) or `authFailed`
/// (show the pairing screen). Drops are retried automatically unless the user
/// disconnected on purpose.
@MainActor
final class CueClient: ObservableObject {
    struct Booth: Identifiable, Equatable {
        let name: String
        let result: NWBrowser.Result

        var id: String { name }

        static func == (lhs: Booth, rhs: Booth) -> Bool { lhs.name == rhs.name }
    }

    enum Phase: Equatable {
        case browsing
        case connecting(String)
        case connected(String)
        case needsPairing(String)
        case failed(String)
    }

    @Published private(set) var phase: Phase = .browsing
    @Published private(set) var booths: [Booth] = []
    @Published private(set) var state: NowPlayingState?
    @Published private(set) var artwork: UIImage?
    /// Last playlist Booth sent; nil until requested, empty when the source
    /// has none reachable.
    @Published private(set) var playlist: [PlaylistItem]?
    @Published private(set) var playlistLoading = false
    @Published private(set) var sources: [MediaSource]?
    @Published private(set) var sourcesLoading = false

    /// Fires after every applied state message — including while the app is
    /// backgrounded (kept alive by BackgroundKeepAlive), where SwiftUI
    /// onChange isn't a reliable hook. Used to refresh the Live Activity.
    var onStateUpdate: (() -> Void)?

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var currentBooth: Booth?
    private(set) var artworkCacheKey: String?
    /// Connect as soon as a single Booth appears, and retry dropped
    /// connections; turned off by a deliberate disconnect so the user can pick
    /// from the list.
    private var autoConnect = true
    private var retryScheduled = false

    private var pairingToken: String {
        get { UserDefaults.standard.string(forKey: "boothToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "boothToken") }
    }

    // MARK: - Discovery

    func startBrowsing() {
        guard browser == nil else { return }
        let browser = NWBrowser(
            for: .bonjour(type: CueProtocol.bonjourServiceType, domain: nil),
            using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self else { return }
                self.booths = results.compactMap { result in
                    guard case .service(let name, _, _, _) = result.endpoint else { return nil }
                    return Booth(name: name, result: result)
                }
                .sorted { $0.name < $1.name }
                if self.autoConnect, case .browsing = self.phase,
                   self.booths.count == 1, let only = self.booths.first {
                    self.connect(to: only)
                }
            }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    /// Call when the app returns to the foreground: reconnect if the link died
    /// while backgrounded.
    func reconnectIfNeeded() {
        guard autoConnect, connection == nil, let booth = currentBooth ?? booths.first else { return }
        connect(to: booth)
    }

    // MARK: - Connection

    func connect(to booth: Booth) {
        connection?.cancel()
        connection = nil
        currentBooth = booth
        phase = .connecting(booth.name)

        let parameters = NWParameters.tcp
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)

        let connection = NWConnection(to: booth.result.endpoint, using: parameters)
        connection.stateUpdateHandler = { [weak self] connectionState in
            Task { @MainActor in
                guard let self else { return }
                switch connectionState {
                case .ready:
                    self.sendHello()
                case .failed:
                    self.connectionDropped()
                case .cancelled:
                    break
                default:
                    break
                }
            }
        }
        receive(over: connection)
        connection.start(queue: .main)
        self.connection = connection
    }

    func disconnect() {
        autoConnect = false
        currentBooth = nil
        connection?.cancel()
        teardown()
        phase = .browsing
    }

    func submitPairingCode(_ code: String) {
        pairingToken = code.trimmingCharacters(in: .whitespaces)
        autoConnect = true
        if let booth = currentBooth ?? booths.first { connect(to: booth) }
    }

    private func teardown() {
        connection = nil
        state = nil
        artwork = nil
        artworkCacheKey = nil
    }

    private func connectionDropped() {
        connection?.cancel()
        teardown()
        guard autoConnect, let booth = currentBooth else {
            phase = .browsing
            return
        }
        phase = .connecting(booth.name)
        guard !retryScheduled else { return }
        retryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.retryScheduled = false
                if self.connection == nil, self.autoConnect, let booth = self.currentBooth {
                    self.connect(to: booth)
                }
            }
        }
    }

    private func receive(over connection: NWConnection) {
        connection.receiveMessage { [weak self, weak connection] data, _, _, error in
            Task { @MainActor in
                guard let self, let connection, connection === self.connection else { return }
                if let data, !data.isEmpty { self.handle(data) }
                if error == nil {
                    self.receive(over: connection)
                } else {
                    self.connectionDropped()
                }
            }
        }
    }

    func requestPlaylist() {
        playlistLoading = true
        send(.requestPlaylist)
    }

    func requestSources() {
        sourcesLoading = true
        send(.requestSources)
    }

    private func handle(_ data: Data) {
        guard let message = try? CueProtocol.decoder().decode(ServerMessage.self, from: data) else { return }
        switch message.type {
        case .playlist:
            playlistLoading = false
            playlist = message.playlist ?? []
        case .sources:
            sourcesLoading = false
            sources = message.sources ?? []
        case .authFailed:
            let name = currentBooth?.name ?? "Cue Booth"
            connection?.cancel()
            connection = nil
            phase = .needsPairing(name)
        case .state:
            guard let newState = message.state else { return }
            if case .connecting(let name) = phase { phase = .connected(name) }
            state = newState
            if newState.artworkBase64 != artworkCacheKey {
                artworkCacheKey = newState.artworkBase64
                artwork = newState.artworkBase64
                    .flatMap { Data(base64Encoded: $0) }
                    .flatMap { UIImage(data: $0) }
            }
            onStateUpdate?()
        }
    }

    // MARK: - Outgoing messages

    private func sendHello() {
        guard let connection,
              let data = try? CueProtocol.encoder().encode(ClientHello(token: pairingToken))
        else { return }
        sendFrame(data, over: connection)
    }

    func send(_ action: CueCommand.Action, value: Double? = nil, target: String? = nil) {
        guard let connection,
              let data = try? CueProtocol.encoder()
                .encode(CueCommand(action: action, value: value, target: target))
        else { return }
        sendFrame(data, over: connection)
    }

    private func sendFrame(_ data: Data, over connection: NWConnection) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true,
                        completion: .contentProcessed { _ in })
    }
}
