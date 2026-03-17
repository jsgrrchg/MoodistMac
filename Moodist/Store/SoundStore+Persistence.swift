import Combine
import Foundation

extension SoundStore {
    // Inicializa el estado en memoria combinando defaults + valores persistidos.
    func bootstrapState() {
        SoundsData.categories.flatMap(\.sounds).forEach { sounds[$0.id] = .default }
        // Restaura estado de sonidos sólo para ids aún válidos en el catálogo actual.
        if let saved = PersistenceService.loadSounds() {
            for (id, item) in saved where sounds[id] != nil {
                sounds[id] = item
            }
        }
        if let g = PersistenceService.loadGlobalVolume() {
            globalVolume = g
        }
        presets = PersistenceService.loadPresets()
        recentMixIds = PersistenceService.loadRecentMixIds()
        recentSoundIds = PersistenceService.loadRecentSoundIds()
        let soundLimit = PersistenceService.loadMaxRecentSoundsCount()
        if recentSoundIds.count > soundLimit {
            recentSoundIds = Array(recentSoundIds.prefix(soundLimit))
        }
        favoriteMixIds = PersistenceService.loadFavoriteMixIds()
        favoriteSoundIds = PersistenceService.loadFavoriteSoundIds()
        if favoriteSoundIds.isEmpty, !favoriteIds.isEmpty {
            favoriteSoundIds = favoriteIds.sorted()
        }
    }

    // Conecta publishers de estado con persistencia reactiva (con debounce donde conviene).
    func setupPersistence() {
        $sounds
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { PersistenceService.saveSounds($0) }
            .store(in: &cancellables)
        $globalVolume
            .dropFirst()
            .sink { PersistenceService.saveGlobalVolume($0) }
            .store(in: &cancellables)
        $presets
            .dropFirst()
            .sink { PersistenceService.savePresets($0) }
            .store(in: &cancellables)
        $recentMixIds
            .dropFirst()
            .sink { PersistenceService.saveRecentMixIds($0) }
            .store(in: &cancellables)
        $recentSoundIds
            .dropFirst()
            .sink { PersistenceService.saveRecentSoundIds($0) }
            .store(in: &cancellables)
        $favoriteMixIds
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { PersistenceService.saveFavoriteMixIds($0) }
            .store(in: &cancellables)
        $favoriteSoundIds
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { PersistenceService.saveFavoriteSoundIds($0) }
            .store(in: &cancellables)
    }

    /// Presenta el panel de guardado y exporta preferencias (mixes personalizados, mixes favoritos, sonidos favoritos) a un JSON.
    /// - Returns: true si el usuario guardó correctamente.
    func exportPreferences() -> Bool {
        PreferencesExportService.presentExportPanel(
            presets: presets,
            favoriteMixIds: favoriteMixIds,
            favoriteSoundIds: favoriteSoundIds
        )
    }

    /// Presenta el panel de abrir, lee un JSON de preferencias y aplica presets, mixes favoritos y sonidos favoritos.
    /// - Returns: true si el usuario importó correctamente.
    func importPreferences() -> Bool {
        guard let payload = PreferencesImportService.presentImportPanel() else { return false }
        let validSoundIds = Set(sounds.keys)
        var seenPresetIds = Set<String>()
        let sanitizedPresets = payload.presets.compactMap { preset -> Preset? in
            guard let sanitizedPreset = sanitizeImportedPreset(preset, validSoundIds: validSoundIds)
            else { return nil }
            guard seenPresetIds.insert(sanitizedPreset.id).inserted else { return nil }
            return sanitizedPreset
        }
        let validMixIds = Set(MixesData.allMixesById.keys).union(sanitizedPresets.map(\.id))
        // Rehidrata colecciones principales desde el payload importado.
        presets = sanitizedPresets
        favoriteMixIds = orderedUnique(payload.favoriteMixIds.filter { validMixIds.contains($0) })
        favoriteSoundIds = orderedUnique(
            payload.favoriteSoundIds.filter { validSoundIds.contains($0) })
        // Sincroniza la bandera isFavorite dentro del diccionario de sonidos.
        let favoriteSet = Set(favoriteSoundIds)
        var next = sounds
        for (id, var item) in next {
            item.isFavorite = favoriteSet.contains(id)
            next[id] = item
        }
        sounds = next
        return true
    }

    // Restablece la app a estado "factory default" y limpia preferencias persistidas.
    func resetAllToDefaults() {
        cancelSleepTimer()
        currentMixId = nil
        currentMixIconName = nil
        isPlaying = false
        audioService.cancelCrossfadeAndCleanup()
        audioService.pauseAll(ids: selectedIds)
        audioService.unloadAll()
        globalVolume = 1.0
        let ids = Array(sounds.keys)
        var next = sounds
        for id in ids {
            if var item = next[id] {
                item.isSelected = false
                item.isFavorite = false
                item.volume = 0.5
                next[id] = item
            }
        }
        sounds = next
        presets = []
        recentMixIds = []
        recentSoundIds = []
        favoriteMixIds = []
        favoriteSoundIds = []
        timerUsageCounts = [:]
        PersistenceService.resetAll()
    }

    private func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
    // Valida y limpia un preset importado, asegurando que sólo contenga sonidos válidos y volúmenes en rango, y que su id sea único y no vacío.
    private func sanitizeImportedPreset(_ preset: Preset, validSoundIds: Set<String>) -> Preset? {
        let presetId = preset.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !presetId.isEmpty else { return nil }
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let iconName = preset.iconName.trimmingCharacters(in: .whitespacesAndNewlines)
        let soundIds = orderedUnique(preset.soundIds.filter { validSoundIds.contains($0) })
        guard !soundIds.isEmpty else { return nil }

        var volumes: [String: Double] = [:]
        for soundId in soundIds {
            guard let volume = preset.volumes[soundId] else { continue }
            volumes[soundId] = min(max(volume, 0), 1)
        }

        return Preset(
            id: presetId,
            name: name.isEmpty ? L10n.customMix : name,
            iconName: iconName.isEmpty ? "sparkles" : iconName,
            soundIds: soundIds,
            volumes: volumes
        )
    }
}
