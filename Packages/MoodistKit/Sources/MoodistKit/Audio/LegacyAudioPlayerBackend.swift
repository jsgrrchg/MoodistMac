//
//  LegacyAudioPlayerBackend.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
public final class LegacyAudioPlayerBackend: AudioPlaybackBackend {
    public var isPlaying: Bool { players.values.contains { $0.isPlaying } }
    public var onFailure: ((String) -> Void)?
    private var players: [String: AVAudioPlayer] = [:]
    private let bundle: Bundle

    /// Players currently fading out and waiting for cleanup.
    private var outgoingPlayers: [String: AVAudioPlayer] = [:]
    private var outgoingCleanupTask: Task<Void, Never>?

    public init(bundle: Bundle = MoodistResources.bundle) {
        self.bundle = bundle
        // macOS does not use AVAudioSession; playback mixes with the system by default.
    }

    @discardableResult
    public func load(sound: Sound) -> Bool {
        if players[sound.id] != nil { return true }

        // If it was outgoing during fade-out, move it back to the active pool.
        if let outgoing = outgoingPlayers.removeValue(forKey: sound.id) {
            players[sound.id] = outgoing
            return true
        }

        let name = (sound.fileName as NSString).deletingPathExtension
        let ext = (sound.fileName as NSString).pathExtension
        let subdir = "sounds/\(sound.categoryFolder)"
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdir) else {
            onFailure?("Missing audio: \(sound.id)")
            NSLog("MoodistMac: sound resource not found: %@/%@.%@", subdir, name, ext)
            return false
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            players[sound.id] = player
            return true
        } catch {
            onFailure?(error.localizedDescription)
            NSLog("MoodistMac: failed to load sound '%@' from %@: %@", sound.id, url.path, String(describing: error))
            return false
        }
    }

    public func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        guard let player = players[soundId] else { return }
        player.volume = Float(volume * globalVolume)
    }

    public func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        guard let player = players[soundId] else { return }
        player.setVolume(Float(volume * globalVolume), fadeDuration: fadeDuration)
    }

    public func play(soundId: String) {
        players[soundId]?.play()
    }

    public func pause(soundId: String) {
        players[soundId]?.pause()
    }

    public func unload(soundId: String) {
        players[soundId]?.stop()
        players.removeValue(forKey: soundId)
    }

    public func unloadAll() {
        cancelCrossfadeAndCleanup()
        for (_, player) in players {
            player.stop()
        }
        players.removeAll()
    }

    public func playAll(ids: [String]) {
        for id in ids { players[id]?.play() }
    }

    public func pauseAll(ids: [String]) {
        for id in ids { players[id]?.pause() }
    }

    public func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        for (id, item) in state where item.isSelected {
            setVolume(soundId: id, volume: item.volume, globalVolume: globalVolume)
        }
    }

    public func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        guard let player = players.removeValue(forKey: soundId) else { return }
        player.setVolume(0, fadeDuration: duration)
        outgoingPlayers[soundId] = player
    }

    public func scheduleOutgoingCleanup(after duration: TimeInterval) {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.1) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.cleanupOutgoingPlayers()
        }
    }

    public func cancelCrossfadeAndCleanup() {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = nil
        cleanupOutgoingPlayers()
    }

    private func cleanupOutgoingPlayers() {
        for (_, player) in outgoingPlayers {
            player.stop()
        }
        outgoingPlayers.removeAll()
    }
}
