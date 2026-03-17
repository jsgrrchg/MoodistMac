import Foundation

extension SoundStore {
    // Selecciona un sonido, lo carga en audio y arranca reproducción inmediata.
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

    // Quita selección de un sonido y libera su reproductor asociado.
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

    // Limpia toda la selección en un único batch para reducir re-renders.
    func unselectAll() {
        currentMixId = nil
        currentMixIconName = nil
        guard hasSelection else { return }
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
        audioService.unloadAll()
        // Una sola actualización del estado para evitar muchos re-renders y bloqueos de la UI.
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

    // Ajusta volumen individual (estado + motor de audio).
    func setVolume(_ id: String, _ volume: Double) {
        guard var item = sounds[id] else { return }
        item.volume = volume
        sounds[id] = item
        audioService.setVolume(soundId: id, volume: volume, globalVolume: globalVolume)
    }

    // Ajusta volumen global y recalcula mezcla efectiva en audio.
    func setGlobalVolume(_ volume: Double) {
        globalVolume = volume
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
    }

    // Pausa reproducción activa sin alterar selección.
    func stopPlayback() {
        guard isPlaying else { return }
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
    }

    // Alterna play/pause respetando si hay o no selección activa.
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

    // Construye selección aleatoria de 4 sonidos y reproduce con crossfade.
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

    // Asegura que el motor de audio refleje la selección/volúmenes actuales.
    func updatePlaybackForSelection() {
        for sound in SoundsData.categories.flatMap(\.sounds) {
            if sounds[sound.id]?.isSelected == true {
                _ = audioService.load(sound: sound)
            }
        }
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
        if isPlaying { audioService.playAll(ids: selectedIds) }
    }

    // Resetea sólo selección y favoritos (sin borrar presets ni preferencias globales).
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
