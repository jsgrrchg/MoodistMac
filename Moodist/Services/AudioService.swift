//
//  AudioService.swift
//  MoodistMac
//

import Combine
import Foundation

@MainActor
final class AudioService: ObservableObject {
    static let crossfadeDuration: TimeInterval = 1.5

    private let backend: AudioPlaybackBackend

    init() {
        self.backend = Self.makeDefaultBackend()
    }

    init(backend: AudioPlaybackBackend) {
        self.backend = backend
    }

    @discardableResult
    func load(sound: Sound) -> Bool {
        backend.load(sound: sound)
    }

    // Sets a sound's volume together with global volume. Missing sounds are ignored.
    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume)
    }

    /// Sets volume with a smooth crossfade transition.
    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume, fadeDuration: fadeDuration)
    }

    func play(soundId: String) {
        backend.play(soundId: soundId)
    }

    func pause(soundId: String) {
        backend.pause(soundId: soundId)
    }

    /// Stops playback and removes the player to free memory.
    /// Call this when a sound is deselected.
    func unload(soundId: String) {
        backend.unload(soundId: soundId)
    }

    /// Removes all loaded players to free memory, useful after unselectAll or reset.
    func unloadAll() {
        backend.unloadAll()
    }

    func playAll(ids: [String]) {
        backend.playAll(ids: ids)
    }

    func pauseAll(ids: [String]) {
        backend.pauseAll(ids: ids)
    }

    func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        backend.updateVolumes(state: state, globalVolume: globalVolume)
    }

    // MARK: - Crossfade

    /// Moves an active player to outgoing and fades it out to volume 0.
    func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        backend.fadeOutAndUnload(soundId: soundId, duration: duration)
    }

    /// Schedules outgoing player cleanup after the fade duration.
    func scheduleOutgoingCleanup(after duration: TimeInterval) {
        backend.scheduleOutgoingCleanup(after: duration)
    }

    /// Cancels any in-progress crossfade and cleans outgoing players immediately.
    func cancelCrossfadeAndCleanup() {
        backend.cancelCrossfadeAndCleanup()
    }

    private static func makeDefaultBackend() -> AudioPlaybackBackend {
        let processInfo = ProcessInfo.processInfo
        let backendName = processInfo.environment["MOODIST_AUDIO_BACKEND"]?.lowercased()
        let usesLegacyArgument = processInfo.arguments.contains("--audio-backend=legacy")

        if backendName == "legacy" || usesLegacyArgument {
            return LegacyAudioPlayerBackend()
        }

        return EngineAudioBackend()
    }
}
