//
//  AudioService.swift
//  MoodistMac
//

import Combine
import Foundation

@MainActor
public final class AudioService: ObservableObject {
    @Published public private(set) var lastError: String?
    public var onFailure: ((String) -> Void)?
    public var preparePlayback: (() throws -> Void)?
    public var playbackDidStop: (() -> Void)?
    public var isPlaying: Bool { backend.isPlaying }

    private func observeFailures() {
        backend.onFailure = { [weak self] message in
            self?.lastError = message
            self?.onFailure?(message)
        }
    }
    private func prepare() -> Bool {
        do { try preparePlayback?(); lastError = nil; return true }
        catch { lastError = error.localizedDescription; onFailure?(error.localizedDescription); return false }
    }
    public func rebuild() { backend.unloadAll() }
    public static let crossfadeDuration: TimeInterval = 1.5

    private var backend: AudioPlaybackBackend

    public init() {
        self.backend = Self.makeDefaultBackend()
        observeFailures()
    }

    public init(backend: AudioPlaybackBackend) {
        self.backend = backend
        observeFailures()
    }

    @discardableResult
    public func load(sound: Sound) -> Bool {
        backend.load(sound: sound)
    }

    // Sets a sound's volume together with global volume. Missing sounds are ignored.
    public func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume)
    }

    /// Sets volume with a smooth crossfade transition.
    public func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume, fadeDuration: fadeDuration)
    }

    public func play(soundId: String) {
        guard prepare() else { return }
        backend.play(soundId: soundId)
    }

    public func pause(soundId: String) {
        backend.pause(soundId: soundId)
        if !backend.isPlaying { playbackDidStop?() }
    }

    /// Stops playback and removes the player to free memory.
    /// Call this when a sound is deselected.
    public func unload(soundId: String) {
        backend.unload(soundId: soundId)
        if !backend.isPlaying { playbackDidStop?() }
    }

    /// Removes all loaded players to free memory, useful after unselectAll or reset.
    public func unloadAll() {
        backend.unloadAll()
        playbackDidStop?()
    }

    public func playAll(ids: [String]) {
        guard !ids.isEmpty, prepare() else { return }
        backend.playAll(ids: ids)
    }

    public func pauseAll(ids: [String]) {
        backend.pauseAll(ids: ids)
        if !backend.isPlaying { playbackDidStop?() }
    }

    public func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        backend.updateVolumes(state: state, globalVolume: globalVolume)
    }

    // MARK: - Crossfade

    /// Moves an active player to outgoing and fades it out to volume 0.
    public func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        backend.fadeOutAndUnload(soundId: soundId, duration: duration)
    }

    /// Schedules outgoing player cleanup after the fade duration.
    public func scheduleOutgoingCleanup(after duration: TimeInterval) {
        backend.scheduleOutgoingCleanup(after: duration)
    }

    /// Cancels any in-progress crossfade and cleans outgoing players immediately.
    public func cancelCrossfadeAndCleanup() {
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
