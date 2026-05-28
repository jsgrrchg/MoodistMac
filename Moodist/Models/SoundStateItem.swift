//
//  SoundStateItem.swift
//  MoodistMac
//
//  Per-sound state: selection, favorite status, and volume.
//

import Foundation

struct SoundStateItem: Codable, Equatable {
    var isSelected: Bool
    var isFavorite: Bool
    var volume: Double

    static let `default` = SoundStateItem(isSelected: false, isFavorite: false, volume: 0.5)
}
