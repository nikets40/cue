import ActivityKit
import AppIntents
import CueKit
import Foundation
import Network

// Shared between the app and the CueWidgets extension.

struct CueActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var artist: String
        var playing: Bool
        /// Elapsed seconds as of `timestamp`; views extrapolate with a timer
        /// interval so progress keeps moving without content updates.
        var elapsedTime: Double
        var duration: Double
        var timestamp: Date
        /// ~64 px JPEG. Kept tiny: ActivityKit content states have a hard
        /// payload budget (~4 KB).
        var artworkThumb: Data?

        /// The fixed wall-clock span of the whole track, for
        /// `ProgressView(timerInterval:)`.
        var trackInterval: ClosedRange<Date> {
            let start = timestamp.addingTimeInterval(-max(elapsedTime, 0))
            let end = start.addingTimeInterval(max(duration, 1))
            return start...min(max(end, start.addingTimeInterval(1)), start.addingTimeInterval(86_400))
        }
    }

    var boothName: String
}

// MARK: - Interactive intents
// LiveActivityIntent runs in the app's process: the system launches the app
// in the background, so we get network access and can talk to Booth.

struct TogglePlayPauseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Play/Pause"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await QuickCommand.send(.togglePlayPause)
        return .result()
    }
}

struct NextTrackIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await QuickCommand.send(.nextTrack)
        return .result()
    }
}

struct PreviousTrackIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await QuickCommand.send(.previousTrack)
        return .result()
    }
}

// MARK: - Fire-and-refresh command channel

/// A short-lived connection used from intents while the app is backgrounded:
/// browse Bonjour → connect → hello → command → read the echoed state →
/// refresh the Live Activity with it. Every step is bounded so the whole
/// round trip stays within the intent's execution window.
enum QuickCommand {
    static func send(_ action: CueCommand.Action, value: Double? = nil) async {
        guard let endpoint = await browse(timeout: 2.5) else { return }
        let token = UserDefaults.standard.string(forKey: "boothToken") ?? ""

        let parameters = NWParameters.tcp
        let webSocket = NWProtocolWebSocket.Options()
        webSocket.autoReplyPing = true
        parameters.defaultProtocolStack.applicationProtocols.insert(webSocket, at: 0)
        let connection = NWConnection(to: endpoint, using: parameters)
        defer { connection.cancel() }

        let ready: Bool = await withCheckedContinuation { continuation in
            var resumed = false
            connection.stateUpdateHandler = { state in
                guard !resumed else { return }
                switch state {
                case .ready: resumed = true; continuation.resume(returning: true)
                case .failed, .cancelled: resumed = true; continuation.resume(returning: false)
                default: break
                }
            }
            connection.start(queue: .main)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if !resumed { resumed = true; continuation.resume(returning: false) }
            }
        }
        guard ready else { return }

        guard await sendFrame(try? CueProtocol.encoder().encode(ClientHello(token: token)), over: connection),
              let first = await receive(over: connection, timeout: 2),
              decodeState(first) != nil
        else { return }

        _ = await sendFrame(
            try? CueProtocol.encoder().encode(CueCommand(action: action, value: value)),
            over: connection)

        // The command triggers a broadcast (~100 ms); use it to refresh the
        // Live Activity so the card reflects the tap immediately.
        if let echoed = await receive(over: connection, timeout: 2),
           let state = decodeState(echoed) {
            await updateActivity(with: state)
        }
    }

    private static func decodeState(_ data: Data) -> NowPlayingState? {
        guard let message = try? CueProtocol.decoder().decode(ServerMessage.self, from: data),
              message.type == .state
        else { return nil }
        return message.state
    }

    @MainActor
    private static func updateActivity(with state: NowPlayingState) async {
        guard let activity = Activity<CueActivityAttributes>.activities.first else { return }
        var content = activity.content.state
        content.title = state.title ?? content.title
        content.artist = state.artist ?? content.artist
        content.playing = state.playing
        content.elapsedTime = state.elapsedTime ?? content.elapsedTime
        content.duration = state.duration ?? content.duration
        content.timestamp = state.timestamp ?? Date()
        await activity.update(ActivityContent(state: content, staleDate: nil))
    }

    private static func browse(timeout: TimeInterval) async -> NWEndpoint? {
        await withCheckedContinuation { continuation in
            var resumed = false
            let browser = NWBrowser(
                for: .bonjour(type: CueProtocol.bonjourServiceType, domain: nil),
                using: .tcp)
            func finish(_ endpoint: NWEndpoint?) {
                guard !resumed else { return }
                resumed = true
                browser.cancel()
                continuation.resume(returning: endpoint)
            }
            browser.browseResultsChangedHandler = { results, _ in
                if let first = results.first { finish(first.endpoint) }
            }
            browser.start(queue: .main)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { finish(nil) }
        }
    }

    private static func sendFrame(_ data: Data?, over connection: NWConnection) async -> Bool {
        guard let data else { return false }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "message", metadata: [metadata])
        return await withCheckedContinuation { continuation in
            connection.send(content: data, contentContext: context, isComplete: true,
                            completion: .contentProcessed { error in
                continuation.resume(returning: error == nil)
            })
        }
    }

    private static func receive(over connection: NWConnection, timeout: TimeInterval) async -> Data? {
        await withCheckedContinuation { continuation in
            var resumed = false
            connection.receiveMessage { data, _, _, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: data)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if !resumed { resumed = true; continuation.resume(returning: nil) }
            }
        }
    }
}
