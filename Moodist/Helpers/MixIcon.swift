//
//  MixIcon.swift
//  MoodistMac
//
//  Centralized rendering and ids for custom mix icons.
//

import SwiftUI

enum MixIcon {
    static let palmTreeID = "palm-tree-solid"
    static let palmTreeAssetName = "PalmTreeSolid"
    static let palmTreeVisualScale: CGFloat = 0.82

    static func displayName(for iconName: String) -> String {
        if iconName == palmTreeID {
            return "Palm Tree"
        }
        return iconName
            .split(separator: ".")
            .map(String.init)
            .filter { $0 != "fill" && $0 != "circle" }
            .joined(separator: " ")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

struct MixIconImage: View {
    let iconName: String
    let size: CGFloat
    let frame: CGFloat
    let weight: Font.Weight
    let color: Color

    init(
        iconName: String,
        size: CGFloat,
        frame: CGFloat? = nil,
        weight: Font.Weight,
        color: Color
    ) {
        self.iconName = iconName
        self.size = size
        self.frame = frame ?? size
        self.weight = weight
        self.color = color
    }

    var body: some View {
        Group {
            if iconName == MixIcon.palmTreeID {
                Image(MixIcon.palmTreeAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(MixIcon.palmTreeVisualScale)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size, weight: weight))
            }
        }
        .foregroundStyle(color)
        .frame(width: frame, height: frame)
    }
}
