//
//  EngineAudioBackend.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
final class EngineAudioBackend: AudioPlaybackBackend {
    private struct SoundPlayback {
        let playerNode: AVAudioPlayerNode
        let mixerNode: AVAudioMixerNode
        let buffer: AVAudioPCMBuffer
    }

    private let engine = AVAudioEngine()
    private let bundle: Bundle
    private var sounds: [String: SoundPlayback] = [:]
    private var outgoingSounds: [String: SoundPlayback] = [:]
    private var fadeTasks: [String: Task<Void, Never>] = [:]
    private var outgoingCleanupTask: Task<Void, Never>?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        // macOS no usa AVAudioSession; AVAudioEngine se mezcla con el sistema por defecto.
    }

    @discardableResult
    func load(sound: Sound) -> Bool {
        if sounds[sound.id] != nil { return true }

        if let outgoing = outgoingSounds.removeValue(forKey: sound.id) {
            fadeTasks[sound.id]?.cancel()
            fadeTasks[sound.id] = nil
            sounds[sound.id] = outgoing
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
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else {
                NSLog("MoodistMac: failed to allocate audio buffer for sound '%@'", sound.id)
                return false
            }

            try audioFile.read(into: buffer)

            let playback = SoundPlayback(
                playerNode: AVAudioPlayerNode(),
                mixerNode: AVAudioMixerNode(),
                buffer: buffer
            )
            attach(playback)
            playback.playerNode.scheduleBuffer(buffer, at: nil, options: [.loops])
            sounds[sound.id] = playback
            return true
        } catch {
            NSLog("MoodistMac: failed to load sound '%@' from %@: %@", sound.id, url.path, String(describing: error))
            return false
        }
    }

    func setVolume(soundId: String, volume: Double, globalVolume: Double) {
        guard let playback = sounds[soundId] else { return }
        fadeTasks[soundId]?.cancel()
        fadeTasks[soundId] = nil
        playback.mixerNode.outputVolume = Float(volume * globalVolume)
    }

    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) {
        guard let playback = sounds[soundId] else { return }
        fade(soundId: soundId, mixerNode: playback.mixerNode, targetVolume: Float(volume * globalVolume), duration: fadeDuration)
    }

    func play(soundId: String) {
        guard let playback = sounds[soundId] else { return }
        guard ensureEngineIsRunning() else { return }
        if !playback.playerNode.isPlaying {
            playback.playerNode.play()
        }
    }

    func pause(soundId: String) {
        sounds[soundId]?.playerNode.pause()
    }

    func unload(soundId: String) {
        guard let playback = sounds.removeValue(forKey: soundId) else { return }
        fadeTasks[soundId]?.cancel()
        fadeTasks[soundId] = nil
        detach(playback)
        if sounds.isEmpty && outgoingSounds.isEmpty {
            engine.stop()
        }
    }

    func unloadAll() {
        cancelCrossfadeAndCleanup()
        for (_, playback) in sounds {
            detach(playback)
        }
        sounds.removeAll()
        engine.stop()
    }

    func playAll(ids: [String]) {
        guard ensureEngineIsRunning() else { return }
        for id in ids {
            guard let playback = sounds[id], !playback.playerNode.isPlaying else { continue }
            playback.playerNode.play()
        }
    }

    func pauseAll(ids: [String]) {
        for id in ids {
            sounds[id]?.playerNode.pause()
        }
    }

    func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        for (id, item) in state where item.isSelected {
            setVolume(soundId: id, volume: item.volume, globalVolume: globalVolume)
        }
    }

    func fadeOutAndUnload(soundId: String, duration: TimeInterval) {
        guard let playback = sounds.removeValue(forKey: soundId) else { return }
        outgoingSounds[soundId] = playback
        fade(soundId: soundId, mixerNode: playback.mixerNode, targetVolume: 0, duration: duration)
    }

    func scheduleOutgoingCleanup(after duration: TimeInterval) {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.1) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.cleanupOutgoingSounds()
        }
    }

    func cancelCrossfadeAndCleanup() {
        outgoingCleanupTask?.cancel()
        outgoingCleanupTask = nil
        cleanupOutgoingSounds()
    }

    private func attach(_ playback: SoundPlayback) {
        engine.attach(playback.playerNode)
        engine.attach(playback.mixerNode)
        engine.connect(playback.playerNode, to: playback.mixerNode, format: playback.buffer.format)
        engine.connect(playback.mixerNode, to: engine.mainMixerNode, format: playback.buffer.format)
    }

    private func detach(_ playback: SoundPlayback) {
        playback.playerNode.stop()
        engine.disconnectNodeOutput(playback.playerNode)
        engine.disconnectNodeOutput(playback.mixerNode)
        engine.detach(playback.playerNode)
        engine.detach(playback.mixerNode)
    }

    private func fade(soundId: String, mixerNode: AVAudioMixerNode, targetVolume: Float, duration: TimeInterval) {
        fadeTasks[soundId]?.cancel()

        guard duration > 0 else {
            mixerNode.outputVolume = targetVolume
            fadeTasks[soundId] = nil
            return
        }

        let startVolume = mixerNode.outputVolume
        let steps = max(1, Int(duration * 30))
        fadeTasks[soundId] = Task { @MainActor [weak self, weak mixerNode] in
            for step in 1...steps {
                guard !Task.isCancelled else { return }
                let progress = Float(step) / Float(steps)
                mixerNode?.outputVolume = startVolume + ((targetVolume - startVolume) * progress)
                try? await Task.sleep(nanoseconds: UInt64(duration / Double(steps) * 1_000_000_000))
            }
            mixerNode?.outputVolume = targetVolume
            self?.fadeTasks[soundId] = nil
        }
    }

    private func cleanupOutgoingSounds() {
        for (id, playback) in outgoingSounds {
            fadeTasks[id]?.cancel()
            fadeTasks[id] = nil
            detach(playback)
        }
        outgoingSounds.removeAll()
        if sounds.isEmpty {
            engine.stop()
        }
    }

    private func ensureEngineIsRunning() -> Bool {
        if engine.isRunning { return true }

        do {
            try engine.start()
            return true
        } catch {
            NSLog("MoodistMac: failed to start AVAudioEngine: %@", String(describing: error))
            return false
        }
    }
}
