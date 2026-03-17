//
//  AudioService.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
final class AudioService: ObservableObject {
    static let crossfadeDuration: TimeInterval = 1.5

    private var players: [String: AVAudioPlayer] = [:]
    private let bundle = Bundle.main

    /// Players en proceso de fade-out, pendientes de limpieza.
    private var outgoingPlayers: [String: AVAudioPlayer] = [:]
    private var outgoingCleanupTask: Task<Void, Never>?

    init() {
        // macOS no usa AVAudioSession; la reproducción se mezcla con el sistema por defecto.
    }
    // Carga un sonido en memoria y devuelve su AVAudioPlayer. Si ya está cargado, devuelve el player existente.
    func load(sound: Sound) -> AVAudioPlayer? {
        if let existing = players[sound.id] { return existing }

        // Si estaba en outgoing (fade-out en curso), rescatarlo al pool activo.
        if let outgoing = outgoingPlayers.removeValue(forKey: sound.id) {
            players[sound.id] = outgoing
            return outgoing
        }

        let name = (sound.fileName as NSString).deletingPathExtension
        let ext = (sound.fileName as NSString).pathExtension
        let subdir = "sounds/\(sound.categoryFolder)"
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdir) else {
            NSLog("MoodistMac: sound resource not found: %@/%@.%@", subdir, name, ext)
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            players[sound.id] = player
            return player
        } catch {
            NSLog("MoodistMac: failed to load sound '%@' from %@: %@", sound.id, url.path, String(describing: error))
            return nil
        }
    }
    // Ajusta el volumen de un sonido específico, aplicando también el volumen global. Si el sonido no está cargado, no hace nada.
    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        guard let player = players[soundId] else { return }
        player.volume = Float(volume * globalVolume)
    }

    /// Ajusta volumen con transición suave (crossfade).
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

    /// Deja de reproducir y elimina el player del diccionario para liberar memoria.
    /// Debe llamarse cuando un sonido se deselecciona.
    func unload(soundId: String) {
        players[soundId]?.stop()
        players.removeValue(forKey: soundId)
    }

    /// Elimina todos los players cargados (libera memoria). Útil tras unselectAll o reset.
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

    // MARK: - Crossfade

    /// Mueve un player activo a outgoing e inicia fade-out a volumen 0.
    func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        guard let player = players.removeValue(forKey: soundId) else { return }
        player.setVolume(0, fadeDuration: duration)
        outgoingPlayers[soundId] = player
    }

    /// Programa la limpieza de outgoing players tras la duración del fade.
    func scheduleOutgoingCleanup(after duration: TimeInterval) {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.1) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.cleanupOutgoingPlayers()
        }
    }

    /// Cancela cualquier crossfade en curso y limpia outgoing players inmediatamente.
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
