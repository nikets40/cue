import AVFoundation
import MediaPlayer
import UIKit

/// Routes the iPhone's physical volume buttons to the Mac while the remote is
/// front-most: an active (silent) audio session makes the buttons adjust our
/// session volume, which we observe via KVO; each change becomes a relative
/// step sent to Booth. A hidden MPVolumeView suppresses the system volume HUD
/// and lets us re-center the phone's own volume to 0.5 after every press so
/// presses never stop registering at the 0/1 extremes.
@MainActor
final class HardwareVolumeSync: NSObject, ObservableObject {
    /// Called with a step in Mac-volume percent (e.g. +6.25 per press).
    var onVolumeStep: ((Double) -> Void)?

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private var volumeView: MPVolumeView?
    private var slider: UISlider?
    private var reference: Float = 0.5
    private var swallowNextChange = false
    private var active = false

    func start() {
        guard !active else { return }
        active = true
        // Same category/options as BackgroundKeepAlive so the two never flap
        // the shared session against each other.
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)

        let view = MPVolumeView(frame: CGRect(x: -200, y: -200, width: 1, height: 1))
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
           let window = scene.windows.first {
            window.addSubview(view)
        }
        volumeView = view
        slider = view.subviews.compactMap { $0 as? UISlider }.first

        reference = session.outputVolume
        recenter()
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            let value = change.newValue ?? 0
            Task { @MainActor in self?.handle(value) }
        }
    }

    func stop() {
        guard active else { return }
        active = false
        observation?.invalidate()
        observation = nil
        volumeView?.removeFromSuperview()
        volumeView = nil
        slider = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handle(_ newValue: Float) {
        if swallowNextChange {
            swallowNextChange = false
            reference = newValue
            return
        }
        let delta = Double(newValue - reference)
        reference = newValue
        guard abs(delta) > 0.001 else { return }
        onVolumeStep?(delta * 100)
        recenter()
    }

    private func recenter() {
        guard let slider, abs(reference - 0.5) > 0.01 else { return }
        swallowNextChange = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            slider.value = 0.5
            self?.reference = 0.5
        }
    }
}
