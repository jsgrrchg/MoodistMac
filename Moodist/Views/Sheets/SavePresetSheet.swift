//
//  SavePresetSheet.swift
//  MoodistMac
//
//  Save Mix modal with SF Symbols picker.
//

import Foundation
import SwiftUI

// MARK: - Data models

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
            "leaf.circle.fill", "bird.fill", "fish.fill", "pawprint.fill", "heart.fill",
            "star.fill",
            "book.fill", "cup.and.saucer.fill", "house.fill", "bolt.fill", "airplane", "car.fill",
            "headphones", "speaker.wave.2.fill",
        ]
    ),
    SaveMixIconCategory(
        id: "nature",
        categorySymbol: "leaf.fill",
        symbols: [
            "leaf.fill", "leaf.circle.fill", "tree.fill", "water.waves", "drop.fill", "flame.fill",
            "snowflake", "sun.max.fill", "sunrise.fill", "sunset.fill", "moon.stars.fill", "wind",
            "mountain.2.fill", "globe", "bird.fill", "fish.fill", "pawprint.fill", "flower.fill",
            "rainbow", "tornado",
        ]
    ),
    SaveMixIconCategory(
        id: "weather",
        categorySymbol: "cloud.sun.fill",
        symbols: [
            "cloud.sun.fill", "cloud.moon.fill", "cloud.fill", "cloud.rain.fill",
            "cloud.drizzle.fill",
            "cloud.heavyrain.fill", "cloud.bolt.fill", "cloud.bolt.rain.fill", "cloud.snow.fill",
            "cloud.fog.fill", "sun.max.fill", "moon.stars.fill", "wind", "tornado", "umbrella.fill",
            "drop.fill", "snowflake", "thermometer.sun.fill",
        ]
    ),
    SaveMixIconCategory(
        id: "sleep",
        categorySymbol: "moon.zzz.fill",
        symbols: [
            "moon.zzz.fill", "moon.fill", "moon.stars.fill", "bed.double.fill", "zzz", "alarm.fill",
            "clock.fill", "sparkles", "star.fill", "eye.slash.fill", "ear.fill", "heart.fill",
            "brain.head.profile", "waveform.path.ecg", "speaker.slash.fill", "cloud.moon.fill",
        ]
    ),
    SaveMixIconCategory(
        id: "focus",
        categorySymbol: "book.fill",
        symbols: [
            "book.fill", "books.vertical.fill", "doc.fill", "doc.text.fill", "folder.fill",
            "pencil.and.outline", "keyboard", "desktopcomputer", "printer.fill", "clock.fill",
            "chart.line.uptrend.xyaxis", "brain.head.profile", "lightbulb.fill", "glasses",
            "target",
            "checkmark.seal.fill", "graduationcap.fill", "briefcase.fill",
        ]
    ),
    SaveMixIconCategory(
        id: "places",
        categorySymbol: "house.fill",
        symbols: [
            MixIcon.palmTreeID,
            "house.fill", "building.2.fill", "building.columns.fill", "tent.fill",
            "mappin.circle.fill",
            "map.fill", "tram.fill", "airplane", "car.fill", "bicycle", "sailboat.fill", "bus.fill",
            "ferry.fill", "train.side.front.car", "cup.and.saucer.fill", "cart.fill", "fork.knife",
            "washer.fill", "books.vertical.fill", "globe",
        ]
    ),
    SaveMixIconCategory(
        id: "audio",
        categorySymbol: "music.note",
        symbols: [
            "music.note", "music.note.list", "headphones", "speaker.wave.2.fill", "speaker.fill",
            "speaker.slash.fill", "waveform", "waveform.circle.fill",
            "dot.radiowaves.left.and.right",
            "radio.fill", "mic.fill", "guitars.fill", "pianokeys", "metronome.fill",
            "record.circle",
            "bell.fill",
        ]
    ),
    SaveMixIconCategory(
        id: "shapes",
        categorySymbol: "circle.grid.3x3.fill",
        symbols: [
            "circle.grid.3x3.fill", "circle.hexagongrid.fill", "square.grid.2x2.fill",
            "square.grid.3x3.fill",
            "triangle.fill", "diamond.fill", "hexagon.fill", "seal.fill", "capsule.fill",
            "scribble.variable", "paintbrush.fill", "wand.and.stars", "sparkles",
            "star.circle.fill",
            "circle.fill", "square.fill", "triangle.circle.fill", "scribble",
        ]
    ),
]

private let saveMixIconOptions: [SaveMixIconOption] = {
    let uniqueSymbols =
        Array(NSOrderedSet(array: saveMixIconCategories.flatMap(\.symbols))) as? [String] ?? []
    return uniqueSymbols.map { SaveMixIconOption(id: $0, sfSymbolName: $0) }
}()

private let saveMixIconOptionsById: [String: SaveMixIconOption] = Dictionary(
    uniqueKeysWithValues: saveMixIconOptions.map { ($0.id, $0) }
)

private let saveMixDefaultIconID = saveMixIconOptions.first?.id ?? "sparkles"
private let saveMixDefaultCategoryID = saveMixIconCategories.first?.id ?? "featured"

extension SaveMixIconOption {
    fileprivate var displayName: String {
        MixIcon.displayName(for: sfSymbolName)
    }
}

extension SaveMixIconCategory {
    fileprivate var localizedTitle: String {
        L10n.saveMixIconCategoryTitle(id)
    }
}

// MARK: - Category pill

private struct SaveMixCategoryPill: View {
    let category: SaveMixIconCategory
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.categorySymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(
                    isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                )
                .frame(width: 13)

            Text(category.localizedTitle)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.primary : MoodistTheme.Colors.secondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(
                    isSelected
                        ? MoodistTheme.Colors.selectedBackground : Color.primary.opacity(0.04)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected
                                ? MoodistTheme.Colors.accent.opacity(0.6)
                                : Color.primary.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Save Mix sheet

struct SavePresetSheet: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var mixName = ""
    @State private var selectedIconID = saveMixDefaultIconID
    @State private var selectedCategoryID = saveMixDefaultCategoryID
    @State private var iconSearchQuery = ""
    @State private var isCancelHovered = false
    @State private var isSaveHovered = false
    @State private var didInitializeForm = false
    @FocusState private var isNameFocused: Bool

    private var trimmedMixName: String {
        mixName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedMixName.isEmpty
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
            return SaveMixIconCategory(
                id: category.id, categorySymbol: category.categorySymbol, symbols: symbols)
        }
    }

    private var currentCategory: SaveMixIconCategory? {
        visibleIconCategories.first(where: { $0.id == selectedCategoryID })
            ?? visibleIconCategories.first
    }

    private var currentCategorySymbols: [String] {
        currentCategory?.symbols ?? []
    }

    private var iconGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 44, maximum: 52), spacing: 6)]
    }

    private var presetBeingEdited: Preset? {
        guard let editingPresetId = store.editingPresetId else { return nil }
        return store.presetsById[editingPresetId]
    }

    private var isEditingPreset: Bool {
        presetBeingEdited != nil
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            nameSection
            iconSection
            footerBar
        }
        .frame(width: 420)
        .background(sheetBackground)
        .onAppear {
            configureInitialFormStateIfNeeded()
        }
        .onChange(of: store.editingPresetId) { _, _ in
            didInitializeForm = false
            configureInitialFormStateIfNeeded()
        }
    }

    // MARK: - Sheet background

    private var sheetBackground: some View {
        ZStack {
            PlatformColor.windowBackground
            VStack(spacing: 0) {
                RadialGradient(
                    colors: [
                        MoodistTheme.Colors.accent.opacity(0.07),
                        Color.clear,
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 180
                )
                .frame(height: 150)
                Spacer()
            }
        }
    }

    // MARK: - Preview header

    private var previewHeader: some View {
        VStack(spacing: MoodistTheme.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MoodistTheme.Colors.selectedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(MoodistTheme.Colors.accent.opacity(0.25), lineWidth: 1.5)
                    )
                MixIconImage(
                    iconName: currentIconOption.sfSymbolName,
                    size: 26,
                    weight: .semibold,
                    color: MoodistTheme.Colors.accent
                )
            }
            .frame(width: 52, height: 52)
            .shadow(color: MoodistTheme.Colors.accent.opacity(0.15), radius: 12, y: 4)
            .animation(.spring(duration: 0.25, bounce: 0.3), value: selectedIconID)

            VStack(spacing: 4) {
                Text(isEditingPreset ? "Edit Mix" : L10n.presetSaveDialogTitle)
                    .font(.system(size: 15, weight: .semibold))
                Text(isEditingPreset ? "Update the mix name and icon." : L10n.saveMixSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }

    // MARK: - Name section

    private var nameSection: some View {
        HStack(spacing: MoodistTheme.Spacing.small) {
            Image(systemName: "character.cursor.ibeam")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(
                    isNameFocused ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                )
                .frame(width: 16)
                .animation(.easeInOut(duration: 0.15), value: isNameFocused)

            TextField(L10n.presetNamePlaceholder, text: $mixName)
                .textFieldStyle(.plain)
                .focused($isNameFocused)
                .font(.body)
                .onSubmit { if canSave { saveAndDismiss() } }
        }
        .padding(.horizontal, MoodistTheme.Spacing.medium)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                .fill(MoodistTheme.Colors.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                        .strokeBorder(
                            isNameFocused
                                ? MoodistTheme.Colors.accent.opacity(0.4)
                                : Color.primary.opacity(0.08),
                            lineWidth: isNameFocused ? 1.5 : 1
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: isNameFocused)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, MoodistTheme.Spacing.large)
    }

    // MARK: - Icon section

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            iconSearchField

            if visibleIconCategories.isEmpty {
                iconEmptyState
            } else {
                iconCategoryScroller
                iconGrid
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, MoodistTheme.Spacing.small)
    }

    private var iconSearchField: some View {
        HStack(spacing: MoodistTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)

            TextField(L10n.saveMixIconSearchPlaceholder, text: $iconSearchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))

            if !iconSearchQuery.isEmpty {
                Button {
                    iconSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MoodistTheme.Colors.secondaryText.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(L10n.cancel)
            }
        }
        .padding(.horizontal, MoodistTheme.Spacing.medium)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.small, style: .continuous)
                .fill(MoodistTheme.Colors.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.small, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var iconEmptyState: some View {
        Text(L10n.saveMixIconNoResults)
            .font(.system(size: 12))
            .foregroundStyle(MoodistTheme.Colors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, MoodistTheme.Spacing.xLarge)
    }

    private var iconCategoryScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
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
        }
        .accessibilityHint(L10n.saveMixIconCategoriesHint)
    }

    private var iconGrid: some View {
        ScrollView {
            LazyVGrid(columns: iconGridColumns, alignment: .leading, spacing: 6) {
                ForEach(currentCategorySymbols, id: \.self) { symbolName in
                    iconGridButton(for: symbolName)
                }
            }
            .padding(6)
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                .fill(MoodistTheme.Colors.cardBackground.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                )
        )
        .accessibilityHint(L10n.saveMixIconMenuHint)
    }

    private func iconGridButton(for symbolName: String) -> some View {
        let isSelected = symbolName == currentIconOption.sfSymbolName
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedIconID = symbolName
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? MoodistTheme.Colors.selectedBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(
                                isSelected ? MoodistTheme.Colors.accent.opacity(0.7) : Color.clear,
                                lineWidth: 1.5
                            )
                    )

                MixIconImage(
                    iconName: symbolName,
                    size: 16,
                    weight: .medium,
                    color: isSelected
                        ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                )
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(MixIcon.displayName(for: symbolName))
        .accessibilityLabel(MixIcon.displayName(for: symbolName))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack(spacing: MoodistTheme.Spacing.medium) {
            Spacer()

            Button(L10n.cancel) { onDismiss() }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(
                    HeaderActionButtonStyle(
                        isHovered: isCancelHovered,
                        isPrimary: false,
                        isCompact: false
                    )
                )
                .onHover { isCancelHovered = $0 }

            Button(L10n.save) { saveAndDismiss() }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(
                    HeaderActionButtonStyle(
                        isHovered: isSaveHovered,
                        isPrimary: true,
                        isCompact: false
                    )
                )
                .onHover { isSaveHovered = $0 }
                .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, MoodistTheme.Spacing.large)
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        let name = trimmedMixName
        guard !name.isEmpty else { return }
        if let preset = presetBeingEdited {
            store.updatePresetMetadata(
                id: preset.id, name: name, iconName: currentIconOption.sfSymbolName)
        } else {
            store.saveCurrentAsPreset(name: name, iconName: currentIconOption.sfSymbolName)
        }
        onDismiss()
    }

    private func configureInitialFormStateIfNeeded() {
        guard !didInitializeForm else { return }

        if let preset = presetBeingEdited {
            mixName = preset.name
            selectedIconID =
                saveMixIconOptionsById[preset.iconName] != nil
                ? preset.iconName : saveMixDefaultIconID
        } else if saveMixIconOptionsById[selectedIconID] == nil {
            selectedIconID = saveMixDefaultIconID
        }

        didInitializeForm = true
        isNameFocused = true
    }
}
