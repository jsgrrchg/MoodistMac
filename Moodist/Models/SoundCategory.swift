//
//  SoundCategory.swift
//  MoodistMac
//
//  Categoría de sonidos: id, título, icono SF Symbol, lista de sonidos.
//

import Foundation

struct SoundCategory: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let sounds: [Sound]

    init(id: String, title: String, iconName: String, sounds: [Sound]) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.sounds = sounds
    }
}
