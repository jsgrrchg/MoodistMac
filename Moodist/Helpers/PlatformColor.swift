//
//  PlatformColor.swift
//  MoodistMac
//
//  Colores para macOS (Big Sur+).
//

import SwiftUI
import AppKit

enum PlatformColor {
    static var windowBackground: Color { Color(NSColor.windowBackgroundColor) }
    static var controlBackground: Color { Color(NSColor.controlBackgroundColor) }
}
