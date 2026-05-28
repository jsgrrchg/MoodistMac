import Foundation

extension SoundStore {
    // MARK: - Presets

    /// Requests the sheet for saving the current preset, avoiding NSAlert stalls.
    func promptSaveCurrentPreset() {
        guard canSaveCustomMix else { return }
        editingPresetId = nil
        showSavePresetSheet = true
    }

    /// Applies a preset with a smooth crossfade: removed sounds fade out, new sounds fade in,
    /// and shared sounds transition volume without reloading.
    func applyPreset(_ preset: Preset, startPlaying: Bool = true) {
        let fadeDuration = AudioService.crossfadeDuration

        // 1. Split sounds into three categories.
        let oldSelectedIds = Set(selectedIds)
        let newSelectedIds = Set(preset.soundIds.filter { sounds[$0] != nil })

        let fadeOutOnly = oldSelectedIds.subtracting(newSelectedIds)
        let fadeInOnly = newSelectedIds.subtracting(oldSelectedIds)
        let common = oldSelectedIds.intersection(newSelectedIds)

        let shouldPlay = startPlaying || isPlaying

        // 2. Cancel any previous crossfade for rapid switching.
        audioService.cancelCrossfadeAndCleanup()

        // 3. Fade out removed sounds.
        for soundId in fadeOutOnly {
            audioService.fadeOutAndUnload(soundId: soundId, duration: fadeDuration)
        }

        // 4. Update UI state in a single batch.
        var next = sounds
        for id in fadeOutOnly {
            if var item = next[id] {
                item.isSelected = false
                next[id] = item
            }
        }
        for soundId in newSelectedIds {
            if var item = next[soundId] {
                item.isSelected = true
                item.volume = preset.volume(for: soundId)
                next[soundId] = item
            }
        }
        sounds = next
        currentMixId = nil
        currentMixIconName = nil

        // 5. Shared sounds: smoothly transition volume without reloading.
        for soundId in common {
            let targetVolume = preset.volume(for: soundId)
            audioService.setVolume(
                soundId: soundId, volume: targetVolume,
                globalVolume: globalVolume, fadeDuration: fadeDuration
            )
        }

        // 6. Fade in new sounds from volume 0 to the target volume.
        for soundId in fadeInOnly {
            guard let sound = SoundsData.allSoundsById[soundId] else { continue }
            if audioService.load(sound: sound) {
                audioService.setVolume(soundId: soundId, volume: 0, globalVolume: 1.0)
                if shouldPlay {
                    audioService.play(soundId: soundId)
                }
                let targetVolume = preset.volume(for: soundId)
                audioService.setVolume(
                    soundId: soundId, volume: targetVolume,
                    globalVolume: globalVolume, fadeDuration: fadeDuration
                )
            }
        }

        // 7. Playback state and recents.
        for soundId in preset.soundIds.reversed() {
            addToRecentSounds(soundId: soundId)
        }
        if startPlaying { isPlaying = true }

        // 8. Schedule cleanup for outgoing players.
        audioService.scheduleOutgoingCleanup(after: fadeDuration)
    }

    /// Applies a thematic mix and stores its ID and icon for display in the UI.
    func applyMix(_ mix: Mix) {
        applyPreset(mix.toPreset())
        // Store applied mix metadata for headers and toolbar state.
        currentMixId = mix.id
        currentMixIconName = mix.iconName
        addToRecentMixes(mixId: mix.id)
    }

    /// Applies a random mix, choosing a different one when multiple options exist.
    /// When `autoMixCustomOnly` is true, rotates only through the user's presets.
    func playNextRandomMix() {
        let pool: [Mix] =
            autoMixCustomOnly
            ? presets.map { $0.toMix() }
            : MixesData.categories.flatMap(\.mixes)
        guard !pool.isEmpty else { return }
        let currentId = recentMixIds.first
        let others = pool.filter { $0.id != currentId }
        let next = others.isEmpty ? pool.randomElement()! : others.randomElement()!
        applyMix(next)
    }

    /// Saves the current selection as a new preset.
    func saveCurrentAsPreset(name: String, iconName: String = "sparkles") {
        let ids = selectedIds
        guard !ids.isEmpty, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        var volumes: [String: Double] = [:]
        for id in ids {
            if let item = sounds[id] {
                volumes[id] = item.volume
            }
        }
        let preset = Preset(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName,
            soundIds: ids,
            volumes: volumes
        )
        presets.append(preset)
    }
    // Starts editing an existing preset so the save sheet knows this is an edit, not a new preset.
    func beginEditingPreset(id: String) {
        // Reuse the same save sheet in edit mode.
        guard presets.contains(where: { $0.id == id }) else { return }
        editingPresetId = id
        showSavePresetSheet = true
    }
    // Updates the edited preset metadata and refreshes the displayed icon when it is the active mix.
    func updatePresetMetadata(id: String, name: String, iconName: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = presets.firstIndex(where: { $0.id == id }) else { return }
        presets[index].name = trimmedName
        presets[index].iconName = iconName
        // Refresh the UI icon if the currently displayed mix was edited.
        if currentMixId == id {
            currentMixIconName = iconName
        }
    }
    // Closes the save sheet without saving and clears edit state.
    func closeSavePresetSheet() {
        showSavePresetSheet = false
        editingPresetId = nil
    }
    // Deletes a preset and clears references from favorites, recents, and current selection.
    func deletePreset(id: String) {
        presets.removeAll { $0.id == id }
        favoriteMixIds.removeAll { $0 == id }
        recentMixIds.removeAll { $0 == id }
        if currentMixId == id {
            currentMixId = nil
            currentMixIconName = nil
        }
        if editingPresetId == id {
            editingPresetId = nil
        }
    }
    // Adds an existing sound to a preset without duplicates and with an assigned volume.
    func addSound(_ soundId: String, toPreset presetId: String) {
        guard sounds[soundId] != nil else { return }
        guard let index = presets.firstIndex(where: { $0.id == presetId }) else { return }
        var preset = presets[index]
        // Add the ID once and fill any missing volume from the current sound state.
        if !preset.soundIds.contains(soundId) {
            preset.soundIds.append(soundId)
        }
        if preset.volumes[soundId] == nil, let item = sounds[soundId] {
            preset.volumes[soundId] = item.volume
        }
        presets[index] = preset
    }

    /// Selects only this sound and shows the sheet for saving it as a new custom mix.
    func createNewPresetWithSound(_ soundId: String) {
        guard sounds[soundId] != nil else { return }
        unselectAll()
        select(soundId)
        editingPresetId = nil
        showSavePresetSheet = true
    }
}
