//
//  Sound.swift
//  MoodistMac
//
//  Individual sound: ID, label, bundle path, and SF Symbol icon.
//

import Foundation

struct Sound: Identifiable, Hashable {
    let id: String
    let label: String
    /// File name, for example "river.mp3".
    let fileName: String
    /// Bundle subfolder, for example "nature".
    let categoryFolder: String
    /// SF Symbol name for the icon.
    let iconName: String

    init(id: String, label: String, fileName: String, categoryFolder: String, iconName: String) {
        self.id = id
        self.label = label
        self.fileName = fileName
        self.categoryFolder = categoryFolder
        self.iconName = iconName
    }
}
