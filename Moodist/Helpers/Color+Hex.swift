//
//  Color+Hex.swift
//  MoodistMac
//
//  Persistencia de color de acento como hex en UserDefaults.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Devuelve el color en hex "#RRGGBB". En macOS usa NSColor para obtener componentes.
    var hexString: String {
        #if canImport(AppKit)
        let ns = NSColor(self)
        guard let sRGB = ns.usingColorSpace(.sRGB) else {
            return "#007AFF"
        }
        let r = Int(round(sRGB.redComponent * 255))
        let g = Int(round(sRGB.greenComponent * 255))
        let b = Int(round(sRGB.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#007AFF"
        #endif
    }
}
