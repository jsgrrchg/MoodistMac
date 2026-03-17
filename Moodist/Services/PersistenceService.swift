//
//  PersistenceService.swift
//  MoodistMac
//

import Foundation

enum PersistenceService {
    private static let soundsKey = "moodist.sounds"
    private static let globalVolumeKey = "moodist.globalVolume"
    private static let presetsKey = "moodist.presets"
    private static let recentMixIdsKey = "moodist.recentMixIds"
    private static let recentSoundIdsKey = "moodist.recentSoundIds"
    private static let favoriteMixIdsKey = "moodist.favoriteMixIds"
    private static let favoriteSoundIdsKey = "moodist.favoriteSoundIds"
    static let maxRecentMixesCountKey = "MoodistMac.maxRecentMixesCount"
    static let maxRecentSoundsCountKey = "MoodistMac.maxRecentSoundsCount"
    static let menuBarEnabledKey = "MoodistMac.menuBarEnabled"
    static let accentColorHexKey = "MoodistMac.accentColorHex"
    static let appearanceModeKey = "MoodistMac.appearanceMode"
    static let transparencyEnabledKey = "MoodistMac.transparencyEnabled"
    static let mediaKeyNextMixKey = "MoodistMac.mediaKeyNextMix"
    static let collapseCategoriesOnColdOpenKey = "MoodistMac.collapseCategoriesOnColdOpen"
    /// Clave que usa AppKit para persistir el frame de la ventana principal.
    private static let appKitMainWindowFrameKey = "NSWindow Frame MoodistMainWindow"
    private static let sidebarSectionsCollapsedKey = "MoodistMac.sidebarSectionsCollapsed"
    private static let timerUsageCountsKey = "MoodistMac.timerUsageCounts"
    private static let scrollAnchorIdsKey = "MoodistMac.scrollAnchorIds"

    static func loadSounds() -> [String: SoundStateItem]? {
        guard let data = UserDefaults.standard.data(forKey: soundsKey) else { return nil }
        return try? JSONDecoder().decode([String: SoundStateItem].self, from: data)
    }

    static func saveSounds(_ state: [String: SoundStateItem]) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: soundsKey)
    }

    static func loadGlobalVolume() -> Double? {
        guard UserDefaults.standard.object(forKey: globalVolumeKey) != nil else { return nil }
        return max(0, min(1, UserDefaults.standard.double(forKey: globalVolumeKey)))
    }

    static func saveGlobalVolume(_ volume: Double) {
        UserDefaults.standard.set(volume, forKey: globalVolumeKey)
    }

    static func loadPresets() -> [Preset] {
        guard let data = UserDefaults.standard.data(forKey: presetsKey) else { return [] }
        let decoder = JSONDecoder()
        if let presets = try? decoder.decode([Preset].self, from: data) {
            return presets
        }

        // Fallback tolerante: recupera elementos válidos si el array contiene
        // entradas legacy/corruptas que invalidan el decode completo.
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
    // Guarda los presets codificados como JSON. Si el encode falla, no hace nada para evitar corromper datos existentes.
    static func savePresets(_ presets: [Preset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: presetsKey)
    }
    // Carga y guarda arrays de ids (recientes y favoritos) codificados como JSON. Si el decode falla, devuelve array vacío para evitar corromper datos existentes.
    static func loadRecentMixIds() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: recentMixIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    static func saveRecentMixIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: recentMixIdsKey)
    }

    static func loadRecentSoundIds() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: recentSoundIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    static func saveRecentSoundIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: recentSoundIdsKey)
    }

    static func loadFavoriteMixIds() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: favoriteMixIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    static func saveFavoriteMixIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: favoriteMixIdsKey)
    }

    static func loadFavoriteSoundIds() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: favoriteSoundIdsKey),
            let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return ids
    }

    static func saveFavoriteSoundIds(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        UserDefaults.standard.set(data, forKey: favoriteSoundIdsKey)
    }

    /// Máximo de mixes recientes en la barra lateral (5...15). Por defecto 10.
    static func loadMaxRecentMixesCount() -> Int {
        let v = UserDefaults.standard.object(forKey: maxRecentMixesCountKey) as? Int ?? 10
        return min(15, max(5, v))
    }

    /// Máximo de sonidos recientes en la barra lateral (5...15). Por defecto 12.
    static func loadMaxRecentSoundsCount() -> Int {
        let v = UserDefaults.standard.object(forKey: maxRecentSoundsCountKey) as? Int ?? 12
        return min(15, max(5, v))
    }

    static func loadTransparencyEnabled() -> Bool {
        guard UserDefaults.standard.object(forKey: transparencyEnabledKey) != nil else {
            return true
        }
        return UserDefaults.standard.bool(forKey: transparencyEnabledKey)
    }

    static func saveTransparencyEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: transparencyEnabledKey)
    }

    /// Si true, la tecla de medios "Siguiente" pasa al siguiente mix. Por defecto true.
    static func loadMediaKeyNextMix() -> Bool {
        guard UserDefaults.standard.object(forKey: mediaKeyNextMixKey) != nil else { return true }
        return UserDefaults.standard.bool(forKey: mediaKeyNextMixKey)
    }

    /// Estado colapsado de secciones de la barra lateral (id -> true = colapsado). Por defecto todas expandidas.
    static func loadSidebarSectionsCollapsed() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: sidebarSectionsCollapsedKey),
            let dict = try? JSONDecoder().decode([String: Bool].self, from: data)
        else { return [:] }
        return dict
    }

    static func saveSidebarSectionsCollapsed(_ value: [String: Bool]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: sidebarSectionsCollapsedKey)
    }

    /// Uso de temporizadores (duración en segundos -> cantidad de uso).
    static func loadTimerUsageCounts() -> [Int: Int] {
        guard
            let dict = UserDefaults.standard.dictionary(forKey: timerUsageCountsKey)
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

    static func saveTimerUsageCounts(_ counts: [Int: Int]) {
        let dict = Dictionary(uniqueKeysWithValues: counts.map { (String($0.key), $0.value) })
        UserDefaults.standard.set(dict, forKey: timerUsageCountsKey)
    }

    /// Anchors de scroll por panel (sounds, mixes, soundsSearch, mixesSearch) para restaurar posición al cambiar de pestaña o reabrir la app.
    static func loadScrollAnchorIds() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: scrollAnchorIdsKey),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }

    static func saveScrollAnchorIds(_ value: [String: String]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: scrollAnchorIdsKey)
    }

    /// Borra todas las claves usadas por la app (sounds, globalVolume, presets, apariencia).
    static func resetAll() {
        UserDefaults.standard.removeObject(forKey: soundsKey)
        UserDefaults.standard.removeObject(forKey: globalVolumeKey)
        UserDefaults.standard.removeObject(forKey: presetsKey)
        UserDefaults.standard.removeObject(forKey: recentMixIdsKey)
        UserDefaults.standard.removeObject(forKey: recentSoundIdsKey)
        UserDefaults.standard.removeObject(forKey: favoriteMixIdsKey)
        UserDefaults.standard.removeObject(forKey: favoriteSoundIdsKey)
        UserDefaults.standard.removeObject(forKey: maxRecentMixesCountKey)
        UserDefaults.standard.removeObject(forKey: maxRecentSoundsCountKey)
        UserDefaults.standard.removeObject(forKey: menuBarEnabledKey)
        UserDefaults.standard.removeObject(forKey: accentColorHexKey)
        UserDefaults.standard.removeObject(forKey: appearanceModeKey)
        UserDefaults.standard.removeObject(forKey: transparencyEnabledKey)
        UserDefaults.standard.removeObject(forKey: mediaKeyNextMixKey)
        UserDefaults.standard.removeObject(forKey: collapseCategoriesOnColdOpenKey)
        UserDefaults.standard.removeObject(forKey: scrollAnchorIdsKey)
        UserDefaults.standard.removeObject(forKey: appKitMainWindowFrameKey)
        UserDefaults.standard.removeObject(forKey: sidebarSectionsCollapsedKey)
        UserDefaults.standard.removeObject(forKey: timerUsageCountsKey)
    }
}
