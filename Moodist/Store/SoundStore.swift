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
    /// When true, the main view shows the sheet for saving the current preset, avoiding NSAlert stalls.
    @Published var showSavePresetSheet = false
    /// Preset ID being edited when the Save Mix sheet is reused to rename or change the icon.
    @Published var editingPresetId: String?
    /// Saved presets, each containing a combination of sounds.
    @Published var presets: [Preset] = []
    /// Search text used to filter by sound or category name.
    @Published var searchQuery = ""
    /// When true, the main view should focus the search field, for example after Command-F.
    @Published var requestSearchFocus = false
    /// Applied mix ID from Mixes, used to show the localized name. Nil when the selection is manual.
    @Published var currentMixId: String?
    /// Applied mix icon as an SF Symbol, shown in the playback bar. Nil when the selection is manual.
    @Published var currentMixIconName: String?
    /// Recently used mix IDs for the sidebar, capped at 10.
    @Published var recentMixIds: [String] = []
    /// Recently used sound IDs for the sidebar.
    @Published var recentSoundIds: [String] = []
    /// Favorite mix IDs in user-defined order.
    @Published var favoriteMixIds: [String] = []
    /// Favorite sound IDs in user-defined order for sidebar drag and drop.
    @Published var favoriteSoundIds: [String] = []
    /// Active timer used to stop playback.
    @Published var activeTimer: TimerItem?
    /// Automatic mix-change interval in seconds, or nil when disabled.
    @Published var autoMixIntervalSeconds: Int?
    /// When true, auto-mix rotates only through the user's custom mixes.
    @Published var autoMixCustomOnly: Bool = false

    // Internal to support organizing SoundStore behavior across extension files.
    let audioService: AudioService
    var activeTimerToken: Timer?
    var autoMixTimerToken: Timer?
    var timerUsageCounts: [Int: Int] = PersistenceService.loadTimerUsageCounts()

    /// Minute presets for the Timer menu: 5m, 10m, 15m, 30m, 45m.
    static let timerMenuMinutesPresets: [Int] = [5, 10, 15, 30, 45].map { $0 * 60 }
    /// Hour presets for the Timer menu: 1h, 2h, 3h, 4h, 8h.
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

    /// Sidebar favorite order: persisted favorites that still exist, followed by any missing favorites.
    var orderedFavoriteSoundIds: [String] {
        let inOrder = favoriteSoundIds.filter { sounds[$0]?.isFavorite == true }
        let remaining = favoriteIds.filter { !inOrder.contains($0) }
        return inOrder + remaining
    }

    /// Fast preset lookup by ID to avoid repeated linear searches in the UI.
    var presetsById: [String: Preset] {
        presets.reduce(into: [:]) { result, preset in
            result[preset.id] = preset
        }
    }

    var hasSelection: Bool {
        sounds.contains { $0.value.isSelected }
    }

    /// Can be saved as a custom mix when there is a selection that does not match a built-in mix.
    var canSaveCustomMix: Bool {
        hasSelection && displayedMixId == nil
    }

    /// Displayed mix name for menus and UI: the explicit mix or the localized mix matching the current selection.
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

    /// Displayed mix ID for the UI: the explicit mix or the mix matching the current selection.
    var displayedMixId: String? {
        if let mixId = currentMixId { return mixId }
        return mixMatchingCurrentSelection()?.id
    }

    /// Displayed mix icon for the playback bar: the applied mix icon or the matching selection's icon.
    var displayedMixIconName: String? {
        if let icon = currentMixIconName, !icon.isEmpty { return icon }
        return mixMatchingCurrentSelection()?.iconName
    }

    /// Returns the first MixesData mix whose sound IDs match the current selection.
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
