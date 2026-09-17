import MoodistKit
import Combine
import Foundation

extension SoundStore {
    // Initializes in-memory state from defaults and persisted values.
    func bootstrapState() {
        SoundsData.categories.flatMap(\.sounds).forEach { sounds[$0.id] = .default }
        // Restore sound state only for IDs that still exist in the current catalog.
        if let saved = preferences.loadSounds() {
            for (id, item) in saved where sounds[id] != nil {
                sounds[id] = item
            }
        }
        if let g = preferences.loadGlobalVolume() {
            globalVolume = g
        }
        presets = preferences.loadPresets()
        recentMixIds = preferences.loadRecentMixIds()
        recentSoundIds = preferences.loadRecentSoundIds()
        let soundLimit = preferences.loadMaxRecentSoundsCount()
        if recentSoundIds.count > soundLimit {
            recentSoundIds = Array(recentSoundIds.prefix(soundLimit))
        }
        favoriteMixIds = preferences.loadFavoriteMixIds()
        favoriteSoundIds = preferences.loadFavoriteSoundIds()
        if favoriteSoundIds.isEmpty, !favoriteIds.isEmpty {
            favoriteSoundIds = favoriteIds.sorted()
        }
    }

    // Connects state publishers to reactive persistence, using debounce where useful.
    func setupPersistence() {
        $sounds
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [preferences] in preferences.saveSounds($0) }
            .store(in: &cancellables)
        $globalVolume
            .dropFirst()
            .sink { [preferences] in preferences.saveGlobalVolume($0) }
            .store(in: &cancellables)
        $presets
            .dropFirst()
            .sink { [preferences] in preferences.savePresets($0) }
            .store(in: &cancellables)
        $recentMixIds
            .dropFirst()
            .sink { [preferences] in preferences.saveRecentMixIds($0) }
            .store(in: &cancellables)
        $recentSoundIds
            .dropFirst()
            .sink { [preferences] in preferences.saveRecentSoundIds($0) }
            .store(in: &cancellables)
        $favoriteMixIds
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [preferences] in preferences.saveFavoriteMixIds($0) }
            .store(in: &cancellables)
        $favoriteSoundIds
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [preferences] in preferences.saveFavoriteSoundIds($0) }
            .store(in: &cancellables)
    }

    func exportedPreferences() -> ExportedPreferences {
        ExportedPreferences(exportDate: ExportedPreferences.exportDateString(), presets: presets,
                            favoriteMixIds: favoriteMixIds, favoriteSoundIds: favoriteSoundIds)
    }

    @discardableResult
    func applyImportedPreferences(_ payload: ExportedPreferences) -> Bool {
        guard payload.version == ExportedPreferences.currentVersion else { return false }
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
        preferences.resetAll()
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
