//
//  ContentSections.swift
//  MoodistMac
//
//  Reusable section views extracted from ContentView.
//

import SwiftUI

struct CurrentlyPlayingSectionView: View {
    @ObservedObject var store: SoundStore
    let contentAreaWidth: CGFloat
    let playingSounds: [Sound]
    @Binding var isSaveMixHovered: Bool
    @Binding var isClearHovered: Bool
    let onSaveMix: () -> Void
    let onClear: () -> Void
    let onCancelTimer: () -> Void

    var body: some View {
        let title: String = {
            guard let mixName = store.displayedMixName else { return L10n.currentlyPlaying }
            if contentAreaWidth < 420 { return mixName }
            return "\(L10n.currentlyPlaying) / \(mixName)"
        }()
        let isNarrow = contentAreaWidth < 420
        let isVeryNarrow = contentAreaWidth < 340
        let isUltraNarrow = contentAreaWidth < 260
        let headerIconFrame: CGFloat = isNarrow ? 18 : 20
        let headerRowSpacing: CGFloat = isUltraNarrow ? 4 : (isVeryNarrow ? 6 : (isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium))
        let headerVerticalPadding: CGFloat = MoodistTheme.Spacing.xSmall
        let sectionHorizontalPadding: CGFloat = isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium

        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            HStack(spacing: headerRowSpacing) {
                Image(systemName: store.isPlaying ? "waveform" : "waveform.slash")
                    .font(.system(size: isNarrow ? 14 : 15, weight: .medium))
                    .frame(width: headerIconFrame, height: headerIconFrame)
                    .foregroundStyle(store.isPlaying ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                Text(title)
                    .font(isNarrow ? .headline : .title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                HStack(spacing: MoodistTheme.Spacing.small) {
                    if store.canSaveCustomMix {
                        Button(action: onSaveMix) {
                            if isVeryNarrow {
                                Label(L10n.addCustom, systemImage: "plus")
                                    .labelStyle(.iconOnly)
                            } else {
                                Label(L10n.addCustom, systemImage: "plus")
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                        .buttonStyle(HeaderActionButtonStyle(
                            isHovered: isSaveMixHovered,
                            isPrimary: true,
                            isCompact: isNarrow
                        ))
                        .onHover { isSaveMixHovered = $0 }
                        .help(L10n.presetSaveCurrent)
                        .accessibilityLabel(L10n.addCustom)
                    }
                    Button(action: onClear) {
                        if isVeryNarrow {
                            Label(L10n.clear, systemImage: "stop.fill")
                                .labelStyle(.iconOnly)
                        } else {
                            Label(L10n.clear, systemImage: "stop.fill")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .buttonStyle(HeaderActionButtonStyle(
                        isHovered: isClearHovered,
                        isPrimary: false,
                        isCompact: isNarrow
                    ))
                    .onHover { isClearHovered = $0 }
                    .disabled(!store.hasSelection)
                    .help(L10n.unselectAll)
                    .accessibilityLabel(L10n.clear)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, headerVerticalPadding)
            if store.hasActiveTimer {
                TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                    if let timer = store.activeTimer {
                        timerInlineRow(remainingSeconds: timer.remainingSeconds, onCancelTimer: onCancelTimer)
                    }
                }
            }
            if !playingSounds.isEmpty {
                LazyVStack(spacing: MoodistTheme.Spacing.small) {
                    ForEach(playingSounds, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
            } else {
                Text(L10n.noSoundsPlaying)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, MoodistTheme.Spacing.small)
            }
        }
        .padding(.horizontal, sectionHorizontalPadding)
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.currentlyPlaying)
    }

    private func timerInlineRow(remainingSeconds: Int, onCancelTimer: @escaping () -> Void) -> some View {
        let isNarrow = contentAreaWidth < 420
        let isVeryNarrow = contentAreaWidth < 340
        let isUltraNarrow = contentAreaWidth < 260
        let rowHorizontalPadding: CGFloat = isUltraNarrow ? 4 : (isVeryNarrow ? 6 : (isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium))
        let labelText = isVeryNarrow
            ? formatTimerRemaining(seconds: remainingSeconds)
            : "\(L10n.timer) · \(formatTimerRemaining(seconds: remainingSeconds))"

        return HStack(spacing: MoodistTheme.Spacing.small) {
            Image(systemName: "timer")
                .font(.system(size: isNarrow ? 12 : 13, weight: .medium))
            Text(labelText)
                .font(MoodistTheme.Typography.subheadline)
                .monospacedDigit()
            Spacer(minLength: 0)
            Button(action: onCancelTimer) {
                if isVeryNarrow {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                } else {
                    Label(L10n.timerStop, systemImage: "xmark")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(MoodistTheme.Colors.secondaryText)
            .background(
                Capsule()
                    .fill(MoodistTheme.Colors.cardBackground.opacity(0.6))
            )
            .help(L10n.timerStop)
            .accessibilityLabel(L10n.timerStop)
        }
        .foregroundStyle(MoodistTheme.Colors.secondaryText)
        .padding(.horizontal, rowHorizontalPadding)
        .padding(.vertical, isNarrow ? 6 : 8)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                .fill(MoodistTheme.Colors.selectedBackground.opacity(0.2))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.timerRemaining(formatTimerRemaining(seconds: remainingSeconds)))
    }

    private func formatTimerRemaining(seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }
}

struct CategoriesSectionView: View {
    @ObservedObject var store: SoundStore
    let contentAreaWidth: CGFloat
    @Binding var categoryExpandedStates: [String: Bool]
    let defaultExpandedState: Bool
    let allCategoriesExpanded: Bool
    @Binding var isCollapseAllHovered: Bool
    let toggleAllCategories: () -> Void

    var body: some View {
        let isNarrow = contentAreaWidth < 420
        let isVeryNarrow = contentAreaWidth < 340
        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            HStack(spacing: MoodistTheme.Spacing.small) {
                Spacer(minLength: 0)
                Button(action: toggleAllCategories) {
                    if isVeryNarrow {
                        Label(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories,
                              systemImage: allCategoriesExpanded ? "chevron.up.circle" : "chevron.down.circle")
                            .labelStyle(.iconOnly)
                    } else {
                        Label(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories,
                              systemImage: allCategoriesExpanded ? "chevron.up.circle" : "chevron.down.circle")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .buttonStyle(HeaderActionButtonStyle(
                    isHovered: isCollapseAllHovered,
                    isPrimary: false,
                    isCompact: isNarrow
                ))
                .onHover { isCollapseAllHovered = $0 }
                .help(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
                .accessibilityLabel(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
            }
            .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
                ForEach(SoundsData.categories, id: \.id) { category in
                    CategoryView(
                        category: category,
                        store: store,
                        isExpanded: Binding(
                            get: { categoryExpandedStates[category.id] ?? defaultExpandedState },
                            set: { categoryExpandedStates[category.id] = $0 }
                        )
                    )
                    .id("category-\(category.id)")
                }
            }
        }
        .onAppear {
            if categoryExpandedStates.isEmpty {
                for category in SoundsData.categories {
                    categoryExpandedStates[category.id] = defaultExpandedState
                }
            }
        }
    }
}

struct MixesPlaceholderSectionView: View {
    @ObservedObject var store: SoundStore
    let contentAreaWidth: CGFloat
    @Binding var mixCategoryExpandedStates: [String: Bool]
    let defaultMixExpandedState: (String) -> Bool
    let allMixCategoriesExpanded: Bool
    @Binding var isCollapseAllMixesHovered: Bool
    let toggleAllMixCategories: () -> Void

    var body: some View {
        let isNarrow = contentAreaWidth < 420
        let isVeryNarrow = contentAreaWidth < 340
        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
            MixCategoryView(
                category: MixesData.custom,
                store: store,
                mixesToShow: store.presets.map { $0.toMix() },
                isExpanded: Binding(
                    get: { mixCategoryExpandedStates[MixesData.custom.id] ?? defaultMixExpandedState(MixesData.custom.id) },
                    set: { mixCategoryExpandedStates[MixesData.custom.id] = $0 }
                )
            )
            .id("mix-category-\(MixesData.custom.id)")

            HStack(spacing: MoodistTheme.Spacing.small) {
                Spacer(minLength: 0)
                Button(action: toggleAllMixCategories) {
                    if isVeryNarrow {
                        Label(allMixCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories,
                              systemImage: allMixCategoriesExpanded ? "chevron.up.circle" : "chevron.down.circle")
                            .labelStyle(.iconOnly)
                    } else {
                        Label(allMixCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories,
                              systemImage: allMixCategoriesExpanded ? "chevron.up.circle" : "chevron.down.circle")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .buttonStyle(HeaderActionButtonStyle(
                    isHovered: isCollapseAllMixesHovered,
                    isPrimary: false,
                    isCompact: isNarrow
                ))
                .onHover { isCollapseAllMixesHovered = $0 }
                .help(allMixCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
                .accessibilityLabel(allMixCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
            }
            .padding(.horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
                ForEach(MixesData.categories.filter { $0.id != MixesData.custom.id }, id: \.id) { category in
                    MixCategoryView(
                        category: category,
                        store: store,
                        mixesToShow: nil,
                        isExpanded: Binding(
                            get: { mixCategoryExpandedStates[category.id] ?? defaultMixExpandedState(category.id) },
                            set: { mixCategoryExpandedStates[category.id] = $0 }
                        )
                    )
                    .id("mix-category-\(category.id)")
                }
            }
        }
        .onAppear {
            if mixCategoryExpandedStates.isEmpty {
                for category in MixesData.categories {
                    mixCategoryExpandedStates[category.id] = defaultMixExpandedState(category.id)
                }
            }
        }
    }
}

struct MixesSearchResultsSectionView: View {
    @ObservedObject var store: SoundStore

    var body: some View {
        let query = store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let customMixes = store.presets.map { $0.toMix() }
        let filtered: [(MixCategory, [Mix])] = MixesData.categories.compactMap { category in
            let categoryTitle = L10n.mixCategoryTitle(category.id)
            let categoryMatches = categoryTitle.localizedStandardContains(query)
            let mixesSource = category.id == MixesData.custom.id ? customMixes : category.mixes
            let matching = mixesSource.filter { mix in
                let displayName = (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id)
                return query.isEmpty || displayName.localizedStandardContains(query) || categoryMatches
            }
            if matching.isEmpty { return nil }
            return (category, matching)
        }

        return Group {
            if filtered.isEmpty {
                VStack(spacing: MoodistTheme.Spacing.medium) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    Text(L10n.searchPlaceholder)
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoodistTheme.Spacing.xLarge)
            } else {
                VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
                    ForEach(filtered, id: \.0.id) { category, mixes in
                        MixCategoryView(category: category, store: store, mixesToShow: mixes)
                            .id("mix-search-\(category.id)")
                    }
                }
            }
        }
    }
}

struct SoundsSearchResultsSectionView: View {
    @ObservedObject var store: SoundStore
    let contentAreaWidth: CGFloat

    var body: some View {
        let query = store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered: [(SoundCategory, [Sound])] = SoundsData.categories.compactMap { category in
            let categoryTitle = L10n.categoryTitle(category.id)
            let categoryMatches = categoryTitle.localizedStandardContains(query)
            let matching = category.sounds.filter { sound in
                query.isEmpty || L10n.soundLabel(sound.id).localizedStandardContains(query) || categoryMatches
            }
            if matching.isEmpty { return nil }
            return (category, matching)
        }

        return Group {
            if filtered.isEmpty {
                VStack(spacing: MoodistTheme.Spacing.medium) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    Text(L10n.searchPlaceholder)
                        .font(MoodistTheme.Typography.subheadline)
                        .foregroundStyle(MoodistTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, MoodistTheme.Spacing.xLarge)
            } else {
                VStack(alignment: .leading, spacing: MoodistTheme.Spacing.large) {
                    ForEach(filtered, id: \.0.id) { category, sounds in
                        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                            HStack(spacing: MoodistTheme.Spacing.xSmall) {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(MoodistTheme.Colors.accent)
                                Text(L10n.categoryTitle(category.id))
                                    .font(.title2.weight(.semibold))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .minimumScaleFactor(0.9)
                                    .layoutPriority(1)
                            }
                            LazyVStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                                ForEach(sounds, id: \.id) { sound in
                                    SoundRow(sound: sound, store: store)
                                }
                            }
                        }
                        .padding(.vertical, MoodistTheme.Spacing.small)
                        .padding(.horizontal, contentAreaWidth < 420 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                        .id("search-category-\(category.id)")
                    }
                }
            }
        }
    }
}
