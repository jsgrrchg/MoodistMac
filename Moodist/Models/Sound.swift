//
//  Sound.swift
//  MoodistMac
//
//  Sonido individual: id, etiqueta, ruta en el bundle (SF Symbol como icono).
//

import Foundation

struct Sound: Identifiable, Hashable {
    let id: String
    let label: String
    /// Nombre del archivo (ej: "river.mp3")
    let fileName: String
    /// Subcarpeta en el bundle (ej: "nature")
    let categoryFolder: String
    /// Nombre del SF Symbol para el icono
    let iconName: String

    init(id: String, label: String, fileName: String, categoryFolder: String, iconName: String) {
        self.id = id
        self.label = label
        self.fileName = fileName
        self.categoryFolder = categoryFolder
        self.iconName = iconName
    }
}
