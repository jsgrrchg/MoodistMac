//
//  Preset.swift
//  MoodistMac
//
//  Preset: combinación guardada de sonidos (ids + volúmenes).
//

import Foundation

struct Preset: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var iconName: String
    /// IDs de sonidos en orden
    var soundIds: [String]
    /// Volumen por soundId (opcional; si falta usa 0.5)
    var volumes: [String: Double]

    init(id: String = UUID().uuidString, name: String, iconName: String = "sparkles", soundIds: [String], volumes: [String: Double] = [:]) {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconName = (try? container.decode(String.self, forKey: .iconName)) ?? "sparkles"
        soundIds = try container.decode([String].self, forKey: .soundIds)
        volumes = try container.decode([String: Double].self, forKey: .volumes)
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

    /// Convierte el preset a Mix para mostrarlo en la sección Custom de Mixes.
    func toMix() -> Mix {
        Mix(id: id, name: name, iconName: iconName, soundIds: soundIds, volumes: volumes)
    }
}
