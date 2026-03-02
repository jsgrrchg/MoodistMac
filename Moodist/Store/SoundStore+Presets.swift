import Foundation

extension SoundStore {
    // MARK: - Presets

    /// Pide mostrar la hoja para guardar el preset actual (SwiftUI sheet; evita NSAlert y bloqueos).
    func promptSaveCurrentPreset() {
        guard canSaveCustomMix else { return }
        editingPresetId = nil
        showSavePresetSheet = true
    }

    /// Aplica un preset: limpia selección, selecciona los sonidos del preset con sus volúmenes y opcionalmente inicia reproducción.
    func applyPreset(_ preset: Preset, startPlaying: Bool = true) {
        // Reinicia selección previa y aplica la nueva configuración de ids + volúmenes.
        unselectAll()
        for soundId in preset.soundIds {
            guard sounds[soundId] != nil else { continue }
            if var item = sounds[soundId] {
                item.isSelected = true
                item.volume = preset.volume(for: soundId)
                sounds[soundId] = item
            }
        }
        for soundId in preset.soundIds.reversed() {
            addToRecentSounds(soundId: soundId)
        }
        if startPlaying { isPlaying = true }
        updatePlaybackForSelection()
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
    func playNextRandomMix() {
        let all = MixesData.categories.flatMap(\.mixes)
        guard !all.isEmpty else { return }
        // Evita repetir el actual si hay alternativas disponibles.
        let currentId = recentMixIds.first
        let others = all.filter { $0.id != currentId }
        let next = others.isEmpty ? all.randomElement()! : others.randomElement()!
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

    func beginEditingPreset(id: String) {
        // Reutiliza la misma sheet de guardado en modo edición.
        guard presets.contains(where: { $0.id == id }) else { return }
        editingPresetId = id
        showSavePresetSheet = true
    }

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

    func closeSavePresetSheet() {
        showSavePresetSheet = false
        editingPresetId = nil
    }

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
