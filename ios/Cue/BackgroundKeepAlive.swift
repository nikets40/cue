import AVFoundation
import Foundation
import UIKit

/// Keeps the app running while backgrounded by looping a silent, mixable
/// audio buffer (UIBackgroundModes: audio). This holds the WebSocket to Booth
/// open, so track changes on the Mac update the Live Activity in real time —
/// the free-account alternative to ActivityKit push updates. Runs only while
/// connected; `mixWithOthers` keeps it inaudible and non-interrupting.
@MainActor
final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()

    private var player: AVAudioPlayer?
    private var observers: [NSObjectProtocol] = []
    private var watchdog: Timer?
    /// Whether the keep-alive is meant to be running, as distinct from whether
    /// it currently is — the two diverge exactly when this class has to repair
    /// itself.
    private var shouldRun = false
    /// Called after the keep-alive repairs itself. That moment is the best
    /// signal available that the app may have been suspended, and therefore
    /// that the socket to Booth needs checking.
    var onRestart: (() -> Void)?

    func start() {
        shouldRun = true
        observeAudioSession()
        startWatchdog()
        startPlayer()
    }

    func stop() {
        shouldRun = false
        watchdog?.invalidate()
        watchdog = nil
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
        player?.stop()
        player = nil
    }

    @discardableResult
    private func startPlayer() -> Bool {
        if player?.isPlaying == true { return true }
        player = nil
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return false
        }
        guard let created = try? AVAudioPlayer(data: Self.makeSilentWav()) else { return false }
        created.numberOfLoops = -1
        // Full volume on purpose. The buffer is silence, so this is inaudible
        // either way, and a zero-volume player is a weaker claim to be an app
        // that is actually playing audio — which is the whole basis for being
        // allowed to keep running.
        created.volume = 1
        created.prepareToPlay()
        guard created.play() else { return false }
        player = created
        return true
    }

    /// Anything that stops the silent player also lets iOS suspend the app,
    /// which kills the socket to Booth — and then the Live Activity sits on an
    /// old track until the app is opened by hand. Interruptions are the common
    /// cause: a call, Siri, or another app claiming audio.
    private func observeAudioSession() {
        guard observers.isEmpty else { return }
        let centre = NotificationCenter.default

        observers.append(centre.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(), queue: .main
        ) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard let type = raw.flatMap(AVAudioSession.InterruptionType.init) else { return }
            Task { @MainActor in
                guard let self, self.shouldRun else { return }
                switch type {
                case .began:
                    // The system has already paused us; drop the player so the
                    // restart below builds a fresh one.
                    self.player = nil
                case .ended:
                    self.restart()
                @unknown default:
                    self.restart()
                }
            }
        })

        // Losing a route (headphones unplugged, Bluetooth dropping) pauses
        // playback under the same rules as a real audio app.
        observers.append(centre.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(), queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.shouldRun else { return }
                if self.player?.isPlaying != true { self.restart() }
            }
        })

        // Media services can be torn down wholesale; every AVAudioPlayer built
        // before that point is dead and has to be recreated.
        observers.append(centre.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.shouldRun else { return }
                self.restart()
            }
        })

        // The moment that decides whether the app keeps running. If the player
        // isn't genuinely going by now, iOS suspends us and the socket to Booth
        // dies with it — which is exactly when the Live Activity goes stale.
        observers.append(centre.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.shouldRun else { return }
                if !self.startPlayer() { self.restart() }
            }
        })
    }

    /// Notifications can be missed — during suspension, or when an
    /// interruption ends without the resume hint — so the state is also
    /// checked on a timer. This is the difference between recovering in
    /// seconds and staying dead until the user opens the app.
    private func startWatchdog() {
        watchdog?.invalidate()
        let timer = Timer(timeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.shouldRun else { return }
                if self.player?.isPlaying != true { self.restart() }
            }
        }
        // Common mode so it keeps firing while the UI is being scrolled.
        RunLoop.main.add(timer, forMode: .common)
        watchdog = timer
    }

    private func restart() {
        player?.stop()
        player = nil
        startPlayer()
        onRestart?()
    }

    /// One second of 8 kHz mono 16-bit PCM silence.
    private static func makeSilentWav() -> Data {
        let sampleRate: UInt32 = 8000
        let dataSize = sampleRate * 2
        var wav = Data()
        func append(_ text: String) { wav.append(contentsOf: text.utf8) }
        func append32(_ value: UInt32) { withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) } }
        func append16(_ value: UInt16) { withUnsafeBytes(of: value.littleEndian) { wav.append(contentsOf: $0) } }
        append("RIFF"); append32(36 + dataSize); append("WAVE")
        append("fmt "); append32(16); append16(1); append16(1)
        append32(sampleRate); append32(sampleRate * 2); append16(2); append16(16)
        append("data"); append32(dataSize)
        wav.append(Data(count: Int(dataSize)))
        return wav
    }
}
