import CueKit
import Foundation
import Network

/// WebSocket server advertised over Bonjour. Pushes full `NowPlayingState`
/// snapshots to every client and forwards received `CueCommand`s.
@MainActor
final class CueServer: ObservableObject {
    enum Status: Equatable {
        case stopped
        case starting
        case listening(port: UInt16)
        case failed(String)
    }

    @Published private(set) var status: Status = .stopped
    /// Authenticated clients only; connections that never complete pairing are
    /// not counted.
    @Published private(set) var clientCount = 0

    var onCommand: ((CueCommand) -> Void)?
    /// Pairing token clients must present in their `ClientHello`. Set before `start()`.
    var pairingToken = ""

    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
    private var authenticated: Set<ObjectIdentifier> = []
    private var lastSnapshotData: Data?

    func start(port: UInt16 = CueProtocol.defaultPort) {
        guard listener == nil else { return }
        status = .starting

        let parameters = NWParameters.tcp
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)

        do {
            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)
            listener.service = NWListener.Service(name: Host.current().localizedName, type: CueProtocol.bonjourServiceType)
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection) }
            }
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready: self?.status = .listening(port: port)
                    case .failed(let error): self?.status = .failed(error.localizedDescription)
                    case .cancelled: self?.status = .stopped
                    default: break
                    }
                }
            }
            listener.start(queue: .main)
            self.listener = listener
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func broadcast(_ state: NowPlayingState) {
        guard let data = try? CueProtocol.encoder().encode(ServerMessage(state: state)) else { return }
        lastSnapshotData = data
        for (id, connection) in connections where authenticated.contains(id) {
            send(data, over: connection)
        }
    }

    private func accept(_ connection: NWConnection) {
        connections[ObjectIdentifier(connection)] = connection
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            Task { @MainActor in
                guard let self, let connection else { return }
                switch state {
                case .failed, .cancelled:
                    self.drop(connection)
                default:
                    break
                }
            }
        }
        receive(over: connection)
        connection.start(queue: .main)
    }

    private func receive(over connection: NWConnection) {
        connection.receiveMessage { [weak self, weak connection] data, _, _, error in
            Task { @MainActor in
                guard let self, let connection else { return }
                if let data, !data.isEmpty { self.handle(data, from: connection) }
                if error == nil, connection.state == .ready || connection.state == .preparing {
                    self.receive(over: connection)
                } else if error != nil {
                    self.drop(connection)
                }
            }
        }
    }

    private func handle(_ data: Data, from connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        guard authenticated.contains(id) else {
            // Silent until a correct hello arrives; wrong token gets one
            // authFailed reply and the connection is closed.
            if let hello = try? CueProtocol.decoder().decode(ClientHello.self, from: data),
               !pairingToken.isEmpty, hello.token == pairingToken {
                authenticated.insert(id)
                clientCount = authenticated.count
                if let snapshot = lastSnapshotData { send(snapshot, over: connection) }
            } else if let reply = try? CueProtocol.encoder().encode(ServerMessage(type: .authFailed)) {
                send(reply, over: connection)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak connection] in
                    guard let connection else { return }
                    Task { @MainActor in self?.drop(connection) }
                }
            }
            return
        }
        if let command = try? CueProtocol.decoder().decode(CueCommand.self, from: data) {
            onCommand?(command)
        }
    }

    private func send(_ data: Data, over connection: NWConnection) {
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "state", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true,
                        completion: .contentProcessed { _ in })
    }

    private func drop(_ connection: NWConnection) {
        connection.cancel()
        let id = ObjectIdentifier(connection)
        connections.removeValue(forKey: id)
        authenticated.remove(id)
        clientCount = authenticated.count
    }
}
