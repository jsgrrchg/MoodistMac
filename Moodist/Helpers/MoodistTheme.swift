//
//  MoodistTheme.swift
//  MoodistMac
//
//  Design tokens for spacing, colors, typography, and radii.
//

import SwiftUI

enum MoodistTheme {
    // MARK: - Spacing (4/8/12/16/24 grid)
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    // MARK: - Corner radius
    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 14
    }

    // MARK: - Colors (identity and states)
    enum Colors {
        static var accent: Color { AccentColorChoice.resolvedAccentColor }
        static var selectedBackground: Color { AccentColorChoice.resolvedAccentColor.opacity(0.12) }
        static var favorite: Color { accent }
        static let cardBackground = PlatformColor.controlBackground
        static let windowBackground = PlatformColor.windowBackground
        static let secondaryText = Color.secondary
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.semibold)
        static let title = Font.title2.weight(.semibold)
        /// Section titles sit one step above body text for clear hierarchy.
        static let headline = Font.title3.weight(.semibold)
        static let body = Font.body
        static let subheadline = Font.subheadline
    }
}
