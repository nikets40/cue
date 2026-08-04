import CoreAudio
import Foundation

/// Direct CoreAudio access to the default output device's volume.
/// Synchronous and effectively instant, unlike shelling out to osascript.
enum SystemVolume {
    private static func defaultOutputDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return status == noErr && deviceID != kAudioObjectUnknown ? deviceID : nil
    }

    /// Volume elements to try, in order: master, then left/right channels
    /// (many USB/Bluetooth devices only expose per-channel volume).
    private static func volumeElements(for device: AudioDeviceID) -> [UInt32] {
        let candidates: [UInt32] = [kAudioObjectPropertyElementMain, 1, 2]
        return candidates.filter { element in
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element)
            return AudioObjectHasProperty(device, &address)
        }
    }

    /// Current volume, 0–100.
    static func get() -> Double? {
        guard let device = defaultOutputDevice() else { return nil }
        let elements = volumeElements(for: device)
        guard !elements.isEmpty else { return nil }
        var total: Float = 0
        var count = 0
        for element in elements.prefix(elements.first == kAudioObjectPropertyElementMain ? 1 : 2) {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element)
            var value: Float = 0
            var size = UInt32(MemoryLayout<Float>.size)
            if AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr {
                total += value
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return Double(total / Float(count)) * 100
    }

    /// Set volume, 0–100.
    static func set(_ percent: Double) {
        guard let device = defaultOutputDevice() else { return }
        var value = Float(min(max(percent, 0), 100) / 100)
        let elements = volumeElements(for: device)
        let targets = elements.first == kAudioObjectPropertyElementMain ? [elements[0]] : elements
        for element in targets {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: element)
            var isSettable = DarwinBoolean(false)
            guard AudioObjectIsPropertySettable(device, &address, &isSettable) == noErr,
                  isSettable.boolValue
            else { continue }
            AudioObjectSetPropertyData(
                device, &address, 0, nil, UInt32(MemoryLayout<Float>.size), &value)
        }
    }
}
