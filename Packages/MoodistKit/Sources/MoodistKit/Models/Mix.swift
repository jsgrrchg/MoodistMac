//
//  Mix.swift
//  MoodistMac
//
//  Thematic mix: preset with name, icon and fixed volumes. Converts to Preset for playback.
//

import Foundation

public struct Mix: Identifiable {
    public init(id: String, name: String, iconName: String, soundIds: [String], volumes: [String: Double]) { self.id = id; self.name = name; self.iconName = iconName; self.soundIds = soundIds; self.volumes = volumes }

    public let id: String
    public let name: String
    public let iconName: String
    public let soundIds: [String]
    public let volumes: [String: Double]

    /// Converts to Preset so MacSoundStore.applyPreset can be used.
    public func toPreset() -> Preset {
        Preset(id: id, name: name, iconName: iconName, soundIds: soundIds, volumes: volumes)
    }
}

public struct MixCategory: Identifiable {
    public init(id: String, title: String, iconName: String, mixes: [Mix]) { self.id = id; self.title = title; self.iconName = iconName; self.mixes = mixes }

    public let id: String
    public let title: String
    public let iconName: String
    public let mixes: [Mix]
}
