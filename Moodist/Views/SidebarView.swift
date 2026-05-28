//
//  SidebarView.swift
//  MoodistMac
//
//  Clean sidebar style with a light background, soft typography, and right-aligned metadata.
//

import SwiftUI

// MARK: - Style Constants

private enum SidebarStyle {
    static let headerFont = Font.system(.subheadline, design: .default).weight(.medium)
    static let headerColor = Color.primary.opacity(0.55)
    static let rowPaddingH: CGFloat = 14
    static let rowPaddingV: CGFloat = 3
    static let rowSpacing: CGFloat = 4
    static let sectionSpacing: CGFloat = 10
    static let iconSize: CGFloat = 14
    static let primaryText = Color.primary.opacity(0.9)
    static let secondaryText = Color.primary.opacity(0.45)
    static let sidebarInset: CGFloat = 8
    /// Top reserved height so scroll content does not overlap the traffic lights.
    static let titleBarReservedHeight: CGFloat = 52
}

private let sidebarSectionIds = (
    favorites: "favorites", recentSounds: "recentSounds", favoriteMixes: "favoriteMixes",
    recentMixes: "recentMixes"
)

struct SidebarView: View {
    @EnvironmentObject var store: SoundStore
    @State private var sectionsCollapsed: [String: Bool] =
        PersistenceService.loadSidebarSectionsCollapsed()
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    @State private var soundDropTargetId: String? = nil
    @State private var mixDropTargetId: String? = nil

    /// Favorite sounds in user-defined order, allowing drag and drop.
    private var orderedFavoriteSounds: [Sound] {
        store.orderedFavoriteSoundIds.compactMap { SoundsData.allSoundsById[$0] }
    }

    private func isSectionCollapsed(_ id: String) -> Bool {
        sectionsCollapsed[id] ?? false
    }

    private func toggleSection(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            sectionsCollapsed[id] = !(sectionsCollapsed[id] ?? false)
            PersistenceService.saveSidebarSectionsCollapsed(sectionsCollapsed)
        }
    }

    private var recentMixes: [Mix] {
        let byId = store.presetsById
        return store.recentMixIds.compactMap { id in
            MixesData.allMixesById[id] ?? byId[id]?.toMix()
        }
    }

    private var recentSounds: [Sound] {
        store.recentSoundIds.compactMap { SoundsData.allSoundsById[$0] }
    }

    private var favoriteMixes: [Mix] {
        let byId = store.presetsById
        return store.favoriteMixIds.compactMap { id in
            MixesData.allMixesById[id] ?? byId[id]?.toMix()
        }
    }

    var body: some View {
        ZStack {
            // Opaque background covering the full sidebar, including the scroller area.
            sidebarBackground

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: SidebarStyle.sectionSpacing) {
                        // Favorites section, reorderable with drag and drop.
                        sidebarSectionHeader(
                            L10n.sidebarFavorites, sectionId: sidebarSectionIds.favorites)
                        if !isSectionCollapsed(sidebarSectionIds.favorites) {
                            if orderedFavoriteSounds.isEmpty {
                                sidebarPlaceholder(L10n.sidebarFavoritesEmpty)
                            } else {
                                VStack(spacing: 1) {
                                    ForEach(orderedFavoriteSounds, id: \.id) { sound in
                                        SidebarSoundRow(sound: sound, store: store)
                                            .draggable(sound.id)
                                            .dropDestination(for: String.self) { droppedIds, _ in
                                                guard let draggedId = droppedIds.first,
                                                    draggedId != sound.id,
                                                    store.orderedFavoriteSoundIds.contains(
                                                        draggedId)
                                                else { return false }
                                                var ordered = store.orderedFavoriteSoundIds
                                                guard let from = ordered.firstIndex(of: draggedId)
                                                else { return false }
                                                ordered.remove(at: from)
                                                guard let to = ordered.firstIndex(of: sound.id)
                                                else { return false }
                                                ordered.insert(draggedId, at: to)
                                                store.favoriteSoundIds = ordered
                                                return true
                                            } isTargeted: { isTargeted in
                                                if isTargeted {
                                                    soundDropTargetId = sound.id
                                                } else if soundDropTargetId == sound.id {
                                                    soundDropTargetId = nil
                                                }
                                            }
                                            .overlay(alignment: .top) {
                                                insertionLine
                                                    .opacity(soundDropTargetId == sound.id ? 1 : 0)
                                                    .animation(
                                                        .easeInOut(duration: 0.12),
                                                        value: soundDropTargetId == sound.id)
                                            }
                                            .id("sidebar-favorite-sound-\(sound.id)")
                                    }
                                }
                                .animation(
                                    .spring(response: 0.3, dampingFraction: 0.8),
                                    value: orderedFavoriteSounds.map(\.id))
                            }
                        }

                        // Favorite mixes section, reorderable with drag and drop.
                        sidebarSectionHeader(
                            L10n.sidebarFavoriteMixes, sectionId: sidebarSectionIds.favoriteMixes)
                        if !isSectionCollapsed(sidebarSectionIds.favoriteMixes) {
                            if favoriteMixes.isEmpty {
                                sidebarPlaceholder(L10n.sidebarFavoriteMixesEmpty)
                            } else {
                                VStack(spacing: 1) {
                                    ForEach(favoriteMixes, id: \.id) { mix in
                                        SidebarMixRow(mix: mix, store: store)
                                            .draggable(mix.id)
                                            .dropDestination(for: String.self) { droppedIds, _ in
                                                guard let draggedId = droppedIds.first,
                                                    draggedId != mix.id,
                                                    store.favoriteMixIds.contains(draggedId)
                                                else { return false }
                                                var ordered = store.favoriteMixIds
                                                guard let from = ordered.firstIndex(of: draggedId)
                                                else { return false }
                                                ordered.remove(at: from)
                                                guard let to = ordered.firstIndex(of: mix.id) else {
                                                    return false
                                                }
                                                ordered.insert(draggedId, at: to)
                                                store.favoriteMixIds = ordered
                                                return true
                                            } isTargeted: { isTargeted in
                                                if isTargeted {
                                                    mixDropTargetId = mix.id
                                                } else if mixDropTargetId == mix.id {
                                                    mixDropTargetId = nil
                                                }
                                            }
                                            .overlay(alignment: .top) {
                                                insertionLine
                                                    .opacity(mixDropTargetId == mix.id ? 1 : 0)
                                                    .animation(
                                                        .easeInOut(duration: 0.12),
                                                        value: mixDropTargetId == mix.id)
                                            }
                                            .id("sidebar-favorite-mix-\(mix.id)")
                                    }
                                }
                                .animation(
                                    .spring(response: 0.3, dampingFraction: 0.8),
                                    value: favoriteMixes.map(\.id))
                            }
                        }

                        // Recent sounds section.
                        sidebarSectionHeader(
                            L10n.sidebarRecentSounds, sectionId: sidebarSectionIds.recentSounds)
                        if !isSectionCollapsed(sidebarSectionIds.recentSounds) {
                            if recentSounds.isEmpty {
                                sidebarPlaceholder(L10n.sidebarRecentSoundsEmpty)
                            } else {
                                LazyVStack(spacing: 1) {
                                    ForEach(recentSounds, id: \.id) { sound in
                                        SidebarSoundRow(sound: sound, store: store)
                                            .contextMenu {
                                                Button(
                                                    L10n.addToFavoritesLabel(
                                                        L10n.soundLabel(sound.id))
                                                ) {
                                                    store.toggleFavorite(sound.id)
                                                }
                                            }
                                            .id("sidebar-recent-sound-\(sound.id)")
                                    }
                                }
                            }
                        }

                        // Recent mixes section.
                        sidebarSectionHeader(
                            L10n.sidebarRecentMixes, sectionId: sidebarSectionIds.recentMixes)
                        if !isSectionCollapsed(sidebarSectionIds.recentMixes) {
                            if recentMixes.isEmpty {
                                sidebarPlaceholder(L10n.sidebarRecentMixesEmpty)
                            } else {
                                LazyVStack(spacing: 1) {
                                    ForEach(recentMixes, id: \.id) { mix in
                                        SidebarMixRow(mix: mix, store: store)
                                            .contextMenu {
                                                Button(L10n.presetApply) {
                                                    store.applyMix(mix)
                                                }
                                                Divider()
                                                if store.favoriteMixIds.contains(mix.id) {
                                                    Button(
                                                        L10n.removeFromFavoritesLabel(
                                                            L10n.mixName(mix.id))
                                                    ) {
                                                        store.toggleFavoriteMix(id: mix.id)
                                                    }
                                                } else {
                                                    Button(
                                                        L10n.addToFavoritesLabel(
                                                            L10n.mixName(mix.id))
                                                    ) {
                                                        store.toggleFavoriteMix(id: mix.id)
                                                    }
                                                }
                                            }
                                            .id("sidebar-recent-mix-\(mix.id)")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, SidebarStyle.sidebarInset)
                    .padding(.top, MoodistTheme.Spacing.medium)
                    .padding(.bottom, MoodistTheme.Spacing.medium)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Color.clear.frame(height: SidebarStyle.titleBarReservedHeight)
                }
                .mask(alignment: .top) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: SidebarStyle.titleBarReservedHeight)
                        Rectangle().fill(.black)
                    }
                }
                .scrollIndicators(.never)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                sectionDivider

                Button(action: { store.showOptionsPanel = true }) {
                    sidebarRowLabel(
                        title: L10n.options,
                        systemImage: "gearshape",
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: [.command])
                .help(L10n.options)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SidebarStyle.sidebarInset)
                .padding(.vertical, MoodistTheme.Spacing.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.06))
            .frame(height: 1)
            .padding(.vertical, 6)
    }

    private var sidebarBackground: some View {
        ZStack {
            if transparencyEnabled {
                VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow)
                    .ignoresSafeArea(.container)
                // No tint, so the glass looks like Finder.
            } else {
                PlatformColor.windowBackground
                    .ignoresSafeArea(.container)
            }
        }
    }

    private var insertionLine: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(height: 2)
            .offset(y: -1)
    }

    /// Section header with a chevron for collapse and expand.
    private func sidebarSectionHeader(_ title: String, sectionId: String) -> some View {
        return Button(action: { toggleSection(sectionId) }) {
            HStack(spacing: 6) {
                Image(systemName: isSectionCollapsed(sectionId) ? "chevron.right" : "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(SidebarStyle.headerColor)
                    .frame(width: 10, alignment: .center)
                Text(title)
                    .font(SidebarStyle.headerFont)
                    .foregroundStyle(SidebarStyle.headerColor)
                    .textCase(nil)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 2)
            .padding(.leading, 2)
        }
        .buttonStyle(.plain)
        .help(isSectionCollapsed(sectionId) ? L10n.expandSection : L10n.collapseSection)
    }

    private func sidebarPlaceholder(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(SidebarStyle.secondaryText)
            .padding(.vertical, SidebarStyle.rowPaddingV + 2)
            .padding(.horizontal, SidebarStyle.rowPaddingH)
    }

}

// MARK: - Row Label Helper

private func sidebarRowLabel(title: String, systemImage: String, isSelected: Bool) -> some View {
    HStack(spacing: 10) {
        Image(systemName: systemImage)
            .font(.system(size: SidebarStyle.iconSize, weight: .regular))
            .foregroundStyle(isSelected ? SidebarStyle.primaryText : SidebarStyle.secondaryText)
            .frame(width: 18, height: 18, alignment: .center)
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(SidebarStyle.primaryText)
            .lineLimit(1)
        Spacer(minLength: 0)
    }
    .padding(.horizontal, SidebarStyle.rowPaddingH)
    .padding(.vertical, SidebarStyle.rowPaddingV)
    .contentShape(Rectangle())
}

// MARK: - Sound Row

private struct SidebarSoundRow: View {
    let sound: Sound
    @ObservedObject var store: SoundStore

    private var state: SoundStateItem {
        store.sounds[sound.id] ?? .default
    }

    private var isSelected: Bool { state.isSelected }
    private var isPlaying: Bool { store.isPlaying && isSelected }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: sound.iconName)
                .font(.system(size: SidebarStyle.iconSize, weight: .regular))
                .foregroundStyle(SidebarStyle.secondaryText)
                .frame(width: 18, height: 18, alignment: .center)
            Text(L10n.soundLabel(sound.id))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(SidebarStyle.primaryText)
                .lineLimit(1)
            Spacer(minLength: 0)
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, SidebarStyle.rowPaddingH)
        .padding(.vertical, SidebarStyle.rowPaddingV)
        .contentShape(Rectangle())
        .onTapGesture { toggleSelection() }
        .contextMenu {
            if isSelected {
                Button(L10n.deselect) { store.unselect(sound.id) }
            } else {
                Button(L10n.select) { store.select(sound.id) }
            }
            Divider()
            Button(L10n.removeFromFavoritesLabel(L10n.soundLabel(sound.id))) {
                store.toggleFavorite(sound.id)
            }
        }
        .accessibilityLabel(
            "\(L10n.soundLabel(sound.id)), \(isSelected ? L10n.stateSelected : L10n.stateNotSelected)"
        )
        .accessibilityHint(L10n.clickToggleSelection)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { toggleSelection() }
    }

    private func toggleSelection() {
        if state.isSelected {
            store.unselect(sound.id)
        } else {
            store.select(sound.id)
        }
    }
}

// MARK: - Recent Mix Row

private struct SidebarMixRow: View {
    let mix: Mix
    @ObservedObject var store: SoundStore
    private var isPlaying: Bool { store.isPlaying && store.displayedMixId == mix.id }
    private var mixDisplayName: String {
        (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id)
    }

    var body: some View {
        HStack(spacing: 10) {
            MixIconImage(
                iconName: mix.iconName,
                size: SidebarStyle.iconSize,
                frame: 18,
                weight: .regular,
                color: SidebarStyle.secondaryText
            )
            Text(mixDisplayName)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(SidebarStyle.primaryText)
                .lineLimit(1)
            Spacer(minLength: 0)
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, SidebarStyle.rowPaddingH)
        .padding(.vertical, SidebarStyle.rowPaddingV)
        .contentShape(Rectangle())
        .onTapGesture { store.applyMix(mix) }
        .contextMenu {
            Button(L10n.presetApply) {
                store.applyMix(mix)
            }
            Divider()
            if store.favoriteMixIds.contains(mix.id) {
                Button(L10n.removeFromFavoritesLabel(mixDisplayName)) {
                    store.toggleFavoriteMix(id: mix.id)
                }
            } else {
                Button(L10n.addToFavoritesLabel(mixDisplayName)) {
                    store.toggleFavoriteMix(id: mix.id)
                }
            }
        }
        .accessibilityLabel("\(mixDisplayName), \(L10n.countSounds(mix.soundIds.count))")
        .accessibilityHint(L10n.clickApplyMix)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { store.applyMix(mix) }
    }
}

#Preview {
    SidebarView()
        .environmentObject(SoundStore(audioService: AudioService()))
        .frame(width: 220, height: 400)
}
