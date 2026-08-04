import Combine
import CueKit
import Foundation
import Network
import UIKit

/// Discovers Cue Booth instances via Bonjour and speaks the CueKit WebSocket
/// protocol over an NWConnection opened directly against the Bonjour endpoint
/// (no manual host/port resolution needed).
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
        case failed(String)
    }

    @Published private(set) var phase: Phase = .browsing
    @Published private(set) var booths: [Booth] = []
    /// Connect as soon as a single Booth appears; turned off after a manual
    /// disconnect so the user can pick from the list.
    private var autoConnect = true
    @Published private(set) var state: NowPlayingState?
    @Published private(set) var artwork: UIImage?

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var artworkCacheKey: String?

    // MARK: - Discovery

    func startBrowsing() {
        guard browser == nil else { return }
        let browser = NWBrowser(
            for: .bonjour(type: CueProtocol.bonjourServiceType, domain: nil),
            using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                self?.booths = results.compactMap { result in
                    guard case .service(let name, _, _, _) = result.endpoint else { return nil }
                    return Booth(name: name, result: result)
                }
                .sorted { $0.name < $1.name }
                if let self, self.autoConnect, case .browsing = self.phase,
                   self.booths.count == 1, let only = self.booths.first {
                    self.connect(to: only)
                }
            }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    // MARK: - Connection

    func connect(to booth: Booth) {
        disconnect()
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
                    self.phase = .connected(booth.name)
                case .failed(let error):
                    self.phase = .failed(error.localizedDescription)
                    self.teardown()
                case .cancelled:
                    if self.phase != .browsing { self.phase = .browsing }
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
        connection?.cancel()
        teardown()
        phase = .browsing
    }

    private func teardown() {
        connection = nil
        state = nil
        artwork = nil
        artworkCacheKey = nil
    }

    private func receive(over connection: NWConnection) {
        connection.receiveMessage { [weak self, weak connection] data, _, _, error in
            Task { @MainActor in
                guard let self, let connection else { return }
                if let data, !data.isEmpty { self.handle(data) }
                if error == nil {
                    self.receive(over: connection)
                } else {
                    self.phase = .failed("Connection lost")
                    self.teardown()
                }
            }
        }
    }

    private func handle(_ data: Data) {
        guard let message = try? CueProtocol.decoder().decode(ServerMessage.self, from: data),
              message.type == .state, let newState = message.state
        else { return }
        state = newState
        if newState.artworkBase64 != artworkCacheKey {
            artworkCacheKey = newState.artworkBase64
            artwork = newState.artworkBase64
                .flatMap { Data(base64Encoded: $0) }
                .flatMap { UIImage(data: $0) }
        }
    }

    // MARK: - Commands

    func send(_ action: CueCommand.Action, value: Double? = nil) {
        guard let connection,
              let data = try? CueProtocol.encoder().encode(CueCommand(action: action, value: value))
        else { return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "command", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true,
                        completion: .contentProcessed { _ in })
    }
}
