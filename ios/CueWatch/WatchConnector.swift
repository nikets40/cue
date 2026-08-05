import CueKit
import Foundation
import WatchConnectivity

/// The watch's whole view of the world. Everything arrives from the phone,
/// which does the actual talking to Booth.
@MainActor
final class WatchConnector: NSObject, ObservableObject {
    @Published private(set) var payload = WatchPayload()
    /// True once anything has arrived. Until then the UI shows "connecting"
    /// rather than an empty player, which would look broken.
    @Published private(set) var hasReceived = false
    /// Set when a command couldn't be delivered, so the tap doesn't just
    /// appear to do nothing.
    @Published var lastError: String?

    /// Volume the user is turning the crown to, held locally until the phone
    /// confirms — otherwise an in-flight update snaps the crown backwards.
    @Published var pendingVolume: Double?
    private var volumeSettleTask: Task<Void, Never>?

    private var session: WCSession { WCSession.default }

    func activate() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    /// The application context may have been set before this app launched, so
    /// take whatever is already there, then ask for a fresh one.
    func refresh() {
        apply(context: session.receivedApplicationContext)
        guard session.isReachable else { return }
        session.sendMessage([WatchMessage.requestState: true]) { [weak self] reply in
            guard let data = reply[WatchMessage.payload] as? Data else { return }
            Task { @MainActor in self?.apply(data: data) }
        } errorHandler: { _ in }
    }

    func send(_ action: CueCommand.Action, value: Double? = nil) {
        guard session.isReachable else {
            lastError = "iPhone unreachable"
            return
        }
        var message: [String: Any] = [WatchMessage.command: action.rawValue]
        if let value { message[WatchMessage.value] = value }
        session.sendMessage(message, replyHandler: { _ in }) { [weak self] error in
            Task { @MainActor in self?.lastError = error.localizedDescription }
        }
    }

    /// The crown emits a continuous stream; sending every value would flood the
    /// link. This forwards as it turns but keeps the local value authoritative
    /// briefly afterwards so the phone's echo doesn't fight the user.
    func setVolume(_ value: Double) {
        pendingVolume = value
        send(.setVolume, value: value)
        volumeSettleTask?.cancel()
        volumeSettleTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.pendingVolume = nil }
        }
    }

    private func apply(context: [String: Any]) {
        guard let data = context[WatchMessage.payload] as? Data else { return }
        apply(data: data)
    }

    private func apply(data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchPayload.self, from: data) else { return }
        payload = decoded
        hasReceived = true
    }
}

extension WatchConnector: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in self.refresh() }
    }

    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.apply(context: context) }
    }
}
