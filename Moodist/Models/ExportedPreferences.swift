//
//  ExportedPreferences.swift
//  MoodistMac
//
//  Model for exporting and importing preferences.
//

import Foundation

struct ExportedPreferences: Codable {
    /// Format version for future imports.
    static let currentVersion = 1

    let version: Int
    let exportDate: String
    let presets: [Preset]
    let favoriteMixIds: [String]
    let favoriteSoundIds: [String]

    init(version: Int = Self.currentVersion, exportDate: String, presets: [Preset], favoriteMixIds: [String], favoriteSoundIds: [String]) {
        self.version = version
        self.exportDate = exportDate
        self.presets = presets
        self.favoriteMixIds = favoriteMixIds
        self.favoriteSoundIds = favoriteSoundIds
    }

    static func exportDateString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
