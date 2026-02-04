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
    /// Crea un Color desde una cadena hex (ej. "#RRGGBB" o "RRGGBB"). Devuelve nil si es inválida.
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        if hexSanitized.count == 8 { hexSanitized = String(hexSanitized.prefix(6)) }
        guard hexSanitized.count == 6, let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

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
