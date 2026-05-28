//
//  Color+Hex.swift
//  MoodistMac
//
//  Persists the accent color as a hex value in UserDefaults.
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    /// Returns the color as "#RRGGBB". On macOS, NSColor provides the components.
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
