//
//  MixCategoryView.swift
//  MoodistMac
//
//  Mix category view with title, icon, and mix list. Tapping a mix applies and plays it.
//

import SwiftUI

struct MixCategoryView: View {
    let category: MixCategory
    @ObservedObject var store: SoundStore
    @Environment(\.contentAreaWidth) private var contentAreaWidth
    /// When non-nil, shows only these mixes, for example search results. Otherwise uses category.mixes.
    var mixesToShow: [Mix]? = nil
    /// Optional binding for controlling expanded state externally. Nil uses internal state.
    var isExpanded: Binding<Bool>? = nil
    /// Optional view on the right side of the header title, such as an "Expand all" button.
    var headerTrailing: AnyView? = nil
    @State private var internalIsExpanded = true
    
    private var expandedState: Bool {
        isExpanded?.wrappedValue ?? internalIsExpanded
    }
    
    private func setExpandedState(_ value: Bool) {
        if let binding = isExpanded {
            binding.wrappedValue = value
        } else {
            internalIsExpanded = value
        }
    }

    private var displayedMixes: [Mix] {
        mixesToShow ?? category.mixes
    }

    private var isNarrow: Bool { contentAreaWidth < 420 }
    private var customHeaderMinHeight: CGFloat? {
        category.id == MixesData.custom.id ? (isNarrow ? 28 : 30) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) { 
                    setExpandedState(!expandedState)
                }
            }) {
                HStack(spacing: isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium) {
                    Image(systemName: category.iconName)
                        .font(isNarrow ? .body : .title3)
                        .frame(width: isNarrow ? 24 : 28, height: isNarrow ? 24 : 28)
                        .foregroundStyle(MoodistTheme.Colors.accent)
                    Text(L10n.mixCategoryTitle(category.id))
                        .font((isNarrow ? Font.headline : Font.title2).weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                    if let trailing = headerTrailing {
                        trailing
                    }
                    Image(systemName: expandedState ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                .padding(.vertical, MoodistTheme.Spacing.xSmall)
                .frame(minHeight: customHeaderMinHeight, alignment: .center)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(L10n.mixCategoryTitle(category.id)), \(expandedState ? L10n.stateExpanded : L10n.stateCollapsed)")

            if expandedState {
                if displayedMixes.isEmpty, category.id == MixesData.custom.id {
                    Text(L10n.customMixesEmpty)
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, MoodistTheme.Spacing.small)
                } else {
                    LazyVStack(alignment: .leading, spacing: isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small) {
                        ForEach(displayedMixes, id: \.id) { mix in
                            MixRowView(mix: mix, store: store)
                        }
                    }
                }
            }
        }
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small)
        .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
    }
}

struct MixRowView: View {
    let mix: Mix
    @ObservedObject var store: SoundStore
    @Environment(\.contentAreaWidth) private var contentAreaWidth
    @Environment(\.isUserScrolling) private var isUserScrolling
    @State private var isHovered = false
    
    // Static cache to avoid recalculating soundsInMix on every render, main thread only.
    private static var soundsCache: [String: [Sound]] = [:]

    private var isCurrentMix: Bool {
        store.currentMixId == mix.id
    }

    private var isFavoriteMix: Bool {
        store.favoriteMixIds.contains(mix.id)
    }

    /// Display name: built-in mixes use L10n, while custom presets use mix.name.
    private var mixDisplayName: String {
        (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id)
    }

    private static let soundsCacheMaxEntries = 200

    private var soundsCacheKey: String {
        "\(mix.id)|\(mix.soundIds.joined(separator: ","))"
    }

    private var soundsInMix: [Sound] {
        let key = soundsCacheKey
        if let cached = Self.soundsCache[key] {
            return cached
        }
        if Self.soundsCache.count >= Self.soundsCacheMaxEntries, let keyToEvict = Self.soundsCache.keys.first {
            Self.soundsCache.removeValue(forKey: keyToEvict)
        }
        let sounds = mix.soundIds.compactMap { SoundsData.allSoundsById[$0] }
        Self.soundsCache[key] = sounds
        return sounds
    }

    private var isNarrow: Bool { contentAreaWidth < 420 }
    private var isVeryNarrow: Bool { contentAreaWidth < 340 }

    var body: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xSmall) {
            HStack(spacing: isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium) {
                MixIconImage(
                    iconName: mix.iconName,
                    size: isNarrow ? 14 : 15,
                    frame: isNarrow ? 18 : 20,
                    weight: isCurrentMix ? .medium : .regular,
                    color: isCurrentMix ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
                )
                Text(mixDisplayName)
                    .font(MoodistTheme.Typography.body)
                    .fontWeight(isCurrentMix ? .medium : .regular)
                    .foregroundStyle(isCurrentMix ? Color.primary : Color.primary.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.toggleFavoriteMix(id: mix.id)
                    }
                }) {
                    Image(systemName: isFavoriteMix ? "star.fill" : "star")
                        .font(.system(size: isNarrow ? 12 : 14, weight: isFavoriteMix ? .medium : .regular))
                        .foregroundStyle(isFavoriteMix ? MoodistTheme.Colors.favorite : (isHovered ? MoodistTheme.Colors.secondaryText.opacity(0.8) : MoodistTheme.Colors.secondaryText.opacity(0.5)))
                        .frame(width: isNarrow ? 18 : 20, height: isNarrow ? 18 : 20)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavoriteMix ? L10n.removeFromFavoritesLabel(mixDisplayName) : L10n.addToFavoritesLabel(mixDisplayName))
                if isCurrentMix {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                if !isVeryNarrow {
                    Text(L10n.countSounds(mix.soundIds.count))
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.vertical, isNarrow ? MoodistTheme.Spacing.small : (MoodistTheme.Spacing.small + 2))
            .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                    .fill(rowBackgroundColor)
            )
            .onTapGesture {
                store.applyMix(mix)
            }
            .onHover { hovering in
                if isUserScrolling && hovering {
                    return
                }
                guard isHovered != hovering else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .contextMenu {
                Button(L10n.presetApply) {
                    store.applyMix(mix)
                }
                Divider()
                if isFavoriteMix {
                    Button(L10n.removeFromFavoritesLabel(mixDisplayName)) {
                        store.toggleFavoriteMix(id: mix.id)
                    }
                } else {
                    Button(L10n.addToFavoritesLabel(mixDisplayName)) {
                        store.toggleFavoriteMix(id: mix.id)
                    }
                }
                if store.presets.contains(where: { $0.id == mix.id }) {
                    Divider()
                    Button(L10n.editMix) {
                        store.beginEditingPreset(id: mix.id)
                    }
                    Button(L10n.presetDelete, role: .destructive) {
                        store.deletePreset(id: mix.id)
                    }
                }
            }
            .accessibilityLabel("\(mixDisplayName), \(L10n.countSounds(mix.soundIds.count))")
            .accessibilityHint(L10n.doubleTapPlayMix)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { store.applyMix(mix) }

            if isCurrentMix {
                LazyVStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                    ForEach(soundsInMix, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
                .padding(.leading, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                .padding(.trailing, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                .padding(.vertical, MoodistTheme.Spacing.small)
            }
        }
    }

    private var rowBackgroundColor: Color {
        if isCurrentMix {
            return MoodistTheme.Colors.selectedBackground.opacity(0.25)
        }
        if isHovered {
            return Color.primary.opacity(0.05)
        }
        return Color.clear
    }
}

#Preview {
    MixCategoryView(category: MixesData.natureRelaxation, store: SoundStore(audioService: AudioService()))
        .padding()
}
