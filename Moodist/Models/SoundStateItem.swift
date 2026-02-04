//
//  SoundStateItem.swift
//  MoodistMac
//
//  Estado por sonido: seleccionado, favorito, volumen.
//

import Foundation

struct SoundStateItem: Codable, Equatable {
    var isSelected: Bool
    var isFavorite: Bool
    var volume: Double

    static let `default` = SoundStateItem(isSelected: false, isFavorite: false, volume: 0.5)
}
