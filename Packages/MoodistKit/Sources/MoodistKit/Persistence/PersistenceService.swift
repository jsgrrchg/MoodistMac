import Foundation

public enum PersistenceService {
    public static let soundsKey = "moodist.sounds"
    public static let globalVolumeKey = "moodist.globalVolume"
    public static let presetsKey = "moodist.presets"
    public static let recentMixIdsKey = "moodist.recentMixIds"
    public static let recentSoundIdsKey = "moodist.recentSoundIds"
    public static let favoriteMixIdsKey = "moodist.favoriteMixIds"
    public static let favoriteSoundIdsKey = "moodist.favoriteSoundIds"
    public static let maxRecentMixesCountKey = "MoodistMac.maxRecentMixesCount"
    public static let maxRecentSoundsCountKey = "MoodistMac.maxRecentSoundsCount"
    public static let menuBarEnabledKey = "MoodistMac.menuBarEnabled"
    public static let accentColorHexKey = "MoodistMac.accentColorHex"
    public static let appearanceModeKey = "MoodistMac.appearanceMode"
    public static let transparencyEnabledKey = "MoodistMac.transparencyEnabled"
    public static let mediaKeyNextMixKey = "MoodistMac.mediaKeyNextMix"
    public static let collapseCategoriesOnColdOpenKey = "MoodistMac.collapseCategoriesOnColdOpen"
    public static let appLanguageKey = "MoodistMac.appLanguage"
    public static let appKitMainWindowFrameKey = "NSWindow Frame MoodistMainWindow"
    public static let sidebarSectionsCollapsedKey = "MoodistMac.sidebarSectionsCollapsed"
    public static let timerUsageCountsKey = "MoodistMac.timerUsageCounts"
    public static let scrollAnchorIdsKey = "MoodistMac.scrollAnchorIds"
    public static func loadSounds() -> [String: SoundStateItem]? { PreferencesRepository().loadSounds() }
    public static func saveSounds(_ state: [String: SoundStateItem]) { PreferencesRepository().saveSounds(state) }
    public static func loadGlobalVolume() -> Double? { PreferencesRepository().loadGlobalVolume() }
    public static func saveGlobalVolume(_ volume: Double) { PreferencesRepository().saveGlobalVolume(volume) }
    public static func loadPresets() -> [Preset] { PreferencesRepository().loadPresets() }
    public static func savePresets(_ presets: [Preset]) { PreferencesRepository().savePresets(presets) }
    public static func loadRecentMixIds() -> [String] { PreferencesRepository().loadRecentMixIds() }
    public static func saveRecentMixIds(_ ids: [String]) { PreferencesRepository().saveRecentMixIds(ids) }
    public static func loadRecentSoundIds() -> [String] { PreferencesRepository().loadRecentSoundIds() }
    public static func saveRecentSoundIds(_ ids: [String]) { PreferencesRepository().saveRecentSoundIds(ids) }
    public static func loadFavoriteMixIds() -> [String] { PreferencesRepository().loadFavoriteMixIds() }
    public static func saveFavoriteMixIds(_ ids: [String]) { PreferencesRepository().saveFavoriteMixIds(ids) }
    public static func loadFavoriteSoundIds() -> [String] { PreferencesRepository().loadFavoriteSoundIds() }
    public static func saveFavoriteSoundIds(_ ids: [String]) { PreferencesRepository().saveFavoriteSoundIds(ids) }
    public static func loadMaxRecentMixesCount() -> Int { PreferencesRepository().loadMaxRecentMixesCount() }
    public static func loadMaxRecentSoundsCount() -> Int { PreferencesRepository().loadMaxRecentSoundsCount() }
    public static func loadTransparencyEnabled() -> Bool { PreferencesRepository().loadTransparencyEnabled() }
    public static func saveTransparencyEnabled(_ enabled: Bool) { PreferencesRepository().saveTransparencyEnabled(enabled) }
    public static func loadMediaKeyNextMix() -> Bool { PreferencesRepository().loadMediaKeyNextMix() }
    public static func loadSidebarSectionsCollapsed() -> [String: Bool] { PreferencesRepository().loadSidebarSectionsCollapsed() }
    public static func saveSidebarSectionsCollapsed(_ value: [String: Bool]) { PreferencesRepository().saveSidebarSectionsCollapsed(value) }
    public static func loadTimerUsageCounts() -> [Int: Int] { PreferencesRepository().loadTimerUsageCounts() }
    public static func saveTimerUsageCounts(_ counts: [Int: Int]) { PreferencesRepository().saveTimerUsageCounts(counts) }
    public static func loadScrollAnchorIds() -> [String: String] { PreferencesRepository().loadScrollAnchorIds() }
    public static func saveScrollAnchorIds(_ value: [String: String]) { PreferencesRepository().saveScrollAnchorIds(value) }
    public static func resetAll() { PreferencesRepository().resetAll() }
}

public struct PreferencesRepository {
    public let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    public func loadSounds() -> [String: SoundStateItem]? {
        guard let data = defaults.data(forKey: PersistenceService.soundsKey) else { return nil }
        return try? JSONDecoder().decode([String: SoundStateItem].self, from: data)
    }

    public func saveSounds(_ state: [String: SoundStateItem]) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: PersistenceService.soundsKey)
    }

    public func loadGlobalVolume() -> Double? {
        guard defaults.object(forKey: PersistenceService.globalVolumeKey) != nil else { return nil }
        return max(0, min(1, defaults.double(forKey: PersistenceService.globalVolumeKey)))
    }

    public func saveGlobalVolume(_ volume: Double) {
        defaults.set(volume, forKey: PersistenceService.globalVolumeKey)
    }

    public func loadPresets() -> [Preset] {
        guard let data = defaults.data(forKey: PersistenceService.presetsKey) else { return [] }
        let decoder = JSONDecoder()
        if let presets = try? decoder.decode([Preset].self, from: data) {
            return presets
        }

        // Tolerant fallback: recover valid elements when legacy or corrupt entries
        // prevent the full array from decoding.
        guard let rawArray = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [Any]
        else {
            NSLog("MoodistMac: failed to decode presets payload.")
            return []
        }

        var recovered: [Preset] = []
        recovered.reserveCapacity(rawArray.count)
        for raw in rawArray {
            guard JSONSerialization.isValidJSONObject(raw),
                let itemData = try? JSONSerialization.data(withJSONObject: raw, options: []),
                let preset = try? decoder.decode(Preset.self, from: itemData)
            else {
                continue
            }
            recovered.append(preset)
        }

        if !recovered.isEmpty {
            NSLog(
                "MoodistMac: recovered \(recovered.count)/\(rawArray.count) presets from partially invalid payload."
            )
        } else {
            NSLog("MoodistMac: failed to decode presets payload.")
        }
        return recovered
    }
    // Saves presets as encoded JSON. If encoding fails, keep existing data untouched.
    public func savePresets(_ presets: [Preset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        defaults.set(data, forKey: PersistenceService.presetsKey)
    }
    // Loads recent and favorite ID arrays from JSON, returning an empty array if decoding fails.
    public func loadRecentMixIds() -> [String] {
        guard let data = defaults.data(forKey: PersistenceService.recentMixIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    public func saveRecentMixIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: PersistenceService.recentMixIdsKey)
    }

    public func loadRecentSoundIds() -> [String] {
        guard let data = defaults.data(forKey: PersistenceService.recentSoundIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    public func saveRecentSoundIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: PersistenceService.recentSoundIdsKey)
    }

    public func loadFavoriteMixIds() -> [String] {
        guard let data = defaults.data(forKey: PersistenceService.favoriteMixIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    public func saveFavoriteMixIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: PersistenceService.favoriteMixIdsKey)
    }

    public func loadFavoriteSoundIds() -> [String] {
        guard let data = defaults.data(forKey: PersistenceService.favoriteSoundIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    public func saveFavoriteSoundIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: PersistenceService.favoriteSoundIdsKey)
    }

    /// Maximum recent mixes in the sidebar (5...15). Defaults to 10.
    public func loadMaxRecentMixesCount() -> Int {
        let v = defaults.object(forKey: PersistenceService.maxRecentMixesCountKey) as? Int ?? 10
        return min(15, max(5, v))
    }

    /// Maximum recent sounds in the sidebar (5...15). Defaults to 12.
    public func loadMaxRecentSoundsCount() -> Int {
        let v = defaults.object(forKey: PersistenceService.maxRecentSoundsCountKey) as? Int ?? 12
        return min(15, max(5, v))
    }

    public func loadTransparencyEnabled() -> Bool {
        guard defaults.object(forKey: PersistenceService.transparencyEnabledKey) != nil else {
            return true
        }
        return defaults.bool(forKey: PersistenceService.transparencyEnabledKey)
    }

    public func saveTransparencyEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: PersistenceService.transparencyEnabledKey)
    }

    /// When true, the "Next" media key advances to the next mix. Defaults to true.
    public func loadMediaKeyNextMix() -> Bool {
        guard defaults.object(forKey: PersistenceService.mediaKeyNextMixKey) != nil else { return true }
        return defaults.bool(forKey: PersistenceService.mediaKeyNextMixKey)
    }

    /// Collapsed sidebar section state (ID -> true = collapsed). Defaults to all expanded.
    public func loadSidebarSectionsCollapsed() -> [String: Bool] {
        guard let data = defaults.data(forKey: PersistenceService.sidebarSectionsCollapsedKey),
            let dict = try? JSONDecoder().decode([String: Bool].self, from: data)
        else { return [:] }
        return dict
    }

    public func saveSidebarSectionsCollapsed(_ value: [String: Bool]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: PersistenceService.sidebarSectionsCollapsedKey)
    }

    /// Timer usage counts keyed by duration in seconds.
    public func loadTimerUsageCounts() -> [Int: Int] {
        guard
            let dict = defaults.dictionary(forKey: PersistenceService.timerUsageCountsKey)
                as? [String: Int]
        else {
            return [:]
        }
        var result: [Int: Int] = [:]
        for (key, value) in dict {
            if let seconds = Int(key) {
                result[seconds] = value
            }
        }
        return result
    }

    public func saveTimerUsageCounts(_ counts: [Int: Int]) {
        let dict = Dictionary(uniqueKeysWithValues: counts.map { (String($0.key), $0.value) })
        defaults.set(dict, forKey: PersistenceService.timerUsageCountsKey)
    }

    /// Scroll anchors per panel, used to restore position when switching tabs or reopening the app.
    public func loadScrollAnchorIds() -> [String: String] {
        guard let data = defaults.data(forKey: PersistenceService.scrollAnchorIdsKey),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }

    public func saveScrollAnchorIds(_ value: [String: String]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: PersistenceService.scrollAnchorIdsKey)
    }

    /// Removes all keys used by the app, including sounds, volume, presets, and appearance.
    public func resetAll() {
        defaults.removeObject(forKey: PersistenceService.soundsKey)
        defaults.removeObject(forKey: PersistenceService.globalVolumeKey)
        defaults.removeObject(forKey: PersistenceService.presetsKey)
        defaults.removeObject(forKey: PersistenceService.recentMixIdsKey)
        defaults.removeObject(forKey: PersistenceService.recentSoundIdsKey)
        defaults.removeObject(forKey: PersistenceService.favoriteMixIdsKey)
        defaults.removeObject(forKey: PersistenceService.favoriteSoundIdsKey)
        defaults.removeObject(forKey: PersistenceService.maxRecentMixesCountKey)
        defaults.removeObject(forKey: PersistenceService.maxRecentSoundsCountKey)
        defaults.removeObject(forKey: PersistenceService.menuBarEnabledKey)
        defaults.removeObject(forKey: PersistenceService.accentColorHexKey)
        defaults.removeObject(forKey: PersistenceService.appearanceModeKey)
        defaults.removeObject(forKey: PersistenceService.transparencyEnabledKey)
        defaults.removeObject(forKey: PersistenceService.mediaKeyNextMixKey)
        defaults.removeObject(forKey: PersistenceService.collapseCategoriesOnColdOpenKey)
        defaults.removeObject(forKey: PersistenceService.appLanguageKey)
        defaults.removeObject(forKey: "AppleLanguages")
        defaults.removeObject(forKey: PersistenceService.scrollAnchorIdsKey)
        defaults.removeObject(forKey: PersistenceService.appKitMainWindowFrameKey)
        defaults.removeObject(forKey: PersistenceService.sidebarSectionsCollapsedKey)
        defaults.removeObject(forKey: PersistenceService.timerUsageCountsKey)
    }
}
