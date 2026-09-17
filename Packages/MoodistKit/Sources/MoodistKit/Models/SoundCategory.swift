//
//  SoundCategory.swift
//  MoodistMac
//
//  Sound category: ID, title, SF Symbol icon, and sound list.
//

import Foundation

public struct SoundCategory: Identifiable {
    public let id: String
    public let title: String
    public let iconName: String
    public let sounds: [Sound]

    public init(id: String, title: String, iconName: String, sounds: [Sound]) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.sounds = sounds
    }
}
