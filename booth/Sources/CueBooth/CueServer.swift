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
    @Published private(set) var clientCount = 0

    var onCommand: ((CueCommand) -> Void)?

    private var listener: NWListener?
    private var connections: [ObjectIdentifier: NWConnection] = [:]
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
        for connection in connections.values { send(data, over: connection) }
    }

    private func accept(_ connection: NWConnection) {
        connections[ObjectIdentifier(connection)] = connection
        clientCount = connections.count
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            Task { @MainActor in
                guard let self, let connection else { return }
                switch state {
                case .ready:
                    // New clients immediately get the current state.
                    if let data = self.lastSnapshotData { self.send(data, over: connection) }
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
                if let data, !data.isEmpty {
                    if let command = try? CueProtocol.decoder().decode(CueCommand.self, from: data) {
                        self.onCommand?(command)
                    }
                }
                if error == nil, connection.state == .ready || connection.state == .preparing {
                    self.receive(over: connection)
                } else if error != nil {
                    self.drop(connection)
                }
            }
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
        connections.removeValue(forKey: ObjectIdentifier(connection))
        clientCount = connections.count
    }
}
