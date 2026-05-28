//
//  Preset.swift
//  MoodistMac
//
//  Preset: saved sound combination with IDs and volumes.
//

import Foundation

struct Preset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var iconName: String
    /// Ordered sound IDs.
    var soundIds: [String]
    /// Volume by soundId. Missing values default to 0.5.
    var volumes: [String: Double]

    init(
        id: String = UUID().uuidString, name: String, iconName: String = "sparkles",
        soundIds: [String], volumes: [String: Double] = [:]
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.soundIds = soundIds
        self.volumes = volumes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName
        case soundIds
        case volumes
    }
    // Custom coding preserves default values and compatibility with older versions.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconName = (try? container.decode(String.self, forKey: .iconName)) ?? "sparkles"
        soundIds = try container.decode([String].self, forKey: .soundIds)
        volumes = (try? container.decodeIfPresent([String: Double].self, forKey: .volumes)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(iconName, forKey: .iconName)
        try container.encode(soundIds, forKey: .soundIds)
        try container.encode(volumes, forKey: .volumes)
    }

    func volume(for soundId: String) -> Double {
        volumes[soundId] ?? 0.5
    }

    /// Converts the preset to a Mix for display in the Custom section of Mixes.
    func toMix() -> Mix {
        Mix(id: id, name: name, iconName: iconName, soundIds: soundIds, volumes: volumes)
    }
}
