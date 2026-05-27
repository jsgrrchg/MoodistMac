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
        self.backend = LegacyAudioPlayerBackend()
    }

    init(backend: AudioPlaybackBackend) {
        self.backend = backend
    }

    @discardableResult
    func load(sound: Sound) -> Bool {
        backend.load(sound: sound)
    }

    // Ajusta el volumen de un sonido específico, aplicando también el volumen global. Si el sonido no está cargado, no hace nada.
    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume)
    }

    /// Ajusta volumen con transición suave (crossfade).
    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        backend.setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume, fadeDuration: fadeDuration)
    }

    func play(soundId: String) {
        backend.play(soundId: soundId)
    }

    func pause(soundId: String) {
        backend.pause(soundId: soundId)
    }

    /// Deja de reproducir y elimina el player del diccionario para liberar memoria.
    /// Debe llamarse cuando un sonido se deselecciona.
    func unload(soundId: String) {
        backend.unload(soundId: soundId)
    }

    /// Elimina todos los players cargados (libera memoria). Útil tras unselectAll o reset.
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

    /// Mueve un player activo a outgoing e inicia fade-out a volumen 0.
    func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        backend.fadeOutAndUnload(soundId: soundId, duration: duration)
    }

    /// Programa la limpieza de outgoing players tras la duración del fade.
    func scheduleOutgoingCleanup(after duration: TimeInterval) {
        backend.scheduleOutgoingCleanup(after: duration)
    }

    /// Cancela cualquier crossfade en curso y limpia outgoing players inmediatamente.
    func cancelCrossfadeAndCleanup() {
        backend.cancelCrossfadeAndCleanup()
    }
}
