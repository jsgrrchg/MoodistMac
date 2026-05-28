import Foundation

extension SoundStore {
    // Selects a sound, loads it into audio, and starts playback immediately.
    func select(_ id: String) {
        currentMixId = nil
        currentMixIconName = nil
        guard var item = sounds[id] else { return }
        item.isSelected = true
        sounds[id] = item
        addToRecentSounds(soundId: id)
        if let sound = SoundsData.allSoundsById[id] {
            _ = audioService.load(sound: sound)
            audioService.setVolume(soundId: id, volume: 0, globalVolume: 1.0)
            isPlaying = true
            audioService.playAll(ids: selectedIds)
            audioService.setVolume(
                soundId: id, volume: item.volume, globalVolume: globalVolume,
                fadeDuration: AudioService.crossfadeDuration)
        }
    }

    // Deselects a sound and releases its associated player.
    func unselect(_ id: String) {
        currentMixId = nil
        currentMixIconName = nil
        guard var item = sounds[id] else { return }
        item.isSelected = false
        sounds[id] = item
        audioService.pause(soundId: id)
        audioService.unload(soundId: id)
        if !hasSelection {
            isPlaying = false
        }
    }

    // Clears the whole selection in one batch to reduce re-renders.
    func unselectAll() {
        currentMixId = nil
        currentMixIconName = nil
        guard hasSelection else { return }
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
        audioService.unloadAll()
        // Use one state update to avoid repeated re-renders and UI stalls.
        var next = sounds
        let ids = Array(next.keys)
        for id in ids {
            if var item = next[id] {
                item.isSelected = false
                next[id] = item
            }
        }
        sounds = next
    }

    // Adjusts the individual volume in both state and the audio engine.
    func setVolume(_ id: String, _ volume: Double) {
        guard var item = sounds[id] else { return }
        item.volume = volume
        sounds[id] = item
        audioService.setVolume(soundId: id, volume: volume, globalVolume: globalVolume)
    }

    // Adjusts global volume and recomputes the effective audio mix.
    func setGlobalVolume(_ volume: Double) {
        globalVolume = volume
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
    }

    // Pauses active playback without changing the selection.
    func stopPlayback() {
        guard isPlaying else { return }
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
    }

    // Toggles play/pause while respecting whether a selection exists.
    func togglePlay() {
        guard hasSelection else {
            if isPlaying { isPlaying = false }
            return
        }
        isPlaying.toggle()
        if isPlaying {
            for sound in SoundsData.categories.flatMap(\.sounds) {
                if sounds[sound.id]?.isSelected == true {
                    _ = audioService.load(sound: sound)
                }
            }
            audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
            audioService.playAll(ids: selectedIds)
        } else {
            audioService.cancelCrossfadeAndCleanup()
            audioService.pauseAll(ids: selectedIds)
        }
    }

    // Builds a random four-sound selection and plays it with crossfade.
    func shuffle() {
        let allIds = Array(sounds.keys)
        guard allIds.count >= 4 else { return }
        let picked = Array(allIds.shuffled().prefix(4))
        var volumes: [String: Double] = [:]
        for id in picked {
            volumes[id] = Double.random(in: 0.2...1.0)
        }
        let shufflePreset = Preset(name: "Shuffle", soundIds: picked, volumes: volumes)
        applyPreset(shufflePreset, startPlaying: true)
        currentMixId = nil
        currentMixIconName = nil
    }

    // Ensures the audio engine reflects the current selection and volumes.
    func updatePlaybackForSelection() {
        for sound in SoundsData.categories.flatMap(\.sounds) {
            if sounds[sound.id]?.isSelected == true {
                _ = audioService.load(sound: sound)
            }
        }
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
        if isPlaying { audioService.playAll(ids: selectedIds) }
    }

    // Resets only selection and favorites without clearing presets or global preferences.
    func resetSelectionAndFavorites() {
        currentMixId = nil
        currentMixIconName = nil
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
        audioService.unloadAll()
        let ids = Array(sounds.keys)
        for id in ids {
            if var item = sounds[id] {
                item.isSelected = false
                item.isFavorite = false
                item.volume = 0.5
                sounds[id] = item
            }
        }
        favoriteSoundIds = []
        favoriteMixIds = []
    }
}
