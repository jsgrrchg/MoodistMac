//
//  LegacyAudioPlayerBackend.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
final class LegacyAudioPlayerBackend: AudioPlaybackBackend {
    private var players: [String: AVAudioPlayer] = [:]
    private let bundle: Bundle

    /// Players en proceso de fade-out, pendientes de limpieza.
    private var outgoingPlayers: [String: AVAudioPlayer] = [:]
    private var outgoingCleanupTask: Task<Void, Never>?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        // macOS no usa AVAudioSession; la reproduccion se mezcla con el sistema por defecto.
    }

    @discardableResult
    func load(sound: Sound) -> Bool {
        if players[sound.id] != nil { return true }

        // Si estaba en outgoing (fade-out en curso), rescatarlo al pool activo.
        if let outgoing = outgoingPlayers.removeValue(forKey: sound.id) {
            players[sound.id] = outgoing
            return true
        }

        let name = (sound.fileName as NSString).deletingPathExtension
        let ext = (sound.fileName as NSString).pathExtension
        let subdir = "sounds/\(sound.categoryFolder)"
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdir) else {
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
            NSLog("MoodistMac: failed to load sound '%@' from %@: %@", sound.id, url.path, String(describing: error))
            return false
        }
    }

    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        guard let player = players[soundId] else { return }
        player.volume = Float(volume * globalVolume)
    }

    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        guard let player = players[soundId] else { return }
        player.setVolume(Float(volume * globalVolume), fadeDuration: fadeDuration)
    }

    func play(soundId: String) {
        players[soundId]?.play()
    }

    func pause(soundId: String) {
        players[soundId]?.pause()
    }

    func unload(soundId: String) {
        players[soundId]?.stop()
        players.removeValue(forKey: soundId)
    }

    func unloadAll() {
        cancelCrossfadeAndCleanup()
        for (_, player) in players {
            player.stop()
        }
        players.removeAll()
    }

    func playAll(ids: [String]) {
        for id in ids { players[id]?.play() }
    }

    func pauseAll(ids: [String]) {
        for id in ids { players[id]?.pause() }
    }

    func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        for (id, item) in state where item.isSelected {
            setVolume(soundId: id, volume: item.volume, globalVolume: globalVolume)
        }
    }

    func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        guard let player = players.removeValue(forKey: soundId) else { return }
        player.setVolume(0, fadeDuration: duration)
        outgoingPlayers[soundId] = player
    }

    func scheduleOutgoingCleanup(after duration: TimeInterval) {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.1) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.cleanupOutgoingPlayers()
        }
    }

    func cancelCrossfadeAndCleanup() {
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
