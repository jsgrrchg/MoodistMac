//
//  AudioService.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
final class AudioService: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private let bundle = Bundle.main

    init() {
        // macOS no usa AVAudioSession; la reproducción se mezcla con el sistema por defecto.
    }

    func load(sound: Sound) -> AVAudioPlayer? {
        if let existing = players[sound.id] { return existing }

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

    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        guard let player = players[soundId] else { return }
        player.volume = Float(volume * globalVolume)
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
}
