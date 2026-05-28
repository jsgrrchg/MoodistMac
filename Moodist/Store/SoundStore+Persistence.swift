import Combine
import Foundation

extension SoundStore {
    // Initializes in-memory state from defaults and persisted values.
    func bootstrapState() {
        SoundsData.categories.flatMap(\.sounds).forEach { sounds[$0.id] = .default }
        // Restore sound state only for IDs that still exist in the current catalog.
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

    // Connects state publishers to reactive persistence, using debounce where useful.
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

    /// Presents the save panel and exports preferences to JSON.
    /// - Returns: true when the user saved successfully.
    func exportPreferences() -> Bool {
        PreferencesExportService.presentExportPanel(
            presets: presets,
            favoriteMixIds: favoriteMixIds,
            favoriteSoundIds: favoriteSoundIds
        )
    }

    /// Presents the open panel, reads a preferences JSON file, and applies the imported values.
    /// - Returns: true when the user imported successfully.
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
        // Rehydrate main collections from the imported payload.
        presets = sanitizedPresets
        favoriteMixIds = orderedUnique(payload.favoriteMixIds.filter { validMixIds.contains($0) })
        favoriteSoundIds = orderedUnique(
            payload.favoriteSoundIds.filter { validSoundIds.contains($0) })
        // Sync the isFavorite flag inside the sounds dictionary.
        let favoriteSet = Set(favoriteSoundIds)
        var next = sounds
        for (id, var item) in next {
            item.isFavorite = favoriteSet.contains(id)
            next[id] = item
        }
        sounds = next
        return true
    }

    // Restores the app to factory defaults and clears persisted preferences.
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
    // Validates and sanitizes an imported preset, keeping valid sounds, clamped volumes, and a non-empty unique ID.
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
