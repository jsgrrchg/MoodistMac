//
//  Mix.swift
//  MoodistMac
//
//  Thematic mix: preset with name, icon and fixed volumes. Converts to Preset for playback.
//

import Foundation

struct Mix: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let soundIds: [String]
    let volumes: [String: Double]

    /// Converts to Preset so SoundStore.applyPreset can be used.
    func toPreset() -> Preset {
        Preset(id: id, name: name, iconName: iconName, soundIds: soundIds, volumes: volumes)
    }
}

struct MixCategory: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let mixes: [Mix]
}
