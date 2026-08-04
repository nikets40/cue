import AVFoundation
import Foundation

/// Keeps the app running while backgrounded by looping a silent, mixable
/// audio buffer (UIBackgroundModes: audio). This holds the WebSocket to Booth
/// open, so track changes on the Mac update the Live Activity in real time —
/// the free-account alternative to ActivityKit push updates. Runs only while
/// connected; `mixWithOthers` keeps it inaudible and non-interrupting.
@MainActor
final class BackgroundKeepAlive {
    static let shared = BackgroundKeepAlive()

    private var player: AVAudioPlayer?

    func start() {
        guard player == nil else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
        player = try? AVAudioPlayer(data: Self.makeSilentWav())
        player?.numberOfLoops = -1
        player?.volume = 0
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
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
