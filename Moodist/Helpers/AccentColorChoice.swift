//
//  AccentColorChoice.swift
//  MoodistMac
//
//  Paleta de acentos estilo macOS (Multicolor + colores clásicos).
//

import SwiftUI
import AppKit

enum AccentColorChoice: String, CaseIterable, Identifiable {
    case system
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case graphite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return L10n.accentColorSystem
        case .blue: return L10n.accentColorBlue
        case .purple: return L10n.accentColorPurple
        case .pink: return L10n.accentColorPink
        case .red: return L10n.accentColorRed
        case .orange: return L10n.accentColorOrange
        case .yellow: return L10n.accentColorYellow
        case .green: return L10n.accentColorGreen
        case .graphite: return L10n.accentColorGraphite
        }
    }

    /// Color a aplicar a la app (nil = usar acento del sistema).
    var accentColor: Color? {
        switch self {
        case .system:
            return nil
        default:
            return swatchColor
        }
    }

    var swatchStyle: AnyShapeStyle {
        switch self {
        case .system:
            return AnyShapeStyle(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(nsColor: .systemPink),
                        Color(nsColor: .systemRed),
                        Color(nsColor: .systemOrange),
                        Color(nsColor: .systemYellow),
                        Color(nsColor: .systemGreen),
                        Color(nsColor: .systemBlue),
                        Color(nsColor: .systemPurple),
                        Color(nsColor: .systemPink)
                    ]),
                    center: .center
                )
            )
        default:
            return AnyShapeStyle(swatchColor)
        }
    }

    private var swatchColor: Color {
        switch self {
        case .blue: return Color(nsColor: .systemBlue)
        case .purple: return Color(nsColor: .systemPurple)
        case .pink: return Color(nsColor: .systemPink)
        case .red: return Color(nsColor: .systemRed)
        case .orange: return Color(nsColor: .systemOrange)
        case .yellow: return Color(nsColor: .systemYellow)
        case .green: return Color(nsColor: .systemGreen)
        case .graphite: return Color(nsColor: .systemGray)
        case .system: return Color(nsColor: .controlAccentColor)
        }
    }

    static func loadSelection() -> AccentColorChoice {
        let raw = UserDefaults.standard.string(forKey: PersistenceService.accentColorHexKey)
            ?? AccentColorChoice.graphite.rawValue
        return AccentColorChoice(rawValue: raw) ?? .graphite
    }

    static var resolvedAccentColor: Color {
        let choice = loadSelection()
        return choice.accentColor ?? Color.accentColor
    }
}
