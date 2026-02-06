//
//  SidebarView.swift
//  MoodistMac
//
//  Barra lateral estilo limpio: fondo claro, tipografía suave, metadatos a la derecha.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Constantes de estilo (sidebar limpio / tipo Cursor)

private enum SidebarStyle {
    static let headerFont = Font.system(.subheadline, design: .default).weight(.medium)
    static let headerColor = Color.primary.opacity(0.55)
    static let rowPaddingH: CGFloat = 14
    static let rowPaddingV: CGFloat = 3
    static let rowSpacing: CGFloat = 4
    static let sectionSpacing: CGFloat = 10
    static let iconSize: CGFloat = 14
    static let selectionRadius: CGFloat = 6
    static let selectionOpacity: Double = 0.08
    static let primaryText = Color.primary.opacity(0.9)
    static let secondaryText = Color.primary.opacity(0.45)
    static let sidebarInset: CGFloat = 8
    static let titlebarInset: CGFloat = 14
    static let chromeHeight: CGFloat = 34
    /// Altura reservada en la parte superior para que el contenido del scroll no invada los traffic lights.
    static let titleBarReservedHeight: CGFloat = 52
    static let topFadeHeight: CGFloat = 24
    static let bottomFadeHeight: CGFloat = 18
}

private let sidebarSectionIds = (favorites: "favorites", recentSounds: "recentSounds", favoriteMixes: "favoriteMixes", recentMixes: "recentMixes")

private let sidebarDragTypes: [UTType] = [.plainText, .utf8PlainText, .text]

private func sidebarDragItemProvider(id: String) -> NSItemProvider {
    // Use a standard text provider for reliable drag recognition on macOS.
    let provider = NSItemProvider(object: id as NSString)
    provider.suggestedName = id
    return provider
}

struct SidebarView: View {
    @EnvironmentObject var store: SoundStore
    @State private var sectionsCollapsed: [String: Bool] = PersistenceService.loadSidebarSectionsCollapsed()
    @State private var draggedFavoriteSoundId: String?
    @State private var draggedFavoriteMixId: String?
    @State private var lastFavoriteSoundDropTargetId: String?
    @State private var lastFavoriteMixDropTargetId: String?
    /// Indica si el indicador de inserción va "antes" (true) o "después" (false) de la fila objetivo.
    @State private var soundDropInsertBefore: Bool = true
    @State private var mixDropInsertBefore: Bool = true
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true

    /// Sonidos favoritos en el orden elegido por el usuario (permite drag and drop).
    private var orderedFavoriteSounds: [Sound] {
        store.orderedFavoriteSoundIds.compactMap { SoundsData.allSoundsById[$0] }
    }

    private var presetsById: [String: Preset] {
        var dict: [String: Preset] = [:]
        for preset in store.presets {
            dict[preset.id] = preset
        }
        return dict
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
        let byId = presetsById
        return store.recentMixIds.compactMap { id in
            MixesData.allMixesById[id] ?? byId[id]?.toMix()
        }
    }

    private var recentSounds: [Sound] {
        store.recentSoundIds.compactMap { SoundsData.allSoundsById[$0] }
    }

    private var favoriteMixes: [Mix] {
        let byId = presetsById
        return store.favoriteMixIds.compactMap { id in
            MixesData.allMixesById[id] ?? byId[id]?.toMix()
        }
    }

    var body: some View {
        ZStack {
            // Fondo opaco que cubre todo el sidebar (incluida zona de scroller).
            sidebarBackground
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: SidebarStyle.sectionSpacing) {
                        // Sección Favoritos (reordenable con drag and drop)
                        sidebarSectionHeader(L10n.sidebarFavorites, sectionId: sidebarSectionIds.favorites)
                        if !isSectionCollapsed(sidebarSectionIds.favorites) {
                            if orderedFavoriteSounds.isEmpty {
                                sidebarPlaceholder(L10n.sidebarFavoritesEmpty)
                            } else {
                                VStack(spacing: 1) {
                                    ForEach(orderedFavoriteSounds, id: \.id) { sound in
                                        VStack(spacing: 0) {
                                            if lastFavoriteSoundDropTargetId == sound.id && draggedFavoriteSoundId != nil && soundDropInsertBefore {
                                                sidebarInsertionLine
                                            }
                                            SidebarSoundRow(sound: sound, store: store)
                                                .onDrag {
                                                    draggedFavoriteMixId = nil
                                                    draggedFavoriteSoundId = sound.id
                                                    return sidebarDragItemProvider(id: sound.id)
                                                }
                                                .onDrop(
                                                    of: sidebarDragTypes,
                                                    delegate: FavoriteSoundDropDelegate(
                                                        destinationSoundId: sound.id,
                                                        store: store,
                                                        draggedSoundId: $draggedFavoriteSoundId,
                                                        lastDropTargetId: $lastFavoriteSoundDropTargetId,
                                                        insertBefore: $soundDropInsertBefore
                                                    )
                                                )
                                            if lastFavoriteSoundDropTargetId == sound.id && draggedFavoriteSoundId != nil && !soundDropInsertBefore {
                                                sidebarInsertionLine
                                            }
                                        }
                                        .id("sidebar-favorite-sound-\(sound.id)")
                                    }
                                }
                            }
                        }

                        // Sección Mixes favoritos (reordenable con drag and drop)
                        sidebarSectionHeader(L10n.sidebarFavoriteMixes, sectionId: sidebarSectionIds.favoriteMixes)
                        if !isSectionCollapsed(sidebarSectionIds.favoriteMixes) {
                            if favoriteMixes.isEmpty {
                                sidebarPlaceholder(L10n.sidebarFavoriteMixesEmpty)
                            } else {
                                VStack(spacing: 1) {
                                    ForEach(favoriteMixes, id: \.id) { mix in
                                        VStack(spacing: 0) {
                                            if lastFavoriteMixDropTargetId == mix.id && draggedFavoriteMixId != nil && mixDropInsertBefore {
                                                sidebarInsertionLine
                                            }
                                            SidebarMixRow(mix: mix, store: store)
                                                .onDrag {
                                                    draggedFavoriteSoundId = nil
                                                    draggedFavoriteMixId = mix.id
                                                    return sidebarDragItemProvider(id: mix.id)
                                                }
                                                .onDrop(
                                                    of: sidebarDragTypes,
                                                    delegate: FavoriteMixDropDelegate(
                                                        destinationMixId: mix.id,
                                                        store: store,
                                                        draggedMixId: $draggedFavoriteMixId,
                                                        lastDropTargetId: $lastFavoriteMixDropTargetId,
                                                        insertBefore: $mixDropInsertBefore
                                                    )
                                                )
                                            if lastFavoriteMixDropTargetId == mix.id && draggedFavoriteMixId != nil && !mixDropInsertBefore {
                                                sidebarInsertionLine
                                            }
                                        }
                                        .id("sidebar-favorite-mix-\(mix.id)")
                                    }
                                }
                            }
                        }

                        // Sección sonidos recientes
                        sidebarSectionHeader(L10n.sidebarRecentSounds, sectionId: sidebarSectionIds.recentSounds)
                        if !isSectionCollapsed(sidebarSectionIds.recentSounds) {
                            if recentSounds.isEmpty {
                                sidebarPlaceholder(L10n.sidebarRecentSoundsEmpty)
                            } else {
                                LazyVStack(spacing: 1) {
                                    ForEach(recentSounds, id: \.id) { sound in
                                        SidebarSoundRow(sound: sound, store: store)
                                            .contextMenu {
                                                Button(L10n.addToFavoritesLabel(L10n.soundLabel(sound.id))) {
                                                    store.toggleFavorite(sound.id)
                                                }
                                            }
                                            .id("sidebar-recent-sound-\(sound.id)")
                                    }
                                }
                            }
                        }

                        // Sección Mixes recientes
                        sidebarSectionHeader(L10n.sidebarRecentMixes, sectionId: sidebarSectionIds.recentMixes)
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
                                                    Button(L10n.removeFromFavoritesLabel(L10n.mixName(mix.id))) {
                                                        store.toggleFavoriteMix(id: mix.id)
                                                    }
                                                } else {
                                                    Button(L10n.addToFavoritesLabel(L10n.mixName(mix.id))) {
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
                // Sin tinte para que el cristal se vea como en Finder.
            } else {
                PlatformColor.windowBackground
                    .ignoresSafeArea(.container)
            }
        }
    }

    /// Encabezado de sección con chevron para colapsar/expandir.
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

    private var sidebarInsertionLine: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(height: 2)
            .padding(.leading, SidebarStyle.rowPaddingH + 18 + 10)
    }
}

// MARK: - Helper para etiqueta de fila (icono + texto)

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

// MARK: - Fila de sonido (estilo Finder: resaltado redondeado al seleccionar)

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
        .accessibilityLabel("\(L10n.soundLabel(sound.id)), \(isSelected ? L10n.stateSelected : L10n.stateNotSelected)")
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

// MARK: - Fila de mix reciente (estilo Finder)

private struct SidebarMixRow: View {
    let mix: Mix
    @ObservedObject var store: SoundStore
    private var isPlaying: Bool { store.isPlaying && store.displayedMixId == mix.id }
    private var mixDisplayName: String { (L10n.mixName(mix.id) == mix.id) ? mix.name : L10n.mixName(mix.id) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: mix.iconName)
                .font(.system(size: SidebarStyle.iconSize, weight: .regular))
                .foregroundStyle(SidebarStyle.secondaryText)
                .frame(width: 18, height: 18, alignment: .center)
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

// MARK: - Drag & drop reorder (favorites)

@MainActor
private struct FavoriteSoundDropDelegate: DropDelegate {
    let destinationSoundId: String
    let store: SoundStore
    @Binding var draggedSoundId: String?
    @Binding var lastDropTargetId: String?
    @Binding var insertBefore: Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: sidebarDragTypes)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedId = resolveDraggedId(from: info),
              draggedId != destinationSoundId else { return }
        let ordered = store.orderedFavoriteSoundIds
        guard let from = ordered.firstIndex(of: draggedId),
              let to = ordered.firstIndex(of: destinationSoundId) else { return }
        lastDropTargetId = destinationSoundId
        insertBefore = (to < from)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedSoundId = nil
            lastDropTargetId = nil
        }
        guard let draggedId = resolveDraggedId(from: info),
              draggedId != destinationSoundId else { return true }
        let ordered = store.orderedFavoriteSoundIds
        guard let from = ordered.firstIndex(of: draggedId),
              let to = ordered.firstIndex(of: destinationSoundId) else { return true }
        let toOffset = to > from ? to + 1 : to
        withAnimation(.easeInOut(duration: 0.2)) {
            store.moveFavoriteSounds(fromOffsets: IndexSet(integer: from), toOffset: toOffset)
        }
        return true
    }

    private func resolveDraggedId(from info: DropInfo) -> String? {
        if let draggedSoundId { return draggedSoundId }
        return info.itemProviders(for: sidebarDragTypes).first?.suggestedName
    }
}

@MainActor
private struct FavoriteMixDropDelegate: DropDelegate {
    let destinationMixId: String
    let store: SoundStore
    @Binding var draggedMixId: String?
    @Binding var lastDropTargetId: String?
    @Binding var insertBefore: Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: sidebarDragTypes)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedId = resolveDraggedId(from: info),
              draggedId != destinationMixId else { return }
        let ordered = store.favoriteMixIds
        guard let from = ordered.firstIndex(of: draggedId),
              let to = ordered.firstIndex(of: destinationMixId) else { return }
        lastDropTargetId = destinationMixId
        insertBefore = (to < from)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedMixId = nil
            lastDropTargetId = nil
        }
        guard let draggedId = resolveDraggedId(from: info),
              draggedId != destinationMixId else { return true }
        let ordered = store.favoriteMixIds
        guard let from = ordered.firstIndex(of: draggedId),
              let to = ordered.firstIndex(of: destinationMixId) else { return true }
        let toOffset = to > from ? to + 1 : to
        withAnimation(.easeInOut(duration: 0.2)) {
            store.moveFavoriteMixes(fromOffsets: IndexSet(integer: from), toOffset: toOffset)
        }
        return true
    }

    private func resolveDraggedId(from info: DropInfo) -> String? {
        if let draggedMixId { return draggedMixId }
        return info.itemProviders(for: sidebarDragTypes).first?.suggestedName
    }
}

#Preview {
    SidebarView()
        .environmentObject(SoundStore(audioService: AudioService()))
        .frame(width: 220, height: 400)
}
