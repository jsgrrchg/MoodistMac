//
//  EngineAudioBackend.swift
//  MoodistMac
//

import AVFoundation
import Foundation

@MainActor
final class EngineAudioBackend: AudioPlaybackBackend {
    private final class SoundPlayback {
        let id: String
        let playerNode: AVAudioPlayerNode
        let mixerNode: AVAudioMixerNode
        let url: URL
        let format: AVAudioFormat
        var pendingLoopSchedules = 0
        var scheduleGeneration = UUID()
        var shouldBePlaying = false

        init(id: String, url: URL, format: AVAudioFormat) {
            self.id = id
            self.url = url
            self.format = format
            self.playerNode = AVAudioPlayerNode()
            self.mixerNode = AVAudioMixerNode()
        }

        func invalidateSchedule() {
            scheduleGeneration = UUID()
            pendingLoopSchedules = 0
        }
    }

    private let engine = AVAudioEngine()
    private let bundle: Bundle
    private let defaultRoutingMode: AudioRoutingMode = .mainMixer
    private let spatialRenderMode: SpatialRenderMode = .disabled
    private let loopScheduleDepth = 2
    private var sounds: [String: SoundPlayback] = [:]
    private var outgoingSounds: [String: SoundPlayback] = [:]
    private var fadeTasks: [String: Task<Void, Never>] = [:]
    private var outgoingCleanupTask: Task<Void, Never>?
    private var configurationChangeObserver: NSObjectProtocol?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        // macOS does not use AVAudioSession; AVAudioEngine mixes with the system by default.
        configurationChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEngineConfigurationChange()
            }
        }
    }

    deinit {
        if let configurationChangeObserver {
            NotificationCenter.default.removeObserver(configurationChangeObserver)
        }
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
            let playback = SoundPlayback(id: sound.id, url: url, format: audioFile.processingFormat)
            attach(playback)
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
        playback.shouldBePlaying = true
        scheduleLoopIfNeeded(playback)
        if !playback.playerNode.isPlaying {
            playback.playerNode.play()
        }
    }

    func pause(soundId: String) {
        guard let playback = sounds[soundId] else { return }
        playback.shouldBePlaying = false
        playback.playerNode.pause()
        stopEngineIfIdle()
    }

    func unload(soundId: String) {
        guard let playback = sounds.removeValue(forKey: soundId) else { return }
        fadeTasks[soundId]?.cancel()
        fadeTasks[soundId] = nil
        detach(playback)
        stopEngineIfIdle()
    }

    func unloadAll() {
        cancelCrossfadeAndCleanup()
        fadeTasks.values.forEach { $0.cancel() }
        fadeTasks.removeAll()

        for (_, playback) in sounds {
            detach(playback)
        }
        sounds.removeAll()
        engine.stop()
    }

    func playAll(ids: [String]) {
        let playbacks = ids.compactMap { sounds[$0] }
        guard !playbacks.isEmpty else { return }
        guard ensureEngineIsRunning() else { return }

        for playback in playbacks {
            playback.shouldBePlaying = true
            scheduleLoopIfNeeded(playback)
            if !playback.playerNode.isPlaying {
                playback.playerNode.play()
            }
        }
    }

    func pauseAll(ids: [String]) {
        for id in ids {
            guard let playback = sounds[id] else { continue }
            playback.shouldBePlaying = false
            playback.playerNode.pause()
        }
        stopEngineIfIdle()
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
        stopEngineIfIdle()
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
        connect(playback)
    }

    private func connect(_ playback: SoundPlayback) {
        engine.connect(playback.playerNode, to: playback.mixerNode, format: playback.format)
        engine.connect(playback.mixerNode, to: destinationNode(for: defaultRoutingMode), format: playback.format)
    }

    private func destinationNode(for routingMode: AudioRoutingMode) -> AVAudioNode {
        guard spatialRenderMode != .disabled else { return engine.mainMixerNode }

        switch routingMode {
        case .positioned:
            // Future spatial hook: attach AVAudioEnvironmentNode here and route positioned sounds through it.
            return engine.mainMixerNode
        case .mainMixer, .channel:
            return engine.mainMixerNode
        }
    }

    private func detach(_ playback: SoundPlayback) {
        playback.shouldBePlaying = false
        playback.invalidateSchedule()
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
        stopEngineIfIdle()
    }

    private func scheduleLoopIfNeeded(_ playback: SoundPlayback) {
        guard playback.pendingLoopSchedules < loopScheduleDepth else { return }

        let generation = playback.scheduleGeneration
        let soundId = playback.id
        while playback.pendingLoopSchedules < loopScheduleDepth {
            do {
                let audioFile = try AVAudioFile(forReading: playback.url)
                playback.pendingLoopSchedules += 1
                playback.playerNode.scheduleFile(audioFile, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard
                            let self,
                            let playback = self.playback(for: soundId),
                            playback.scheduleGeneration == generation
                        else { return }
                        playback.pendingLoopSchedules = max(0, playback.pendingLoopSchedules - 1)
                        if playback.shouldBePlaying {
                            self.scheduleLoopIfNeeded(playback)
                        }
                    }
                }
            } catch {
                NSLog(
                    "MoodistMac: failed to schedule sound '%@' from %@: %@",
                    playback.id, playback.url.path, String(describing: error)
                )
                break
            }
        }
    }

    private func playback(for soundId: String) -> SoundPlayback? {
        sounds[soundId] ?? outgoingSounds[soundId]
    }

    private func handleEngineConfigurationChange() {
        let activePlaybacks = Array(sounds.values) + Array(outgoingSounds.values)
        guard !activePlaybacks.isEmpty else {
            engine.stop()
            return
        }

        engine.stop()
        for playback in activePlaybacks {
            playback.invalidateSchedule()
            playback.playerNode.stop()
            engine.disconnectNodeOutput(playback.playerNode)
            engine.disconnectNodeOutput(playback.mixerNode)
            connect(playback)
            if playback.shouldBePlaying {
                scheduleLoopIfNeeded(playback)
            }
        }

        guard hasActivePlayback else {
            engine.stop()
            return
        }

        guard ensureEngineIsRunning() else { return }
        for playback in activePlaybacks where playback.shouldBePlaying {
            playback.playerNode.play()
        }
    }

    private var hasActivePlayback: Bool {
        sounds.values.contains { $0.shouldBePlaying }
            || outgoingSounds.values.contains { $0.shouldBePlaying }
    }

    private func stopEngineIfIdle() {
        guard !hasActivePlayback else { return }
        engine.pause()
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
