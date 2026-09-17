//
//  SoundStateItem.swift
//  MoodistMac
//
//  Per-sound state: selection, favorite status, and volume.
//

import Foundation

public struct SoundStateItem: Codable, Equatable {
    public init(isSelected: Bool, isFavorite: Bool, volume: Double) { self.isSelected = isSelected; self.isFavorite = isFavorite; self.volume = volume }

    public var isSelected: Bool
    public var isFavorite: Bool
    public var volume: Double

    public static let `default` = SoundStateItem(isSelected: false, isFavorite: false, volume: 0.5)
}
