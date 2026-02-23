//
//  ContentView.swift
//  MoodistMac
//
//  Vista principal: controles, favoritos, volumen, categorías. macOS Sequoia 15.0+.
//

import SwiftUI
import AppKit

private let sidebarWidthMin: CGFloat = 180
private let sidebarWidthMax: CGFloat = 320
private let sidebarWidthDefault: CGFloat = 220
private let sidebarResizeHandleWidth: CGFloat = 14
/// Por debajo de este ancho de ventana se usa el menú compacto (un solo icono).
/// Nota: el buscador en la toolbar ocupa espacio; en ventanas estrechas el sistema puede mover controles
/// al overflow ("»"), donde algunos pickers pueden volverse poco fiables. Preferimos consolidar en un menú.
private let toolbarCompactThreshold: CGFloat = 600
/// Por debajo de este ancho de ventana el selector Sounds/Mixes pasa a menú desplegable en lugar de segmentado.
private let toolbarMediumThreshold: CGFloat = 720
/// Espacio extra para que el contenido no se solape con la barra de título cuando esta es transparente.
private let titlebarContentInset: CGFloat = 40
/// Backdrop sutil para fundir controles con el contenido.
private let toolbarBackdropHeight: CGFloat = 56
private let toolbarBackdropFadeHeight: CGFloat = 28
private let toolbarSearchFieldYOffset: CGFloat = 0
/// Rango de ancho donde el offset del toolbar se aplica gradualmente (evita solaparse con el search).
private let toolbarOffsetMinWidth: CGFloat = 520
private let toolbarOffsetMaxWidth: CGFloat = 760
/// Mantener un mínimo de ancho útil para el contenido principal al calcular el máximo de sidebar.
private let mainContentMinWidth: CGFloat = 520

private struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 600
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct WindowWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 800
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Ancho del área de contenido para que las filas adapten espaciado y controles en ventanas estrechas.
struct ContentAreaWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 600
}
extension EnvironmentValues {
    var contentAreaWidth: CGFloat {
        get { self[ContentAreaWidthEnvironmentKey.self] }
        set { self[ContentAreaWidthEnvironmentKey.self] = newValue }
    }
}

/// Indica si el usuario está desplazando activamente el ScrollView principal.
struct IsUserScrollingEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}
extension EnvironmentValues {
    var isUserScrolling: Bool {
        get { self[IsUserScrollingEnvironmentKey.self] }
        set { self[IsUserScrollingEnvironmentKey.self] = newValue }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: SoundStore
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    @AppStorage(PersistenceService.collapseCategoriesOnColdOpenKey) private var collapseCategoriesOnColdOpen = true
    @State private var windowWidth: CGFloat = 800
    @State private var requestToolbarSearchFocus = false
    @State private var selectedSection: ContentSection = .sounds
    @AppStorage("MoodistMac.sidebarWidth") private var persistedSidebarWidth: Double = sidebarWidthDefault
    /// Ancho en uso durante arrastre; solo se persiste al soltar para evitar lag.
    @State private var sidebarWidth: CGFloat = CGFloat(sidebarWidthDefault)
    @State private var sidebarResizeStartWidth: CGFloat = 0
    /// Ancho del área de contenido; por debajo del umbral se usa la barra compacta (menú único).
    @State private var contentAreaWidth: CGFloat = 600
    /// Estado expandido de cada categoría (por ID). Por defecto todas expandidas.
    @State private var categoryExpandedStates: [String: Bool] = [:]
    /// Estado expandido de cada categoría de mixes (por ID). Por defecto todas expandidas.
    @State private var mixCategoryExpandedStates: [String: Bool] = [:]
    @State private var scrollState = ScrollStateStore()
    @State private var soundsScrollPosition: String? = ScrollStateStore.scrollTopAnchorId
    @State private var mixesScrollPosition: String? = ScrollStateStore.scrollTopAnchorId
    @State private var isUserScrolling = false
    @State private var isSaveMixHovered = false
    @State private var isClearHovered = false
    @State private var isTimerButtonHovered = false
    @State private var isTimerCancelButtonHovered = false
    @State private var isCollapseAllSoundsHovered = false
    @State private var isCollapseAllMixesHovered = false
    @State private var isResizeCursorActive = false
    @State private var sidebarResizeStartPointerX: CGFloat?
    @State private var playingSoundsCache: [Sound] = []
    @State private var sectionTransitionDirection: CGFloat = 1

    /// La sidebar es siempre visible; el toggle fue eliminado para simplificar la navegación.
    private var isSidebarVisible: Bool { true }

    private var contentSidebarWidth: CGFloat { sidebarWidth }

    private var contentTopPadding: CGFloat {
        let base = contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large
        return base + titlebarContentInset
    }

    private var mixesScrollTopPadding: CGFloat {
        contentTopPadding
    }

    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { proxy in
                let contentWidth = max(0, proxy.size.width - (isSidebarVisible ? contentSidebarWidth : 0))
                mainContent
                    .frame(width: contentWidth, height: proxy.size.height, alignment: .leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
            .clipped()
            if isSidebarVisible {
                sidebarOverlay
                    .ignoresSafeArea(.container)
                    .zIndex(1)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                sidebarResizeHandle
                    .offset(x: sidebarWidth - (sidebarResizeHandleWidth / 2))
                    .zIndex(2)
            }
        }
        .ignoresSafeArea(.container)
        .tint(MoodistTheme.Colors.accent)
        .frame(minWidth: 850, minHeight: 600)
        .background(GeometryReader { geometry in
            Color.clear.preference(key: WindowWidthKey.self, value: geometry.size.width)
        })
        .onPreferenceChange(WindowWidthKey.self) { totalWidth in
            windowWidth = totalWidth
            updateSidebarForWindowWidth(totalWidth)
        }
        .onAppear(perform: setupOnAppear)
        .onChange(of: store.isPlaying) { _, newValue in
            MediaKeyHandler.shared.updateNowPlaying(isPlaying: newValue)
        }
        .onChange(of: store.requestSearchFocus) { _, requested in
            if requested {
                requestToolbarSearchFocus = true
                store.requestSearchFocus = false
            }
        }
        .onChange(of: store.sounds) { _, _ in
            refreshPlayingSoundsCache()
        }
    }


    private var sidebarOverlay: some View {
        SidebarView()
            .environmentObject(store)
            .frame(width: sidebarWidth)
            .frame(maxHeight: .infinity)
    }

    @ViewBuilder private var mainContent: some View {
        #if LIQUID_GLASS_SDK
        if #available(macOS 26.0, *) {
            // GlassEffectContainer coordina el cristal del reproductor con el contenido:
            // el contenido detrás se distorsiona/refracta según Liquid Glass.
            GlassEffectContainer {
                ZStack(alignment: .bottom) {
                    // Fondo con extensión para que el cristal pueda muestrear más allá del safe area (Liquid Glass).
                    PlatformColor.windowBackground
                        .backgroundExtensionEffect()
                        .ignoresSafeArea(.container, edges: .top)
                    NavigationStack {
                        mainScrollContent
                    }
                    .environment(\.contentAreaWidth, contentAreaWidth)
                    .frame(minHeight: 0)
                    .overlay(alignment: .top) {
                        topControlsBackdrop
                    }
                    BottomPlayerBarView()
                        .environmentObject(store)
                        .frame(width: contentAreaWidth)
                        .frame(height: 76)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .onPreferenceChange(ContentWidthKey.self) { newWidth in
                guard sidebarResizeStartWidth == 0 else { return }
                if abs(newWidth - contentAreaWidth) >= 0.5 {
                    contentAreaWidth = newWidth
                }
            }
        } else {
            mainContentFallback
        }
        #else
        mainContentFallback
        #endif
    }
    
    private var mainContentFallback: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                mainScrollContent
            }
            .environment(\.contentAreaWidth, contentAreaWidth)
            .frame(minHeight: 0)
            .overlay(alignment: .top) {
                topControlsBackdrop
            }
            BottomPlayerBarView()
                .environmentObject(store)
                .frame(width: contentAreaWidth)
                .frame(height: 76)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .background(
            PlatformColor.windowBackground
                .ignoresSafeArea(.container, edges: .top)
        )
        .onPreferenceChange(ContentWidthKey.self) { newWidth in
            guard sidebarResizeStartWidth == 0 else { return }
            if abs(newWidth - contentAreaWidth) >= 0.5 {
                contentAreaWidth = newWidth
            }
        }
    }

    private static let scrollTopAnchorId = ScrollStateStore.scrollTopAnchorId
    private typealias ScrollContext = ScrollStateStore.Context

    private func scrollContext(for section: ContentSection, searchQuery: String) -> ScrollContext {
        scrollState.context(for: section, searchQuery: searchQuery)
    }

    private func storedScrollAnchorId(for context: ScrollContext) -> String {
        scrollState.storedScrollAnchorId(for: context)
    }

    private func setStoredScrollAnchorId(_ id: String, for context: ScrollContext) {
        scrollState.setStoredScrollAnchorId(id, for: context)
    }

    private func schedulePersistScrollAnchors() {
        scrollState.schedulePersistScrollAnchors { anchors in
            PersistenceService.saveScrollAnchorIds(anchors)
        }
    }

    private func isRelevantScrollAnchorId(_ id: String, for context: ScrollContext) -> Bool {
        scrollState.isRelevantScrollAnchorId(id, for: context)
    }

    private func scheduleSoundsScrollRestore(for context: ScrollContext, scrollToTopFirst: Bool) {
        scrollState.scheduleSoundsScrollRestore(for: context, scrollToTopFirst: scrollToTopFirst) { position in
            soundsScrollPosition = position
        }
    }

    private func scheduleMixesScrollRestore(for context: ScrollContext, scrollToTopFirst: Bool) {
        scrollState.scheduleMixesScrollRestore(for: context, scrollToTopFirst: scrollToTopFirst) { position in
            mixesScrollPosition = position
        }
    }

    private func requestSectionChange(to newSection: ContentSection) {
        guard selectedSection != newSection else { return }
        sectionTransitionDirection = transitionDirection(from: selectedSection, to: newSection)
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedSection = newSection
        }
    }

    private var mainScrollContent: some View {
        ZStack {
            if selectedSection == .sounds {
                soundsScrollContent
                    .transition(sectionSwapTransition)
                    .accessibilityHidden(false)
            }
            if selectedSection == .mixes {
                mixesScrollContent
                    .transition(sectionSwapTransition)
                    .accessibilityHidden(false)
            }
        }
        .clipped()
        .environment(\.isUserScrolling, isUserScrolling)
        .background(GeometryReader { g in
            Color.clear.preference(key: ContentWidthKey.self, value: g.size.width)
        })
        .background(mainBackground)
        .navigationTitle("")
        .toolbar { toolbarContent }
        // With transparency enabled, let the sidebar frosting show under the titlebar (Finder-like).
        .toolbarBackground(transparencyEnabled ? .clear : PlatformColor.windowBackground, for: .windowToolbar)
        .toolbarBackground(transparencyEnabled ? .hidden : .visible, for: .windowToolbar)
        .onChange(of: store.showOptionsPanel) { _, show in
            if show {
                openWindow(id: "options")
                store.showOptionsPanel = false
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showSavePresetSheet },
            set: { if !$0 { store.closeSavePresetSheet() } else { store.showSavePresetSheet = true } }
        )) {
            SavePresetSheet(store: store) {
                store.closeSavePresetSheet()
            }
        }
    }

    private var sectionSwapTransition: AnyTransition {
        let insertionEdge: Edge = sectionTransitionDirection > 0 ? .trailing : .leading
        let removalEdge: Edge = sectionTransitionDirection > 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertionEdge).combined(with: .opacity),
            removal: .move(edge: removalEdge).combined(with: .opacity)
        )
    }

    private func transitionDirection(from oldSection: ContentSection, to newSection: ContentSection) -> CGFloat {
        switch (oldSection, newSection) {
        case (.sounds, .mixes):
            return 1
        case (.mixes, .sounds):
            return -1
        default:
            return 1
        }
    }

    private var soundsScrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: contentAreaWidth < 400 ? MoodistTheme.Spacing.medium : MoodistTheme.Spacing.xLarge) {
                Color.clear
                    .frame(height: 1)
                    .id(Self.scrollTopAnchorId)
                soundsSections
            }
            .padding(.horizontal, contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large)
            .padding(.top, contentTopPadding)
            .padding(.bottom, (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large) + 88)
        }
        .scrollPosition(id: $soundsScrollPosition, anchor: .top)
        .onScrollPhaseChange { _, phase in
            guard selectedSection == .sounds else { return }
            isUserScrolling = phase != .idle
        }
        .onChange(of: soundsScrollPosition) { _, newValue in
            guard !scrollState.suppressSoundsScrollMemoryUpdates else { return }
            guard let newValue else { return }
            let context = scrollContext(for: .sounds, searchQuery: store.searchQuery)
            guard isRelevantScrollAnchorId(newValue, for: context) else { return }
            guard newValue != storedScrollAnchorId(for: context) else { return }
            setStoredScrollAnchorId(newValue, for: context)
            schedulePersistScrollAnchors()
        }
        .onChange(of: store.searchQuery) { oldValue, newValue in
            let oldContext = scrollContext(for: .sounds, searchQuery: oldValue)
            if let current = soundsScrollPosition, isRelevantScrollAnchorId(current, for: oldContext) {
                setStoredScrollAnchorId(current, for: oldContext)
                schedulePersistScrollAnchors()
            }
            let newContext = scrollContext(for: .sounds, searchQuery: newValue)
            if oldContext != newContext {
                scheduleSoundsScrollRestore(for: newContext, scrollToTopFirst: true)
            } else if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: newContext)
                scheduleSoundsScrollRestore(for: newContext, scrollToTopFirst: true)
            }
        }
        .onAppear {
            guard !scrollState.didRestoreSounds else { return }
            scrollState.didRestoreSounds = true
            let context = scrollContext(for: .sounds, searchQuery: store.searchQuery)
            if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // En el primer arranque mostramos "Currently playing" en la parte superior.
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: context)
                scheduleSoundsScrollRestore(for: context, scrollToTopFirst: true)
                return
            }
            scheduleSoundsScrollRestore(for: context, scrollToTopFirst: false)
        }
    }

    private var mixesScrollContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: contentAreaWidth < 400 ? MoodistTheme.Spacing.medium : MoodistTheme.Spacing.xLarge) {
                Color.clear
                    .frame(height: 1)
                    .id(Self.scrollTopAnchorId)
                mixesSections
            }
            .padding(.horizontal, contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large)
            .padding(.top, mixesScrollTopPadding)
            .padding(.bottom, (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large) + 88)
        }
        .scrollPosition(id: $mixesScrollPosition, anchor: .top)
        .onScrollPhaseChange { _, phase in
            guard selectedSection == .mixes else { return }
            isUserScrolling = phase != .idle
        }
        .onChange(of: mixesScrollPosition) { _, newValue in
            guard !scrollState.suppressMixesScrollMemoryUpdates else { return }
            guard let newValue else { return }
            let context = scrollContext(for: .mixes, searchQuery: store.searchQuery)
            guard isRelevantScrollAnchorId(newValue, for: context) else { return }
            guard newValue != storedScrollAnchorId(for: context) else { return }
            setStoredScrollAnchorId(newValue, for: context)
            schedulePersistScrollAnchors()
        }
        .onChange(of: store.searchQuery) { oldValue, newValue in
            let oldContext = scrollContext(for: .mixes, searchQuery: oldValue)
            if let current = mixesScrollPosition, isRelevantScrollAnchorId(current, for: oldContext) {
                setStoredScrollAnchorId(current, for: oldContext)
                schedulePersistScrollAnchors()
            }
            let newContext = scrollContext(for: .mixes, searchQuery: newValue)
            if oldContext != newContext {
                scheduleMixesScrollRestore(for: newContext, scrollToTopFirst: true)
            } else if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: newContext)
                scheduleMixesScrollRestore(for: newContext, scrollToTopFirst: true)
            }
        }
        .onAppear {
            guard !scrollState.didRestoreMixes else { return }
            scrollState.didRestoreMixes = true
            let context = scrollContext(for: .mixes, searchQuery: store.searchQuery)
            if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // En el primer arranque mostramos el inicio de la lista en Mixes.
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: context)
                scheduleMixesScrollRestore(for: context, scrollToTopFirst: true)
                return
            }
            scheduleMixesScrollRestore(for: context, scrollToTopFirst: false)
        }
    }

    private var soundsSections: some View {
        Group {
            if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                currentlyPlayingSection
                categoriesSection
            } else {
                searchResultsSection
            }
        }
    }

    private var mixesSections: some View {
        Group {
            if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                mixesPlaceholderSection
            } else {
                mixesSearchResultsSection
            }
        }
    }

    private var mainBackground: some View {
        PlatformColor.windowBackground
            .ignoresSafeArea(.container, edges: .top)
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ContentToolbar(
            windowWidth: windowWidth,
            compactThreshold: toolbarCompactThreshold,
            mediumThreshold: toolbarMediumThreshold,
            toolbarContentOffset: toolbarContentOffset,
            toolbarSearchFieldWidth: toolbarSearchFieldWidth,
            toolbarSearchFieldHeight: toolbarSearchFieldHeight,
            toolbarSearchFieldFocusPadding: toolbarSearchFieldFocusPadding,
            toolbarSearchFieldYOffset: toolbarSearchFieldYOffset,
            selectedSection: $selectedSection,
            searchQuery: $store.searchQuery,
            requestSearchFocus: $requestToolbarSearchFocus,
            onRequestSectionChange: requestSectionChange(to:),
            onTogglePlay: { store.togglePlay() },
            onShuffle: { store.shuffle() },
            onNextMix: { store.playNextRandomMix() },
            onUnselectAll: { store.unselectAll() },
            isPlaying: store.isPlaying,
            hasSelection: store.hasSelection
        )
    }

    private func setupOnAppear() {
        let w = CGFloat(persistedSidebarWidth)
        sidebarWidth = min(sidebarWidthMax, max(sidebarWidthMin, w))
        updateSidebarForWindowWidth(windowWidth)
        refreshPlayingSoundsCache()
        let anchors = PersistenceService.loadScrollAnchorIds()
        scrollState.loadPersistedAnchorDictionary(anchors)
        MediaKeyHandler.shared.setup()
        MediaKeyHandler.shared.setToggleHandler { store.togglePlay() }
        MediaKeyHandler.shared.setNextTrackHandler { store.playNextRandomMix() }
        MediaKeyHandler.shared.updateNowPlaying(isPlaying: store.isPlaying)
    }

    private func refreshPlayingSoundsCache() {
        playingSoundsCache = store.selectedIds
            .compactMap { SoundsData.allSoundsById[$0] }
            .sorted { L10n.soundLabel($0.id).localizedStandardCompare(L10n.soundLabel($1.id)) == .orderedAscending }
    }

    private var defaultSoundCategoryExpandedState: Bool {
        !collapseCategoriesOnColdOpen
    }

    private func defaultMixCategoryExpandedState(for categoryId: String) -> Bool {
        if categoryId == MixesData.custom.id {
            return true
        }
        return !collapseCategoriesOnColdOpen
    }

    /// Ajusta el ancho de la sidebar a su rango permitido para el ancho de ventana actual.
    /// Fuera de drag: respeta el ancho deseado persistido.
    /// Durante drag: solo mantiene la posición actual dentro de límites válidos.
    private func updateSidebarForWindowWidth(_ totalWidth: CGFloat) {
        sidebarWidth = SidebarLayout.adjustedSidebarWidth(
            currentWidth: sidebarWidth,
            desiredWidth: CGFloat(persistedSidebarWidth),
            totalWidth: totalWidth,
            isResizing: sidebarResizeStartWidth != 0,
            minSidebarWidth: sidebarWidthMin,
            maxSidebarLimit: sidebarWidthMax,
            minContentWidth: mainContentMinWidth
        )
    }

    private func maxSidebarWidth(for totalWidth: CGFloat) -> CGFloat {
        SidebarLayout.maxSidebarWidth(
            totalWidth: totalWidth,
            minSidebarWidth: sidebarWidthMin,
            maxSidebarLimit: sidebarWidthMax,
            minContentWidth: mainContentMinWidth
        )
    }

    private func clampedSidebarWidthForDrag(translationX: CGFloat) -> CGFloat {
        let baseWidth = sidebarResizeStartWidth == 0 ? sidebarWidth : sidebarResizeStartWidth
        let newWidth = baseWidth + translationX
        let maxAllowed = maxSidebarWidth(for: windowWidth)
        return min(maxAllowed, max(sidebarWidthMin, newWidth)).rounded()
    }

    private func clampedSidebarWidthForDrag(pointerX: CGFloat) -> CGFloat {
        let startPointerX = sidebarResizeStartPointerX ?? pointerX
        return clampedSidebarWidthForDrag(translationX: pointerX - startPointerX)
    }

    private var toolbarContentOffset: CGFloat {
        guard isSidebarVisible else { return 0 }
        if #available(macOS 26.0, *) {
            return 0
        }
        let desired = sidebarWidth / 2
        let width = contentAreaWidth
        if width <= toolbarOffsetMinWidth { return 0 }
        if width >= toolbarOffsetMaxWidth { return desired }
        let t = (width - toolbarOffsetMinWidth) / (toolbarOffsetMaxWidth - toolbarOffsetMinWidth)
        return desired * t
    }

    private var toolbarSearchFieldWidth: CGFloat {
        min(240, max(140, windowWidth * 0.25))
    }

    private var toolbarSearchFieldHeight: CGFloat {
        if #available(macOS 26.0, *) {
            return 32
        }
        return 28
    }

    private var toolbarSearchFieldFocusPadding: CGFloat {
        if #available(macOS 26.0, *) {
            return 4
        }
        return 0
    }

    /// Backdrop superior: bloquea clics para que no lleguen al contenido (categorías/sonidos).
    private var topControlsBackdrop: some View {
        let height = toolbarBackdropHeight + toolbarBackdropFadeHeight
        return ZStack {
            PlatformColor.windowBackground
                .frame(height: height)
                .frame(maxWidth: .infinity)
                // Fade out hacia el contenido para evitar una "barra" dura.
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.7),
                            .init(color: .black.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)

            // Área de arrastre restringida a la zona superior (barra de título).
            TitlebarDragArea()
                .frame(height: height)
                .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(.container, edges: .top)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }

    private var sidebarResizeHandle: some View {
        ZStack {
            // Línea visible para indicar el borde de resize.
            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 1)
        }
        .frame(width: sidebarResizeHandleWidth)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active:
                setResizeCursorActive(true)
            case .ended:
                setResizeCursorActive(false)
            }
        }
        .onDisappear {
            setResizeCursorActive(false)
            sidebarResizeStartPointerX = nil
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if sidebarResizeStartWidth == 0 {
                        sidebarResizeStartWidth = sidebarWidth
                        sidebarResizeStartPointerX = value.startLocation.x
                    } else if sidebarResizeStartPointerX == nil {
                        sidebarResizeStartPointerX = value.startLocation.x
                    }
                    let nextWidth = clampedSidebarWidthForDrag(pointerX: value.location.x)
                    if abs(nextWidth - sidebarWidth) >= 0.5 {
                        sidebarWidth = nextWidth
                    }
                }
                .onEnded { value in
                    if sidebarResizeStartPointerX == nil {
                        sidebarResizeStartPointerX = value.startLocation.x
                    }
                    let finalWidth = clampedSidebarWidthForDrag(pointerX: value.location.x)
                    if abs(finalWidth - sidebarWidth) >= 0.5 {
                        sidebarWidth = finalWidth
                    }
                    persistedSidebarWidth = Double(sidebarWidth)
                    sidebarResizeStartWidth = 0
                    sidebarResizeStartPointerX = nil
                }
        )
        .accessibilityLabel(L10n.resizeSidebar)
        .accessibilityHint(L10n.resizeSidebarHint)
    }

    private func setResizeCursorActive(_ active: Bool) {
        guard active != isResizeCursorActive else { return }
        isResizeCursorActive = active
        if active {
            NSCursor.resizeLeftRight.push()
        } else {
            NSCursor.pop()
        }
    }

    /// Sección Mixes: categorías temáticas con mixes aplicables.
    private var mixesPlaceholderSection: some View {
        MixesPlaceholderSectionView(
            store: store,
            contentAreaWidth: contentAreaWidth,
            mixCategoryExpandedStates: $mixCategoryExpandedStates,
            defaultMixExpandedState: defaultMixCategoryExpandedState(for:),
            allMixCategoriesExpanded: allMixCategoriesExpanded,
            isCollapseAllMixesHovered: $isCollapseAllMixesHovered,
            toggleAllMixCategories: toggleAllMixCategories
        )
    }

    private var mixesSearchResultsSection: some View {
        MixesSearchResultsSectionView(store: store)
    }

    private var currentlyPlayingSection: some View {
        CurrentlyPlayingSectionView(
            store: store,
            contentAreaWidth: contentAreaWidth,
            playingSounds: playingSoundsCache,
            isSaveMixHovered: $isSaveMixHovered,
            isClearHovered: $isClearHovered,
            isTimerHovered: $isTimerButtonHovered,
            isTimerCancelHovered: $isTimerCancelButtonHovered,
            onSaveMix: { store.promptSaveCurrentPreset() },
            onClear: { store.unselectAll() },
            onOpenTimer: {
                NotificationCenter.default.post(name: .requestShowCustomTimerWindow, object: nil)
            },
            onCancelTimer: { store.cancelSleepTimer() }
        )
    }

    private var categoriesSection: some View {
        CategoriesSectionView(
            store: store,
            contentAreaWidth: contentAreaWidth,
            categoryExpandedStates: $categoryExpandedStates,
            defaultExpandedState: defaultSoundCategoryExpandedState,
            allCategoriesExpanded: allCategoriesExpanded,
            isCollapseAllHovered: $isCollapseAllSoundsHovered,
            toggleAllCategories: toggleAllCategories
        )
    }

    private var allCategoriesExpanded: Bool {
        SoundsData.categories.allSatisfy { categoryExpandedStates[$0.id] ?? true }
    }

    private func toggleAllCategories() {
        let shouldExpand = !allCategoriesExpanded
        withAnimation(.easeInOut(duration: 0.2)) {
            for category in SoundsData.categories {
                categoryExpandedStates[category.id] = shouldExpand
            }
        }
    }

    private var nonCustomMixCategories: [MixCategory] {
        MixesData.categories.filter { $0.id != MixesData.custom.id }
    }

    private var allMixCategoriesExpanded: Bool {
        nonCustomMixCategories.allSatisfy { mixCategoryExpandedStates[$0.id] ?? defaultMixCategoryExpandedState(for: $0.id) }
    }

    private func toggleAllMixCategories() {
        let shouldExpand = !allMixCategoriesExpanded
        withAnimation(.easeInOut(duration: 0.2)) {
            for category in nonCustomMixCategories {
                mixCategoryExpandedStates[category.id] = shouldExpand
            }
        }
    }

    private var searchResultsSection: some View {
        SoundsSearchResultsSectionView(store: store, contentAreaWidth: contentAreaWidth)
    }
}

struct HeaderActionButtonStyle: ButtonStyle {
    let isHovered: Bool
    let isPrimary: Bool
    let isCompact: Bool

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isCompact ? 12 : 13, weight: .medium))
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.vertical, isCompact ? 4 : 5)
            .foregroundStyle(foregroundColor)
            .background(
                Capsule().fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                Capsule().strokeBorder(borderColor(isPressed: configuration.isPressed), lineWidth: 1)
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
        if !isEnabled {
            return Color.primary.opacity(0.08)
        }
        if isPrimary {
            return MoodistTheme.Colors.accent.opacity(isPressed ? 0.5 : (isHovered ? 0.4 : 0.25))
        }
        return Color.primary.opacity(isPressed ? 0.22 : (isHovered ? 0.16 : 0.1))
    }
}

#Preview {
    ContentView()
        .environmentObject(SoundStore(audioService: AudioService()))
        .frame(width: 400, height: 600)
}
