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
open class SoundStore: ObservableObject {
    @Published public var sounds: [String: SoundStateItem] = [:]
    @Published public var globalVolume: Double = 1.0
    @Published public var isPlaying: Bool = false
    @Published public var playbackError: String?
    /// Saved presets, each containing a combination of sounds.
    @Published public var presets: [Preset] = []
    /// Search text used to filter by sound or category name.
    @Published public var searchQuery = ""
    /// Applied mix ID from Mixes, used to show the localized name. Nil when the selection is manual.
    @Published public var currentMixId: String?
    /// Applied mix icon as an SF Symbol, shown in the playback bar. Nil when the selection is manual.
    @Published public var currentMixIconName: String?
    /// Recently used mix IDs for the sidebar, capped at 10.
    @Published public var recentMixIds: [String] = []
    /// Recently used sound IDs for the sidebar.
    @Published public var recentSoundIds: [String] = []
    /// Favorite mix IDs in user-defined order.
    @Published public var favoriteMixIds: [String] = []
    /// Favorite sound IDs in user-defined order for sidebar drag and drop.
    @Published public var favoriteSoundIds: [String] = []
    /// Active timer used to stop playback.
    @Published public var activeTimer: TimerItem?
    /// Automatic mix-change interval in seconds, or nil when disabled.
    @Published public var autoMixIntervalSeconds: Int?
    /// When true, auto-mix rotates only through the user's custom mixes.
    @Published public var autoMixCustomOnly: Bool = false

    // Internal to support organizing SoundStore behavior across extension files.
    let audioService: AudioService
    var activeTimerToken: Timer?
    var autoMixTimerToken: Timer?
    var timerUsageCounts: [Int: Int] = [:]
    let preferences: PreferencesRepository
    public var onTimerScheduled: ((String, Date) -> Void)?
    public var onTimerCancelled: (() -> Void)?
    public var onTimerFinished: ((String) -> Void)?

    /// Minute presets for the Timer menu: 5m, 10m, 15m, 30m, 45m.
    public static let timerMenuMinutesPresets: [Int] = [5, 10, 15, 30, 45].map { $0 * 60 }
    /// Hour presets for the Timer menu: 1h, 2h, 3h, 4h, 8h.
    public static let timerMenuHoursPresets: [Int] = [1, 2, 3, 4, 8].map { $0 * 3600 }

    public var isMuted: Bool { globalVolume == 0 }
    public var hasActiveTimer: Bool { activeTimer != nil }
    var cancellables = Set<AnyCancellable>()

    public var selectedIds: [String] {
        sounds.filter { $0.value.isSelected }.map(\.key)
    }

    public var favoriteIds: [String] {
        sounds.filter { $0.value.isFavorite }.map(\.key)
    }

    /// Sidebar favorite order: persisted favorites that still exist, followed by any missing favorites.
    public var orderedFavoriteSoundIds: [String] {
        let inOrder = favoriteSoundIds.filter { sounds[$0]?.isFavorite == true }
        let remaining = favoriteIds.filter { !inOrder.contains($0) }
        return inOrder + remaining
    }

    /// Fast preset lookup by ID to avoid repeated linear searches in the UI.
    public var presetsById: [String: Preset] {
        presets.reduce(into: [:]) { result, preset in
            result[preset.id] = preset
        }
    }

    public var hasSelection: Bool {
        sounds.contains { $0.value.isSelected }
    }

    /// Can be saved as a custom mix when there is a selection that does not match a built-in mix.
    public var canSaveCustomMix: Bool {
        hasSelection && displayedMixId == nil
    }

    /// Displayed mix name for menus and UI: the explicit mix or the localized mix matching the current selection.
    public var displayedMixName: String? {
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
    public var displayedMixId: String? {
        if let mixId = currentMixId { return mixId }
        return mixMatchingCurrentSelection()?.id
    }

    /// Displayed mix icon for the playback bar: the applied mix icon or the matching selection's icon.
    public var displayedMixIconName: String? {
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

    public init(audioService: AudioService, preferences: PreferencesRepository = PreferencesRepository()) {
        self.preferences = preferences
        self.timerUsageCounts = preferences.loadTimerUsageCounts()
        self.audioService = audioService
        audioService.onFailure = { [weak self] message in
            self?.playbackError = message
            self?.isPlaying = false
        }
        bootstrapState()
        setupPersistence()
    }
}
