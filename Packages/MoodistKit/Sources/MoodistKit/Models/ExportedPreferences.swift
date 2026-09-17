//
//  ExportedPreferences.swift
//  MoodistMac
//
//  Model for exporting and importing preferences.
//

import Foundation

public struct ExportedPreferences: Codable {
    /// Format version for future imports.
    public static let currentVersion = 1

    public let version: Int
    public let exportDate: String
    public let presets: [Preset]
    public let favoriteMixIds: [String]
    public let favoriteSoundIds: [String]

    public init(version: Int = Self.currentVersion, exportDate: String, presets: [Preset], favoriteMixIds: [String], favoriteSoundIds: [String]) {
        self.version = version
        self.exportDate = exportDate
        self.presets = presets
        self.favoriteMixIds = favoriteMixIds
        self.favoriteSoundIds = favoriteSoundIds
    }

    public static func exportDateString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
