//
//  SoundStore.swift
//  MoodistMac
//

import Combine
import Foundation

extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
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
    /// ID de preset en edición cuando la hoja de Save Mix se reutiliza para renombrar/cambiar icono.
    @Published var editingPresetId: String?
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
    /// Temporizador activo para detener la reproducción.
    @Published var activeTimer: TimerItem?
    /// Intervalo en segundos para cambio automático de mix (nil = desactivado).
    @Published var autoMixIntervalSeconds: Int?
    /// Si true, el auto-mix rota solo entre mixes personalizados del usuario.
    @Published var autoMixCustomOnly: Bool = false

    // Internal para permitir organización por extensiones en múltiples archivos.
    let audioService: AudioService
    var activeTimerToken: Timer?
    var autoMixTimerToken: Timer?
    var timerUsageCounts: [Int: Int] = PersistenceService.loadTimerUsageCounts()

    /// Presets de minutos para el menú Timer (5 opciones): 5m, 10m, 15m, 30m, 45m.
    static let timerMenuMinutesPresets: [Int] = [5, 10, 15, 30, 45].map { $0 * 60 }
    /// Presets de horas para el menú Timer (5 opciones): 1h, 2h, 3h, 4h, 8h.
    static let timerMenuHoursPresets: [Int] = [1, 2, 3, 4, 8].map { $0 * 3600 }

    var isMuted: Bool { globalVolume == 0 }
    var hasActiveTimer: Bool { activeTimer != nil }
    var cancellables = Set<AnyCancellable>()

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

    /// Índice rápido de presets por id para evitar búsquedas lineales repetidas en la UI.
    var presetsById: [String: Preset] {
        presets.reduce(into: [:]) { result, preset in
            result[preset.id] = preset
        }
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
}
