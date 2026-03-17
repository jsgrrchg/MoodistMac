import Foundation

extension SoundStore {
    // MARK: - Presets

    /// Pide mostrar la hoja para guardar el preset actual (SwiftUI sheet; evita NSAlert y bloqueos).
    func promptSaveCurrentPreset() {
        guard canSaveCustomMix else { return }
        editingPresetId = nil
        showSavePresetSheet = true
    }

    /// Aplica un preset con crossfade suave: los sonidos que salen hacen fade-out, los que entran fade-in,
    /// y los comunes transicionan volumen sin recargarse.
    func applyPreset(_ preset: Preset, startPlaying: Bool = true) {
        let fadeDuration = AudioService.crossfadeDuration

        // 1. Clasificar sonidos en tres categorías.
        let oldSelectedIds = Set(selectedIds)
        let newSelectedIds = Set(preset.soundIds.filter { sounds[$0] != nil })

        let fadeOutOnly = oldSelectedIds.subtracting(newSelectedIds)
        let fadeInOnly = newSelectedIds.subtracting(oldSelectedIds)
        let common = oldSelectedIds.intersection(newSelectedIds)

        let shouldPlay = startPlaying || isPlaying

        // 2. Cancelar crossfade previo (rapid switching).
        audioService.cancelCrossfadeAndCleanup()

        // 3. Fade-out: sonidos que salen.
        for soundId in fadeOutOnly {
            audioService.fadeOutAndUnload(soundId: soundId, duration: fadeDuration)
        }

        // 4. Actualizar estado UI en un solo batch.
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

        // 5. Sonidos comunes: transición suave de volumen (sin recargar).
        for soundId in common {
            let targetVolume = preset.volume(for: soundId)
            audioService.setVolume(
                soundId: soundId, volume: targetVolume,
                globalVolume: globalVolume, fadeDuration: fadeDuration
            )
        }

        // 6. Fade-in: cargar nuevos sonidos a volumen 0, luego fade al objetivo.
        for soundId in fadeInOnly {
            guard let sound = SoundsData.allSoundsById[soundId] else { continue }
            if audioService.load(sound: sound) != nil {
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

        // 7. Estado de reproducción y recientes.
        for soundId in preset.soundIds.reversed() {
            addToRecentSounds(soundId: soundId)
        }
        if startPlaying { isPlaying = true }

        // 8. Programar limpieza de outgoing players.
        audioService.scheduleOutgoingCleanup(after: fadeDuration)
    }

    /// Aplica un mix temático y guarda su id e icono para mostrarlos en la UI.
    func applyMix(_ mix: Mix) {
        applyPreset(mix.toPreset())
        // Guarda metadatos del mix aplicado para encabezados/toolbar.
        currentMixId = mix.id
        currentMixIconName = mix.iconName
        addToRecentMixes(mixId: mix.id)
    }

    /// Aplica un mix aleatorio (otro distinto al actual si hay varios).
    /// Cuando `autoMixCustomOnly` es true, rota solo entre presets del usuario.
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

    /// Guarda la selección actual como un nuevo preset.
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
    // Inicia edición de un preset existente: carga su id para que la hoja de guardado sepa que es edición, no creación.
    func beginEditingPreset(id: String) {
        // Reutiliza la misma sheet de guardado en modo edición.
        guard presets.contains(where: { $0.id == id }) else { return }
        editingPresetId = id
        showSavePresetSheet = true
    }
    // Actualiza el preset editado con nuevos valores. Si se editó el preset actualmente aplicado como mix, actualiza su icono en la UI.
    func updatePresetMetadata(id: String, name: String, iconName: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        guard let index = presets.firstIndex(where: { $0.id == id }) else { return }
        presets[index].name = trimmedName
        presets[index].iconName = iconName
        // Si se edita el preset actualmente mostrado como mix, refresca su icono en UI.
        if currentMixId == id {
            currentMixIconName = iconName
        }
    }
    // Cierra la hoja de guardado sin guardar cambios y limpia el estado de edición.
    func closeSavePresetSheet() {
        showSavePresetSheet = false
        editingPresetId = nil
    }
    // Elimina un preset y limpia cualquier referencia a él en favoritos, recientes y selección actual.
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
    // Agrega un sonido a un preset existente, asegurando que el sonido exista, no se duplique en el preset y que tenga un volumen asignado.
    func addSound(_ soundId: String, toPreset presetId: String) {
        guard sounds[soundId] != nil else { return }
        guard let index = presets.firstIndex(where: { $0.id == presetId }) else { return }
        var preset = presets[index]
        // Añade id sin duplicar y rellena volumen faltante usando el valor actual del sonido.
        if !preset.soundIds.contains(soundId) {
            preset.soundIds.append(soundId)
        }
        if preset.volumes[soundId] == nil, let item = sounds[soundId] {
            preset.volumes[soundId] = item.volume
        }
        presets[index] = preset
    }

    /// Prepara la selección con solo este sonido y muestra la hoja para guardar como nuevo preset (mix personalizado).
    func createNewPresetWithSound(_ soundId: String) {
        guard sounds[soundId] != nil else { return }
        unselectAll()
        select(soundId)
        editingPresetId = nil
        showSavePresetSheet = true
    }
}
