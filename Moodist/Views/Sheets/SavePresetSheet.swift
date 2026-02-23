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
        HStack(spacing: 7) {
            Image(systemName: category.categorySymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                .frame(width: 14)

            Text(category.localizedTitle)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? Color.primary : MoodistTheme.Colors.secondaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, MoodistTheme.Spacing.medium)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(isSelected ? MoodistTheme.Colors.selectedBackground.opacity(0.95) : MoodistTheme.Colors.cardBackground.opacity(0.7))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected ? MoodistTheme.Colors.accent.opacity(0.9) : Color.primary.opacity(0.10),
                            lineWidth: isSelected ? 1.2 : 1
                        )
                )
        )
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
            return SaveMixIconCategory(id: category.id, categorySymbol: category.categorySymbol, symbols: symbols)
        }
    }

    private var currentCategory: SaveMixIconCategory? {
        visibleIconCategories.first(where: { $0.id == selectedCategoryID }) ?? visibleIconCategories.first
    }

    private var currentCategorySymbols: [String] {
        currentCategory?.symbols ?? []
    }

    private var iconGridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 48, maximum: 56), spacing: MoodistTheme.Spacing.small)]
    }

    private var previewTitle: String {
        trimmedMixName.isEmpty ? L10n.presetNamePlaceholder : trimmedMixName
    }

    private var presetBeingEdited: Preset? {
        guard let editingPresetId = store.editingPresetId else { return nil }
        return store.presetsById[editingPresetId]
    }

    private var isEditingPreset: Bool {
        presetBeingEdited != nil
    }

    var body: some View {
        VStack(spacing: MoodistTheme.Spacing.large) {
            headerCard
            nameCard
            iconPickerCard
            footerBar
        }
        .padding(20)
        .frame(width: 460)
        .background(
            LinearGradient(
                colors: [
                    PlatformColor.windowBackground,
                    MoodistTheme.Colors.selectedBackground.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            configureInitialFormStateIfNeeded()
        }
        .onChange(of: store.editingPresetId) { _, _ in
            didInitializeForm = false
            configureInitialFormStateIfNeeded()
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: MoodistTheme.Spacing.large) {
            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xSmall) {
                HStack(spacing: MoodistTheme.Spacing.small) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(isEditingPreset ? "Edit Mix" : L10n.presetSaveDialogTitle)
                        .font(MoodistTheme.Typography.title)
                }
                Text(isEditingPreset ? "Update the mix name and icon." : L10n.saveMixSubtitle)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: MoodistTheme.Spacing.small)

            HStack(spacing: MoodistTheme.Spacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MoodistTheme.Colors.selectedBackground.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(MoodistTheme.Colors.accent.opacity(0.28), lineWidth: 1)
                        )
                    MixIconImage(
                        iconName: currentIconOption.sfSymbolName,
                        size: 18,
                        weight: .semibold,
                        color: MoodistTheme.Colors.accent
                    )
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(previewTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trimmedMixName.isEmpty ? MoodistTheme.Colors.secondaryText : Color.primary)
                        .lineLimit(1)
                    Text(currentIconOption.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, MoodistTheme.Spacing.small)
            .padding(.vertical, MoodistTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                    .fill(MoodistTheme.Colors.cardBackground.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .padding(MoodistTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            MoodistTheme.Colors.selectedBackground.opacity(0.55),
                            MoodistTheme.Colors.cardBackground.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            Text(L10n.presetNamePlaceholder)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)

            HStack(spacing: MoodistTheme.Spacing.small) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)

                TextField(L10n.presetNamePlaceholder, text: $mixName)
                    .textFieldStyle(.plain)
                    .focused($isNameFocused)
                    .font(.body)
                    .onSubmit { if canSave { saveAndDismiss() } }
            }
            .padding(.horizontal, MoodistTheme.Spacing.medium)
            .padding(.vertical, MoodistTheme.Spacing.small + 2)
            .background(nameFieldBackground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MoodistTheme.Spacing.large)
        .background(standardCardBackground)
    }

    private var iconPickerCard: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.medium) {
            HStack(alignment: .center, spacing: MoodistTheme.Spacing.small) {
                Text(L10n.iconLabel)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                HStack(spacing: 6) {
                    MixIconImage(
                        iconName: currentIconOption.sfSymbolName,
                        size: 12,
                        weight: .semibold,
                        color: MoodistTheme.Colors.accent
                    )
                    Text(currentIconOption.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(MoodistTheme.Colors.selectedBackground.opacity(0.7))
                )
            }

            iconSearchField

            if visibleIconCategories.isEmpty {
                iconEmptyState
            } else {
                iconCategoryScroller
                iconGrid
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MoodistTheme.Spacing.large)
        .background(standardCardBackground)
    }

    private var iconSearchField: some View {
        HStack(spacing: MoodistTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MoodistTheme.Colors.secondaryText)

            TextField(L10n.saveMixIconSearchPlaceholder, text: $iconSearchQuery)
                .textFieldStyle(.plain)
                .font(.subheadline)

            if !iconSearchQuery.isEmpty {
                Button {
                    iconSearchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MoodistTheme.Colors.secondaryText.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help(L10n.cancel)
            }
        }
        .padding(.horizontal, MoodistTheme.Spacing.medium)
        .padding(.vertical, MoodistTheme.Spacing.small)
        .background(subtlePanelBackground(opacity: 1.0))
    }

    private var iconEmptyState: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            Text(L10n.saveMixIconNoResults)
                .font(MoodistTheme.Typography.subheadline)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MoodistTheme.Spacing.medium)
        .background(subtlePanelBackground(opacity: 0.45))
    }

    private var iconCategoryScroller: some View {
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
            .padding(.horizontal, MoodistTheme.Spacing.small)
            .padding(.vertical, MoodistTheme.Spacing.small)
        }
        .background(subtlePanelBackground(opacity: 0.42))
        .accessibilityHint(L10n.saveMixIconCategoriesHint)
    }

    private var iconGrid: some View {
        ScrollView {
            LazyVGrid(columns: iconGridColumns, alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                ForEach(currentCategorySymbols, id: \.self) { symbolName in
                    iconGridButton(for: symbolName)
                }
            }
            .padding(MoodistTheme.Spacing.small)
        }
        .frame(height: 216)
        .background(subtlePanelBackground(opacity: 0.36))
        .accessibilityHint(L10n.saveMixIconMenuHint)
    }

    private func iconGridButton(for symbolName: String) -> some View {
        let isSelected = symbolName == currentIconOption.sfSymbolName
        return Button {
            selectedIconID = symbolName
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? MoodistTheme.Colors.selectedBackground.opacity(0.95) : MoodistTheme.Colors.cardBackground.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                isSelected ? MoodistTheme.Colors.accent.opacity(0.9) : Color.primary.opacity(0.10),
                                lineWidth: isSelected ? 1.4 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? MoodistTheme.Colors.accent.opacity(0.12) : .clear,
                        radius: isSelected ? 6 : 0,
                        y: 2
                    )

                MixIconImage(
                    iconName: symbolName,
                    size: 18,
                    weight: .semibold,
                    color: isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                )
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .help(MixIcon.displayName(for: symbolName))
        .accessibilityLabel(MixIcon.displayName(for: symbolName))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var footerBar: some View {
        HStack(spacing: MoodistTheme.Spacing.medium) {
            Text(L10n.saveMixIconLabel(currentIconOption.displayName))
                .font(MoodistTheme.Typography.subheadline)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
                .lineLimit(1)

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
        .padding(MoodistTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
                .fill(MoodistTheme.Colors.cardBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var standardCardBackground: some View {
        RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
            .fill(MoodistTheme.Colors.cardBackground.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.large, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private var nameFieldBackground: some View {
        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
            .fill(MoodistTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                    .strokeBorder(
                        isNameFocused ? MoodistTheme.Colors.accent.opacity(0.35) : Color.primary.opacity(0.10),
                        lineWidth: isNameFocused ? 1.2 : 1
                    )
            )
    }

    private func subtlePanelBackground(opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
            .fill(MoodistTheme.Colors.cardBackground.opacity(opacity))
            .overlay(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.medium, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    private func saveAndDismiss() {
        let name = trimmedMixName
        guard !name.isEmpty else { return }
        if let preset = presetBeingEdited {
            store.updatePresetMetadata(id: preset.id, name: name, iconName: currentIconOption.sfSymbolName)
        } else {
            store.saveCurrentAsPreset(name: name, iconName: currentIconOption.sfSymbolName)
        }
        onDismiss()
    }

    private func configureInitialFormStateIfNeeded() {
        guard !didInitializeForm else { return }

        if let preset = presetBeingEdited {
            mixName = preset.name
            selectedIconID = saveMixIconOptionsById[preset.iconName] != nil ? preset.iconName : saveMixDefaultIconID
        } else if saveMixIconOptionsById[selectedIconID] == nil {
            selectedIconID = saveMixDefaultIconID
        }

        didInitializeForm = true
        isNameFocused = true
    }
}
