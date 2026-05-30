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
    @Binding var isPomodoroHovered: Bool
    @Binding var isPomodoroXHovered: Bool
    @Binding var isClearHovered: Bool
    @Binding var isTimerHovered: Bool
    @Binding var isTimerCancelHovered: Bool
    let onSaveMix: () -> Void
    let onClear: () -> Void
    let onOpenTimer: () -> Void
    let onCancelTimer: () -> Void

    var body: some View {
        // Contextual title: shows the mix name when it exists and width allows.
        let title: String = {
            guard let mixName = store.displayedMixName else { return L10n.currentlyPlaying }
            if contentAreaWidth < 420 { return mixName }
            return "\(L10n.currentlyPlaying) / \(mixName)"
        }()
        let isNarrow = contentAreaWidth < 420
        let isVeryNarrow = contentAreaWidth < 340
        let isUltraNarrow = contentAreaWidth < 260
        let headerIconFrame: CGFloat = isNarrow ? 18 : 20
        let headerRowSpacing: CGFloat =
            isUltraNarrow
            ? 4
            : (isVeryNarrow
                ? 6 : (isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium))
        let headerVerticalPadding: CGFloat = MoodistTheme.Spacing.xSmall
        let sectionHorizontalPadding: CGFloat =
            isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium

        // Main block: controls header plus the active sound list.
        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            HStack(spacing: headerRowSpacing) {
                Image(systemName: store.isPlaying ? "waveform" : "waveform.slash")
                    .font(.system(size: isNarrow ? 14 : 15, weight: .medium))
                    .frame(width: headerIconFrame, height: headerIconFrame)
                    .foregroundStyle(
                        store.isPlaying
                            ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
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
                        .buttonStyle(
                            HeaderActionButtonStyle(
                                isHovered: isSaveMixHovered,
                                isPrimary: true,
                                isCompact: isNarrow
                            )
                        )
                        .onHover { isSaveMixHovered = $0 }
                        .help(L10n.presetSaveCurrent)
                        .accessibilityLabel(L10n.addCustom)
                    }
                    pomodoroHeaderButton(isNarrow: isNarrow, isVeryNarrow: isVeryNarrow)
                    Button(action: onClear) {
                        if isVeryNarrow {
                            Label(L10n.clear, systemImage: "stop.fill")
                                .labelStyle(.iconOnly)
                        } else {
                            Label(L10n.clear, systemImage: "stop.fill")
                                .labelStyle(.titleAndIcon)
                        }
                    }
                    .buttonStyle(
                        HeaderActionButtonStyle(
                            isHovered: isClearHovered,
                            isPrimary: false,
                            isCompact: isNarrow
                        )
                    )
                    .onHover { isClearHovered = $0 }
                    .disabled(!store.hasSelection)
                    .help(L10n.unselectAll)
                    .accessibilityLabel(L10n.clear)
                    timerHeaderButton(isNarrow: isNarrow, isVeryNarrow: isVeryNarrow)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, headerVerticalPadding)
            if !playingSounds.isEmpty {
                // Cached list to avoid recalculating on every timer tick.
                LazyVStack(spacing: MoodistTheme.Spacing.small) {
                    ForEach(playingSounds, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
            } else {
                // Empty state when no sounds are playing.
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

    @ViewBuilder
    private func pomodoroHeaderButton(isNarrow: Bool, isVeryNarrow: Bool) -> some View {
        HStack(spacing: 6) {
            Menu {
                Picker(L10n.automixRotate, selection: $store.autoMixCustomOnly) {
                    Text(L10n.automixAllMixes).tag(false)
                    Text(L10n.automixOnlyCustom).tag(true)
                }
                Divider()
                ForEach(SoundStore.autoMixIntervalPresets, id: \.self) { seconds in
                    Button(store.autoMixIntervalLabel(forSeconds: seconds)) {
                        store.startAutoMixTimer(intervalSeconds: seconds)
                    }
                }
                if store.hasActiveAutoMixTimer {
                    Divider()
                    Button(L10n.timerStop, role: .destructive) {
                        store.cancelAutoMixTimer()
                    }
                }
            } label: {
                if store.hasActiveAutoMixTimer && isVeryNarrow {
                    Label {
                        TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                            let secs = max(
                                0,
                                Int(
                                    (store.autoMixNextFireDate ?? Date())
                                        .timeIntervalSinceNow))
                            Text(formatTimerRemaining(seconds: secs))
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.linear(duration: 0.3), value: secs)
                        }
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .labelStyle(.iconOnly)
                } else if store.hasActiveAutoMixTimer {
                    Label {
                        TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                            let secs = max(
                                0,
                                Int(
                                    (store.autoMixNextFireDate ?? Date())
                                        .timeIntervalSinceNow))
                            Text(formatTimerRemaining(seconds: secs))
                                .monospacedDigit()
                                .contentTransition(.numericText(countsDown: true))
                                .animation(.linear(duration: 0.3), value: secs)
                        }
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    .labelStyle(.titleAndIcon)
                } else if isVeryNarrow {
                    Label(L10n.automixLabel, systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(.iconOnly)
                } else {
                    Label(L10n.automixLabel, systemImage: "arrow.triangle.2.circlepath")
                        .labelStyle(.titleAndIcon)
                }
            }
            .buttonStyle(
                HeaderActionButtonStyle(
                    isHovered: isPomodoroHovered,
                    isPrimary: store.hasActiveAutoMixTimer,
                    isCompact: isNarrow
                )
            )
            .onHover { isPomodoroHovered = $0 }
            .help(
                store.hasActiveAutoMixTimer
                    ? L10n.automixHelpActive(
                        store.timerLabel(forSeconds: store.autoMixIntervalSeconds ?? 0))
                    : L10n.automixHelpIdle
            )
            .accessibilityLabel(L10n.automixLabel)

            if store.hasActiveAutoMixTimer {
                Button(action: { store.cancelAutoMixTimer() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: isNarrow ? 10 : 11, weight: .semibold))
                        .frame(width: isNarrow ? 20 : 22, height: isNarrow ? 20 : 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
                .background(
                    Capsule()
                        .fill(
                            isPomodoroXHovered
                                ? MoodistTheme.Colors.cardBackground.opacity(0.75)
                                : MoodistTheme.Colors.cardBackground.opacity(0.45)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.primary.opacity(isPomodoroXHovered ? 0.16 : 0.1), lineWidth: 1)
                )
                .onHover { isPomodoroXHovered = $0 }
                .help(L10n.timerStop)
                .accessibilityLabel(L10n.timerStop)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .scale(scale: 0.6))
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
            }
        }
        .animation(
            .spring(response: 0.35, dampingFraction: 0.75), value: store.hasActiveAutoMixTimer)
    }

    @ViewBuilder
    private func timerHeaderButton(isNarrow: Bool, isVeryNarrow: Bool) -> some View {
        // Timer control: open the window plus quick cancellation.
        HStack(spacing: 6) {
            Button(action: onOpenTimer) {
                timerHeaderButtonLabel(isVeryNarrow: isVeryNarrow)
            }
            .buttonStyle(
                HeaderActionButtonStyle(
                    isHovered: isTimerHovered,
                    isPrimary: false,
                    isCompact: isNarrow
                )
            )
            .onHover { isTimerHovered = $0 }
            .help(
                store.hasActiveTimer
                    ? (store.timerRemainingMenuTitle ?? L10n.timer) : L10n.timerCustomTitle
            )
            .accessibilityLabel(store.hasActiveTimer ? L10n.timer : L10n.timerCustomTitle)

            if store.hasActiveTimer {
                // "X" button stops the timer without opening the setup window.
                Button(action: onCancelTimer) {
                    Image(systemName: "xmark")
                        .font(.system(size: isNarrow ? 10 : 11, weight: .semibold))
                        .frame(width: isNarrow ? 20 : 22, height: isNarrow ? 20 : 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MoodistTheme.Colors.secondaryText)
                .background(
                    Capsule()
                        .fill(
                            (isTimerCancelHovered
                                ? MoodistTheme.Colors.cardBackground.opacity(0.75)
                                : MoodistTheme.Colors.cardBackground.opacity(0.45))
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.primary.opacity(isTimerCancelHovered ? 0.16 : 0.1), lineWidth: 1)
                )
                .onHover { isTimerCancelHovered = $0 }
                .help(L10n.timerStop)
                .accessibilityLabel(L10n.timerStop)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .leading).combined(with: .scale(scale: 0.6))
                            .combined(with: .opacity),
                        removal: .scale(scale: 0.6).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: store.hasActiveTimer)
    }

    @ViewBuilder
    private func timerHeaderButtonLabel(isVeryNarrow: Bool) -> some View {
        if store.hasActiveTimer {
            // Live countdown with monospaced digits for visual stability.
            Label {
                TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                    let secs = store.activeTimer?.remainingSeconds ?? 0
                    Text(formatTimerRemaining(seconds: secs))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.linear(duration: 0.3), value: secs)
                }
            } icon: {
                Image(systemName: "timer")
            }
            .labelStyle(.titleAndIcon)
        } else if isVeryNarrow {
            Label(L10n.timer, systemImage: "timer")
                .labelStyle(.iconOnly)
        } else {
            Label(L10n.timer, systemImage: "timer")
                .labelStyle(.titleAndIcon)
        }
    }

    private func formatTimerRemaining(seconds: Int) -> String {
        // Compact format: h:mm:ss or m:ss depending on remaining duration.
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
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
        // Sound categories section with a global expand/collapse action.
        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            HStack(spacing: MoodistTheme.Spacing.small) {
                Spacer(minLength: 0)
                Button(action: toggleAllCategories) {
                    if isVeryNarrow {
                        Label(
                            allCategoriesExpanded
                                ? L10n.collapseAllCategories : L10n.expandAllCategories,
                            systemImage: allCategoriesExpanded
                                ? "chevron.up.circle" : "chevron.down.circle"
                        )
                        .labelStyle(.iconOnly)
                    } else {
                        Label(
                            allCategoriesExpanded
                                ? L10n.collapseAllCategories : L10n.expandAllCategories,
                            systemImage: allCategoriesExpanded
                                ? "chevron.up.circle" : "chevron.down.circle"
                        )
                        .labelStyle(.titleAndIcon)
                    }
                }
                .buttonStyle(
                    HeaderActionButtonStyle(
                        isHovered: isCollapseAllHovered,
                        isPrimary: false,
                        isCompact: isNarrow
                    )
                )
                .onHover { isCollapseAllHovered = $0 }
                .help(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
                .accessibilityLabel(
                    allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
            }
            .padding(
                .horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
                // Expanded state per category using an ID-keyed dictionary.
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
            // Initialize states only during the first view load.
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
        // Mixes section: custom block plus standard categories with a global control.
        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
            MixCategoryView(
                category: MixesData.custom,
                store: store,
                mixesToShow: store.presets.map { $0.toMix() },
                isExpanded: Binding(
                    get: {
                        mixCategoryExpandedStates[MixesData.custom.id]
                            ?? defaultMixExpandedState(MixesData.custom.id)
                    },
                    set: { mixCategoryExpandedStates[MixesData.custom.id] = $0 }
                )
            )
            .id("mix-category-\(MixesData.custom.id)")

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                HStack(spacing: MoodistTheme.Spacing.small) {
                    Spacer(minLength: 0)
                    Button(action: toggleAllMixCategories) {
                        if isVeryNarrow {
                            Label(
                                allMixCategoriesExpanded
                                    ? L10n.collapseAllCategories : L10n.expandAllCategories,
                                systemImage: allMixCategoriesExpanded
                                    ? "chevron.up.circle" : "chevron.down.circle"
                            )
                            .labelStyle(.iconOnly)
                        } else {
                            Label(
                                allMixCategoriesExpanded
                                    ? L10n.collapseAllCategories : L10n.expandAllCategories,
                                systemImage: allMixCategoriesExpanded
                                    ? "chevron.up.circle" : "chevron.down.circle"
                            )
                            .labelStyle(.titleAndIcon)
                        }
                    }
                    .buttonStyle(
                        HeaderActionButtonStyle(
                            isHovered: isCollapseAllMixesHovered,
                            isPrimary: false,
                            isCompact: isNarrow
                        )
                    )
                    .onHover { isCollapseAllMixesHovered = $0 }
                    .help(
                        allMixCategoriesExpanded
                            ? L10n.collapseAllCategories : L10n.expandAllCategories
                    )
                    .accessibilityLabel(
                        allMixCategoriesExpanded
                            ? L10n.collapseAllCategories : L10n.expandAllCategories)
                }
                .padding(
                    .horizontal, isNarrow ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium
                )

                VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
                    // Exclude custom to avoid duplicating the user's preset category.
                    ForEach(MixesData.categories.filter { $0.id != MixesData.custom.id }, id: \.id)
                    { category in
                        MixCategoryView(
                            category: category,
                            store: store,
                            mixesToShow: nil,
                            isExpanded: Binding(
                                get: {
                                    mixCategoryExpandedStates[category.id]
                                        ?? defaultMixExpandedState(category.id)
                                },
                                set: { mixCategoryExpandedStates[category.id] = $0 }
                            )
                        )
                        .id("mix-category-\(category.id)")
                    }
                }
            }
        }
        .onAppear {
            // Initialize the mix expansion map once.
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
        // Filter by mix or category name, including custom mixes.
        let filtered: [(MixCategory, [Mix])] = MixesData.categories.compactMap { category in
            let categoryTitle = L10n.mixCategoryTitle(category.id)
            let categoryMatches = categoryTitle.localizedStandardContains(query)
            let mixesSource = category.id == MixesData.custom.id ? customMixes : category.mixes
            let matching = mixesSource.filter { mix in
                let displayName = (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id)
                return query.isEmpty || displayName.localizedStandardContains(query)
                    || categoryMatches
            }
            if matching.isEmpty { return nil }
            return (category, matching)
        }

        return Group {
            if filtered.isEmpty {
                // Empty state when the search has no results.
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
                // Results grouped by category to preserve visual hierarchy.
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
        // Filter sounds by label or matching category name.
        let filtered: [(SoundCategory, [Sound])] = SoundsData.categories.compactMap { category in
            let categoryTitle = L10n.categoryTitle(category.id)
            let categoryMatches = categoryTitle.localizedStandardContains(query)
            let matching = category.sounds.filter { sound in
                query.isEmpty || L10n.soundLabel(sound.id).localizedStandardContains(query)
                    || categoryMatches
            }
            if matching.isEmpty { return nil }
            return (category, matching)
        }

        return Group {
            if filtered.isEmpty {
                // Empty search state for sounds.
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
                // Sound results grouped by category.
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
                        .padding(
                            .horizontal,
                            contentAreaWidth < 420
                                ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium
                        )
                        .id("search-category-\(category.id)")
                    }
                }
            }
        }
    }
}

struct ContentScrollPanelView<SectionContent: View>: View {
    let section: ContentSection
    let selectedSection: ContentSection
    let contentAreaWidth: CGFloat
    let topPadding: CGFloat
    let scrollTopAnchorId: String
    @Binding var scrollPosition: String?
    @Binding var isUserScrolling: Bool
    let searchQuery: String
    let onScrollAnchorChanged: (String) -> Void
    let onSearchQueryChanged: (String, String) -> Void
    let onFirstAppear: () -> Void
    @ViewBuilder let sections: () -> SectionContent

    var body: some View {
        // Reusable scroll container with position memory and search hooks.
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: contentAreaWidth < 400
                    ? MoodistTheme.Spacing.medium : MoodistTheme.Spacing.xLarge
            ) {
                Color.clear
                    .frame(height: 1)
                    .id(scrollTopAnchorId)
                sections()
            }
            .padding(
                .horizontal,
                contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large
            )
            .padding(.top, topPadding)
            .padding(
                .bottom,
                (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large)
                    + 88
            )
        }
        .scrollPosition(id: $scrollPosition, anchor: .top)
        .onScrollPhaseChange { _, phase in
            // Mark scrolling only for the visible section.
            guard selectedSection == section else { return }
            isUserScrolling = phase != .idle
        }
        .onChange(of: scrollPosition) { _, newValue in
            guard let newValue else { return }
            // Delegate persistence and validation to the caller.
            onScrollAnchorChanged(newValue)
        }
        .onChange(of: searchQuery) { oldValue, newValue in
            onSearchQueryChanged(oldValue, newValue)
        }
        .onAppear(perform: onFirstAppear)
    }
}

struct HeaderActionButtonStyle: ButtonStyle {
    let isHovered: Bool
    let isPrimary: Bool
    let isCompact: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        // Shared capsule style for header actions.
        configuration.label
            .font(.system(size: isCompact ? 12 : 13, weight: .medium))
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 4 : 5)
            .foregroundStyle(foregroundColor)
            .background(
                Capsule().fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule().strokeBorder(
                    borderColor(isPressed: configuration.isPressed), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
            .opacity(isEnabled ? 1 : 0.45)
    }

    private var foregroundColor: Color {
        if !isEnabled {
            return MoodistTheme.Colors.secondaryText.opacity(0.8)
        }
        return isPrimary ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        // Visual states: disabled, pressed, hover, and idle.
        if !isEnabled {
            return MoodistTheme.Colors.cardBackground.opacity(0.25)
        }
        if isPressed {
            return MoodistTheme.Colors.cardBackground.opacity(0.9)
        }
        if isHovered {
            return MoodistTheme.Colors.cardBackground.opacity(0.7)
        }
        return MoodistTheme.Colors.cardBackground.opacity(0.4)
    }

    private func borderColor(isPressed: Bool) -> Color {
        // Additional visual emphasis for primary buttons.
        if !isEnabled {
            return Color.primary.opacity(0.08)
        }
        if isPrimary {
            return MoodistTheme.Colors.accent.opacity(isPressed ? 0.5 : (isHovered ? 0.4 : 0.25))
        }
        return Color.primary.opacity(isPressed ? 0.22 : (isHovered ? 0.16 : 0.1))
    }
}
