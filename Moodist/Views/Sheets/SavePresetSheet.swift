//
//  SavePresetSheet.swift
//  MoodistMac
//
//  Save Mix modal with SF Symbols picker.
//

import SwiftUI
import Foundation

// MARK: - Save Mix sheet (SwiftUI; evita NSAlert y bloqueos)

private struct SaveMixIconOption: Identifiable {
    let id: String
    let sfSymbolName: String
}

private struct SaveMixIconCategory: Identifiable {
    let id: String
    let categorySymbol: String
    let symbols: [String]
}

private let saveMixIconCategories: [SaveMixIconCategory] = [
    SaveMixIconCategory(
        id: "featured",
        categorySymbol: "sparkles",
        symbols: [
            "sparkles", "leaf.fill", "moon.zzz.fill", "cloud.rain.fill", "wind", "water.waves",
            "flame.fill", "music.note", "drop.fill", "snowflake", "sun.max.fill", "moon.stars.fill",
            "leaf.circle.fill", "bird.fill", "fish.fill", "pawprint.fill", "heart.fill", "star.fill",
            "book.fill", "cup.and.saucer.fill", "house.fill", "bolt.fill", "airplane", "car.fill",
            "headphones", "speaker.wave.2.fill"
        ]
    ),
    SaveMixIconCategory(
        id: "nature",
        categorySymbol: "leaf.fill",
        symbols: [
            "leaf.fill", "leaf.circle.fill", "tree.fill", "water.waves", "drop.fill", "flame.fill",
            "snowflake", "sun.max.fill", "sunrise.fill", "sunset.fill", "moon.stars.fill", "wind",
            "mountain.2.fill", "globe", "bird.fill", "fish.fill", "pawprint.fill", "flower.fill",
            "rainbow", "tornado"
        ]
    ),
    SaveMixIconCategory(
        id: "weather",
        categorySymbol: "cloud.sun.fill",
        symbols: [
            "cloud.sun.fill", "cloud.moon.fill", "cloud.fill", "cloud.rain.fill", "cloud.drizzle.fill",
            "cloud.heavyrain.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill", "cloud.snow.fill",
            "cloud.fog.fill", "sun.max.fill", "moon.stars.fill", "wind", "tornado", "umbrella.fill",
            "drop.fill", "snowflake", "thermometer.sun.fill"
        ]
    ),
    SaveMixIconCategory(
        id: "sleep",
        categorySymbol: "moon.zzz.fill",
        symbols: [
            "moon.zzz.fill", "moon.fill", "moon.stars.fill", "bed.double.fill", "zzz", "alarm.fill",
            "clock.fill", "sparkles", "star.fill", "eye.slash.fill", "ear.fill", "heart.fill",
            "brain.head.profile", "waveform.path.ecg", "speaker.slash.fill", "cloud.moon.fill"
        ]
    ),
    SaveMixIconCategory(
        id: "focus",
        categorySymbol: "book.fill",
        symbols: [
            "book.fill", "books.vertical.fill", "doc.fill", "doc.text.fill", "folder.fill",
            "pencil.and.outline", "keyboard", "desktopcomputer", "printer.fill", "clock.fill",
            "chart.line.uptrend.xyaxis", "brain.head.profile", "lightbulb.fill", "glasses", "target",
            "checkmark.seal.fill", "graduationcap.fill", "briefcase.fill"
        ]
    ),
    SaveMixIconCategory(
        id: "places",
        categorySymbol: "house.fill",
        symbols: [
            MixIcon.palmTreeID,
            "house.fill", "building.2.fill", "building.columns.fill", "tent.fill", "mappin.circle.fill",
            "map.fill", "tram.fill", "airplane", "car.fill", "bicycle", "sailboat.fill", "bus.fill",
            "ferry.fill", "train.side.front.car", "cup.and.saucer.fill", "cart.fill", "fork.knife",
            "washer.fill", "books.vertical.fill", "globe"
        ]
    ),
    SaveMixIconCategory(
        id: "audio",
        categorySymbol: "music.note",
        symbols: [
            "music.note", "music.note.list", "headphones", "speaker.wave.2.fill", "speaker.fill",
            "speaker.slash.fill", "waveform", "waveform.circle.fill", "dot.radiowaves.left.and.right",
            "radio.fill", "mic.fill", "guitars.fill", "pianokeys", "metronome.fill", "record.circle",
            "bell.fill"
        ]
    ),
    SaveMixIconCategory(
        id: "shapes",
        categorySymbol: "circle.grid.3x3.fill",
        symbols: [
            "circle.grid.3x3.fill", "circle.hexagongrid.fill", "square.grid.2x2.fill", "square.grid.3x3.fill",
            "triangle.fill", "diamond.fill", "hexagon.fill", "seal.fill", "capsule.fill",
            "scribble.variable", "paintbrush.fill", "wand.and.stars", "sparkles", "star.circle.fill",
            "circle.fill", "square.fill", "triangle.circle.fill", "scribble"
        ]
    )
]

private let saveMixIconOptions: [SaveMixIconOption] = {
    let uniqueSymbols = Array(NSOrderedSet(array: saveMixIconCategories.flatMap(\.symbols))) as? [String] ?? []
    return uniqueSymbols.map { SaveMixIconOption(id: $0, sfSymbolName: $0) }
}()

private let saveMixIconOptionsById: [String: SaveMixIconOption] = Dictionary(
    uniqueKeysWithValues: saveMixIconOptions.map { ($0.id, $0) }
)

private let saveMixDefaultIconID = saveMixIconOptions.first?.id ?? "sparkles"
private let saveMixDefaultCategoryID = saveMixIconCategories.first?.id ?? "featured"

private extension SaveMixIconOption {
    var displayName: String {
        MixIcon.displayName(for: sfSymbolName)
    }
}

private extension SaveMixIconCategory {
    var localizedTitle: String {
        L10n.saveMixIconCategoryTitle(id)
    }
}

private struct SaveMixCategoryPill: View {
    let category: SaveMixIconCategory
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                    .fill(isSelected ? MoodistTheme.Colors.selectedBackground.opacity(0.9) : MoodistTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                            .strokeBorder(
                                isSelected ? MoodistTheme.Colors.accent.opacity(0.85) : Color.primary.opacity(0.10),
                                lineWidth: isSelected ? 1.25 : 1
                            )
                    )
                Image(systemName: category.categorySymbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
            }
            .frame(width: 34, height: 30)
            Text(category.localizedTitle)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
                .lineLimit(1)
                .frame(width: 58)
        }
        .padding(.vertical, 1)
    }
}

struct SavePresetSheet: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var mixName = ""
    @State private var selectedIconID = saveMixDefaultIconID
    @State private var selectedCategoryID = saveMixDefaultCategoryID
    @State private var iconSearchQuery = ""
    @State private var isCancelHovered = false
    @State private var isSaveHovered = false
    @FocusState private var isNameFocused: Bool

    private var canSave: Bool {
        !mixName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentIconOption: SaveMixIconOption {
        saveMixIconOptionsById[selectedIconID]
            ?? saveMixIconOptions.first
            ?? SaveMixIconOption(id: saveMixDefaultIconID, sfSymbolName: saveMixDefaultIconID)
    }

    private var visibleIconCategories: [SaveMixIconCategory] {
        let query = iconSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return saveMixIconCategories }

        return saveMixIconCategories.compactMap { category in
            let symbols = category.symbols.filter { symbol in
                symbol.localizedCaseInsensitiveContains(query)
            }
            if symbols.isEmpty, !category.localizedTitle.localizedCaseInsensitiveContains(query) {
                return nil
            }
            return SaveMixIconCategory(id: category.id, categorySymbol: category.categorySymbol, symbols: symbols)
        }
    }

    private var currentCategory: SaveMixIconCategory? {
        visibleIconCategories.first(where: { $0.id == selectedCategoryID }) ?? visibleIconCategories.first
    }

    private var currentCategorySymbols: [String] {
        currentCategory?.symbols ?? []
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xSmall) {
                HStack(spacing: MoodistTheme.Spacing.small) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.presetSaveDialogTitle)
                        .font(.title2.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(L10n.saveMixSubtitle)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            .padding(.bottom, MoodistTheme.Spacing.xLarge)

            TextField(L10n.presetNamePlaceholder, text: $mixName)
                .textFieldStyle(.plain)
                .focused($isNameFocused)
                .font(.body)
                .padding(.horizontal, MoodistTheme.Spacing.medium)
                .padding(.vertical, MoodistTheme.Spacing.small + 2)
                .background(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                        .fill(MoodistTheme.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                )
                .onSubmit { if canSave { saveAndDismiss() } }
                .padding(.bottom, MoodistTheme.Spacing.xLarge)

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                Text(L10n.iconLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)

                TextField(L10n.saveMixIconSearchPlaceholder, text: $iconSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .padding(.horizontal, MoodistTheme.Spacing.medium)
                    .padding(.vertical, MoodistTheme.Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                            .fill(MoodistTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                            )
                    )

                if visibleIconCategories.isEmpty {
                    Text(L10n.saveMixIconNoResults)
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MoodistTheme.Spacing.small) {
                            ForEach(visibleIconCategories) { category in
                                let isSelected = category.id == (currentCategory?.id ?? selectedCategoryID)
                                Button {
                                    selectedCategoryID = category.id
                                } label: {
                                    SaveMixCategoryPill(category: category, isSelected: isSelected)
                                }
                                .buttonStyle(.plain)
                                .help(category.localizedTitle)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .padding(.horizontal, MoodistTheme.Spacing.xSmall)
                    .padding(.vertical, MoodistTheme.Spacing.xSmall)
                    .background(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                            .fill(MoodistTheme.Colors.cardBackground.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                            )
                    )
                    .accessibilityHint(L10n.saveMixIconCategoriesHint)
                }

                let columns = [GridItem(.adaptive(minimum: 40, maximum: 52), spacing: MoodistTheme.Spacing.small)]
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                        ForEach(currentCategorySymbols, id: \.self) { symbolName in
                            let isSelected = symbolName == currentIconOption.sfSymbolName
                            Button {
                                selectedIconID = symbolName
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                                        .fill(isSelected ? MoodistTheme.Colors.selectedBackground.opacity(0.9) : MoodistTheme.Colors.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                                                .strokeBorder(
                                                    isSelected ? MoodistTheme.Colors.accent.opacity(0.9) : Color.primary.opacity(0.12),
                                                    lineWidth: isSelected ? 1.5 : 1
                                                )
                                        )
                                    MixIconImage(
                                        iconName: symbolName,
                                        size: 18,
                                        weight: .semibold,
                                        color: isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                                    )
                                }
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .help(MixIcon.displayName(for: symbolName))
                            .accessibilityLabel(MixIcon.displayName(for: symbolName))
                            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                        }
                    }
                    .padding(.horizontal, MoodistTheme.Spacing.xSmall)
                    .padding(.vertical, MoodistTheme.Spacing.xSmall)
                }
                .frame(height: 174)
                .background(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                        .fill(MoodistTheme.Colors.cardBackground.opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium)
                                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
                        )
                )
                .accessibilityHint(L10n.saveMixIconMenuHint)

                Text(L10n.saveMixIconLabel(currentIconOption.displayName))
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, MoodistTheme.Spacing.xLarge)

            HStack(spacing: MoodistTheme.Spacing.medium) {
                Spacer()
                Button(L10n.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isCancelHovered,
                        isPrimary: false,
                        isCompact: false
                    ))
                    .onHover { isCancelHovered = $0 }
                Button(L10n.save) { saveAndDismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isSaveHovered,
                        isPrimary: true,
                        isCompact: false
                    ))
                    .onHover { isSaveHovered = $0 }
                    .disabled(!canSave)
            }
        }
        .padding(MoodistTheme.Spacing.xLarge)
        .frame(width: 378)
        .background(PlatformColor.windowBackground)
        .onAppear { isNameFocused = true }
    }

    private func saveAndDismiss() {
        let name = mixName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        store.saveCurrentAsPreset(name: name, iconName: currentIconOption.sfSymbolName)
        onDismiss()
    }
}
