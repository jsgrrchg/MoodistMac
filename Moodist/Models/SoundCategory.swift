//
//  SoundCategory.swift
//  MoodistMac
//
//  Sound category: ID, title, SF Symbol icon, and sound list.
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
