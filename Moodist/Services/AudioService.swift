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
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.prepareToPlay()
            players[sound.id] = player
            return player
        } catch {
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
