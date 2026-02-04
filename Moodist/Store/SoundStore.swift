//
//  SoundStore.swift
//  MoodistMac
//

import Foundation
import Combine
#if canImport(AppKit)
import AppKit
#endif

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

@MainActor
final class SoundStore: ObservableObject {
    @Published var sounds: [String: SoundStateItem] = [:]
    @Published var globalVolume: Double = 1.0
    @Published var isPlaying: Bool = false
    @Published var showOptionsPanel = false
    /// Si true, la vista principal muestra la hoja para guardar el preset actual (evita NSAlert y bloqueos).
    @Published var showSavePresetSheet = false
    /// Presets guardados (combinaciones de sonidos).
    @Published var presets: [Preset] = []
    /// Texto de búsqueda: filtra por nombre de sonido o categoría.
    @Published var searchQuery = ""
    /// Si true, la vista principal debe enfocar el campo de búsqueda (p. ej. ⌘F).
    @Published var requestSearchFocus = false
    /// ID del mix aplicado (desde Mixes); se usa para mostrar el nombre localizado. nil si la selección es manual.
    @Published var currentMixId: String?
    /// Icono del mix aplicado (SF Symbol); se muestra en la barra de reproducción. nil si la selección es manual.
    @Published var currentMixIconName: String?
    /// IDs de mixes usados recientemente (máx. 10), para la barra lateral.
    @Published var recentMixIds: [String] = []
    /// IDs de sonidos usados recientemente, para la barra lateral.
    @Published var recentSoundIds: [String] = []
    /// IDs de mixes marcados como favoritos (orden definido por el usuario).
    @Published var favoriteMixIds: [String] = []
    /// IDs de sonidos favoritos en el orden elegido por el usuario (para drag and drop en la barra lateral).
    @Published var favoriteSoundIds: [String] = []
    /// Solicitud desde la UI para cambiar de sección principal ("sounds" o "mixes").
    @Published var requestedMainSection: String?
    /// Temporizador activo para detener la reproducción.
    @Published private(set) var activeTimer: TimerItem?

    private let audioService: AudioService
    /// Volumen guardado antes de mutear; se restaura al desmutear.
    private var volumeBeforeMute: Double = 1.0
    private var activeTimerToken: Timer?
    private var timerUsageCounts: [Int: Int] = PersistenceService.loadTimerUsageCounts()
    private let defaultTimerPresetsSeconds: [Int] = [5, 10, 15, 20, 30, 60, 120, 480].map { $0 * 60 }

    /// Presets de minutos para el menú Timer (5 opciones): 5m, 10m, 15m, 30m, 45m.
    static let timerMenuMinutesPresets: [Int] = [5, 10, 15, 30, 45].map { $0 * 60 }
    /// Presets de horas para el menú Timer (5 opciones): 1h, 2h, 3h, 4h, 8h.
    static let timerMenuHoursPresets: [Int] = [1, 2, 3, 4, 8].map { $0 * 3600 }

    var isMuted: Bool { globalVolume == 0 }
    var hasActiveTimer: Bool { activeTimer != nil }
    private var cancellables = Set<AnyCancellable>()

    var selectedIds: [String] {
        sounds.filter { $0.value.isSelected }.map(\.key)
    }

    var favoriteIds: [String] {
        sounds.filter { $0.value.isFavorite }.map(\.key)
    }

    /// Orden de favoritos para la barra lateral: favoriteSoundIds que sigan siendo favoritos + los que falten.
    var orderedFavoriteSoundIds: [String] {
        let inOrder = favoriteSoundIds.filter { sounds[$0]?.isFavorite == true }
        let remaining = favoriteIds.filter { !inOrder.contains($0) }
        return inOrder + remaining
    }

    var hasSelection: Bool {
        sounds.contains { $0.value.isSelected }
    }

    /// Puede guardarse como mix personalizado cuando hay selección y no coincide con un mix predeterminado.
    var canSaveCustomMix: Bool {
        hasSelection && displayedMixId == nil
    }

    /// Nombre del mix a mostrar en menú/UI: el aplicado explícitamente o uno que coincida con la selección actual (localizado).
    var displayedMixName: String? {
        if let mixId = currentMixId {
            if let preset = presets.first(where: { $0.id == mixId }) {
                return preset.name
            }
            return L10n.mixName(mixId)
        }
        if let mixId = mixMatchingCurrentSelection()?.id {
            return L10n.mixName(mixId)
        }
        return nil
    }

    /// ID del mix a mostrar en UI: el aplicado explícitamente o uno que coincida con la selección actual.
    var displayedMixId: String? {
        if let mixId = currentMixId { return mixId }
        return mixMatchingCurrentSelection()?.id
    }

    /// Icono del mix a mostrar en la barra de reproducción: el del mix aplicado o el del mix que coincida con la selección.
    var displayedMixIconName: String? {
        if let icon = currentMixIconName, !icon.isEmpty { return icon }
        return mixMatchingCurrentSelection()?.iconName
    }

    /// Devuelve el primer mix en MixesData que coincida con los sonidos seleccionados (mismos IDs).
    private func mixMatchingCurrentSelection() -> Mix? {
        let ids = selectedIds.sorted()
        guard !ids.isEmpty else { return nil }
        for mix in MixesData.categories.flatMap(\.mixes) {
            if mix.soundIds.sorted() == ids { return mix }
        }
        return nil
    }

    init(audioService: AudioService) {
        self.audioService = audioService
        bootstrapState()
        setupPersistence()
    }

    private func bootstrapState() {
        SoundsData.categories.flatMap(\.sounds).forEach { sounds[$0.id] = .default }
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

    private func setupPersistence() {
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

    func select(_ id: String) {
        currentMixId = nil
        currentMixIconName = nil
        guard var item = sounds[id] else { return }
        item.isSelected = true
        sounds[id] = item
        addToRecentSounds(soundId: id)
        if let sound = SoundsData.categories.flatMap(\.sounds).first(where: { $0.id == id }) {
            _ = audioService.load(sound: sound)
            audioService.setVolume(soundId: id, volume: item.volume, globalVolume: globalVolume)
            // Iniciar reproducción inmediata al seleccionar (p. ej. primer elemento).
            isPlaying = true
            audioService.playAll(ids: selectedIds)
        }
    }

    func unselect(_ id: String) {
        currentMixId = nil
        currentMixIconName = nil
        guard var item = sounds[id] else { return }
        item.isSelected = false
        sounds[id] = item
        audioService.pause(soundId: id)
    }

    func unselectAll() {
        currentMixId = nil
        currentMixIconName = nil
        guard hasSelection else { return }
        isPlaying = false
        audioService.pauseAll(ids: selectedIds)
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

    func setVolume(_ id: String, _ volume: Double) {
        guard var item = sounds[id] else { return }
        item.volume = volume
        sounds[id] = item
        audioService.setVolume(soundId: id, volume: volume, globalVolume: globalVolume)
    }

    func setGlobalVolume(_ volume: Double) {
        globalVolume = volume
        if volume > 0 { volumeBeforeMute = volume }
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
    }

    /// Alterna mute: si hay sonido lo silencia; si está silenciado restaura el volumen anterior.
    func toggleMute() {
        if globalVolume == 0 {
            globalVolume = volumeBeforeMute > 0 ? volumeBeforeMute : 1.0
        } else {
            volumeBeforeMute = globalVolume
            globalVolume = 0
        }
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
    }

    func stopPlayback() {
        guard isPlaying else { return }
        isPlaying = false
        audioService.pauseAll(ids: selectedIds)
    }

    func toggleFavorite(_ id: String) {
        guard var item = sounds[id] else { return }
        item.isFavorite.toggle()
        sounds[id] = item
        if item.isFavorite {
            if !favoriteSoundIds.contains(id) { favoriteSoundIds.append(id) }
        } else {
            favoriteSoundIds.removeAll { $0 == id }
        }
    }

    // MARK: - Timers (Sleep)

    func startSleepTimer(durationSeconds: Int, name: String? = nil) {
        let safeDuration = max(1, durationSeconds)
        cancelSleepTimer()
        let displayName = name ?? timerLabel(forSeconds: safeDuration)
        let endDate = Date().addingTimeInterval(TimeInterval(safeDuration))
        activeTimer = TimerItem(name: displayName, durationSeconds: safeDuration, state: .running(endDate: endDate))
        timerUsageCounts[safeDuration, default: 0] += 1
        PersistenceService.saveTimerUsageCounts(timerUsageCounts)
        TimerNotificationManager.shared.requestAuthorizationIfNeeded()
        activeTimerToken = Timer.scheduledTimer(withTimeInterval: TimeInterval(safeDuration), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.completeSleepTimer()
            }
        }
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }

    func cancelSleepTimer() {
        activeTimerToken?.invalidate()
        activeTimerToken = nil
        activeTimer = nil
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }

    #if canImport(AppKit)
    func promptCustomTimer() {
        let alert = NSAlert()
        alert.messageText = L10n.timerCustomTitle
        alert.informativeText = L10n.timerCustomMessage
        let input = NSTextField(string: "")
        input.placeholderString = L10n.timerMinutesPlaceholder
        input.frame = NSRect(x: 0, y: 0, width: 180, height: 24)
        alert.accessoryView = input
        alert.addButton(withTitle: L10n.timerStart)
        alert.addButton(withTitle: L10n.cancel)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }
        let raw = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(raw), minutes > 0 else { return }
        startSleepTimer(durationSeconds: minutes * 60)
    }

    /// Pide mostrar la hoja para guardar el preset actual (SwiftUI sheet; evita NSAlert y bloqueos).
    func promptSaveCurrentPreset() {
        guard canSaveCustomMix else { return }
        showSavePresetSheet = true
    }
    #endif

    var timerRemainingMenuTitle: String? {
        guard let activeTimer else { return nil }
        let remaining = activeTimer.remainingSeconds
        return L10n.timerRemaining(timerRemainingString(seconds: remaining))
    }

    func topTimerPresets(limit: Int) -> [Int] {
        var ordered = timerUsageCounts.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value > rhs.value
        }.map { $0.key }
        for preset in defaultTimerPresetsSeconds where !ordered.contains(preset) {
            ordered.append(preset)
        }
        return Array(ordered.prefix(limit))
    }

    func timerLabel(forSeconds seconds: Int) -> String {
        timerPresetString(seconds: seconds)
    }

    private func timerPresetString(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    private func timerRemainingString(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else if seconds >= 60 {
            formatter.allowedUnits = [.minute, .second]
            formatter.zeroFormattingBehavior = .pad
        } else {
            formatter.allowedUnits = [.second]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    private func completeSleepTimer() {
        activeTimerToken?.invalidate()
        activeTimerToken = nil
        let timerName = activeTimer?.name ?? L10n.timer
        activeTimer = nil
        stopPlayback()
        TimerNotificationManager.shared.scheduleFinishedNotification(name: timerName)
        NotificationCenter.default.post(name: .timerStateDidChange, object: nil)
    }

    /// Reordena los sonidos favoritos (drag and drop en la barra lateral).
    func moveFavoriteSounds(fromOffsets: IndexSet, toOffset: Int) {
        var ordered = orderedFavoriteSoundIds
        ordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        favoriteSoundIds = ordered
    }

    /// Reordena los mixes favoritos (drag and drop en la barra lateral).
    func moveFavoriteMixes(fromOffsets: IndexSet, toOffset: Int) {
        favoriteMixIds.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    /// Añade o quita un mix de favoritos por su id.
    func toggleFavoriteMix(id: String) {
        if favoriteMixIds.contains(id) {
            favoriteMixIds.removeAll { $0 == id }
        } else {
            favoriteMixIds.append(id)
        }
    }

    func togglePlay() {
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
            audioService.pauseAll(ids: selectedIds)
        }
    }

    func shuffle() {
        let allIds = Array(sounds.keys)
        guard allIds.count >= 4 else { return }
        unselectAll()
        let picked = allIds.shuffled().prefix(4)
        for id in picked {
            if var item = sounds[id] {
                item.isSelected = true
                item.volume = Double.random(in: 0.2...1.0)
                sounds[id] = item
            }
        }
        isPlaying = true
        updatePlaybackForSelection()
    }

    private func updatePlaybackForSelection() {
        for sound in SoundsData.categories.flatMap(\.sounds) {
            if sounds[sound.id]?.isSelected == true {
                _ = audioService.load(sound: sound)
            }
        }
        audioService.updateVolumes(state: sounds, globalVolume: globalVolume)
        if isPlaying { audioService.playAll(ids: selectedIds) }
    }

    func resetSelectionAndFavorites() {
        currentMixId = nil
        currentMixIconName = nil
        isPlaying = false
        audioService.pauseAll(ids: selectedIds)
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
    }

    // MARK: - Presets

    /// Aplica un preset: limpia selección, selecciona los sonidos del preset con sus volúmenes y opcionalmente inicia reproducción.
    func applyPreset(_ preset: Preset, startPlaying: Bool = true) {
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
        currentMixId = mix.id
        currentMixIconName = mix.iconName
        addToRecentMixes(mixId: mix.id)
    }

    /// Aplica un mix aleatorio (otro distinto al actual si hay varios).
    func playNextRandomMix() {
        let all = MixesData.categories.flatMap(\.mixes)
        guard !all.isEmpty else { return }
        let currentId = recentMixIds.first
        let others = all.filter { $0.id != currentId }
        let next = others.isEmpty ? all.randomElement()! : others.randomElement()!
        applyMix(next)
    }

    private func addToRecentMixes(mixId: String) {
        var ids = recentMixIds
        ids.removeAll { $0 == mixId }
        ids.insert(mixId, at: 0)
        let limit = PersistenceService.loadMaxRecentMixesCount()
        recentMixIds = Array(ids.prefix(limit))
    }

    private func addToRecentSounds(soundId: String) {
        var ids = recentSoundIds
        ids.removeAll { $0 == soundId }
        ids.insert(soundId, at: 0)
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        recentSoundIds = Array(ids.prefix(limit))
    }

    /// Recorta la lista de mixes recientes al límite configurado en Opciones (p. ej. al reducir el máximo).
    func trimRecentMixIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentMixesCount()
        if recentMixIds.count > limit {
            recentMixIds = Array(recentMixIds.prefix(limit))
        }
    }

    /// Recorta la lista de sonidos recientes al límite configurado en Opciones.
    func trimRecentSoundIdsToLimit() {
        let limit = PersistenceService.loadMaxRecentSoundsCount()
        if recentSoundIds.count > limit {
            recentSoundIds = Array(recentSoundIds.prefix(limit))
        }
    }

    /// Guarda la selección actual como un nuevo preset.
    func saveCurrentAsPreset(name: String, iconName: String = "sparkles") {
        let ids = selectedIds
        guard !ids.isEmpty, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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

    func deletePreset(id: String) {
        presets.removeAll { $0.id == id }
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
        presets = payload.presets
        favoriteMixIds = payload.favoriteMixIds
        favoriteSoundIds = payload.favoriteSoundIds
        return true
    }

    func addSound(_ soundId: String, toPreset presetId: String) {
        guard sounds[soundId] != nil else { return }
        guard let index = presets.firstIndex(where: { $0.id == presetId }) else { return }
        var preset = presets[index]
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
        showSavePresetSheet = true
    }

    func resetAllToDefaults() {
        cancelSleepTimer()
        currentMixId = nil
        currentMixIconName = nil
        isPlaying = false
        audioService.pauseAll(ids: selectedIds)
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
}

extension SoundStore {
    static let mainSectionSounds = "sounds"
    static let mainSectionMixes = "mixes"

    func requestMainSection(_ section: String) {
        requestedMainSection = section
    }
}
