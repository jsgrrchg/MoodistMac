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
/// Paso de actualización durante resize para reducir recomputes y lag.
private let sidebarResizeStep: CGFloat = 6
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

private struct TitlebarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableTitlebarView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DraggableTitlebarView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
    }
}

/// Barra de búsqueda nativa de macOS (NSSearchField con estilo estándar de Apple).
private struct ToolbarSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var requestFocus: Bool
    let height: CGFloat

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField(string: "")
        field.delegate = context.coordinator
        field.controlSize = .small
        field.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.sendsSearchStringImmediately = true
        field.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = field.heightAnchor.constraint(equalToConstant: height)
        heightConstraint.isActive = true
        context.coordinator.heightConstraint = heightConstraint
        // Mantiene el anillo de foco nativo para dar claridad al estado activo.
        if #available(macOS 26.0, *) {
            field.focusRingType = .exterior
        } else {
            field.focusRingType = .default
        }

        // Estilo nativo: bisel redondeado estándar de macOS (Human Interface Guidelines),
        // con icono de lupa para mayor affordance.
        if let cell = field.cell as? NSSearchFieldCell {
            cell.controlSize = .small
            cell.bezelStyle = .roundedBezel
        }
        field.placeholderString = placeholder
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
        context.coordinator.heightConstraint?.constant = height
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if requestFocus {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
                requestFocus = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        private let parent: ToolbarSearchField
        var heightConstraint: NSLayoutConstraint?

        init(_ parent: ToolbarSearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            parent.text = field.stringValue
        }
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

/// Sección principal del área de contenido: librería de sonidos o mezclas.
private enum MainSection: String, CaseIterable {
    case sounds
    case mixes
}

/// Tamaño de texto elegido por el usuario (small, medium, large, xLarge).
private func dynamicTypeSizeFromRaw(_ raw: String) -> DynamicTypeSize {
    switch raw {
    case "small": return .small
    case "large": return .large
    case "xLarge": return .xLarge
    default: return .medium
    }
}

struct ContentView: View {
    private final class ScrollCoordinator {
        var soundsScrollAnchorId: String = ContentView.scrollTopAnchorId
        var mixesScrollAnchorId: String = ContentView.scrollTopAnchorId
        var soundsSearchScrollAnchorId: String = ContentView.scrollTopAnchorId
        var mixesSearchScrollAnchorId: String = ContentView.scrollTopAnchorId
        var suppressSoundsScrollMemoryUpdates = false
        var suppressMixesScrollMemoryUpdates = false
        var persistScrollTask: Task<Void, Never>?
        var soundsRestoreTask: Task<Void, Never>?
        var mixesRestoreTask: Task<Void, Never>?
        var soundsRestoreGeneration = 0
        var mixesRestoreGeneration = 0
        var didRestoreSounds = false
        var didRestoreMixes = false
        var forceInitialSoundsTop = false
        var forceInitialMixesTop = false
    }

    @EnvironmentObject var store: SoundStore
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PersistenceService.textSizeKey) private var textSizeRaw = "medium"
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    @State private var windowWidth: CGFloat = 800
    @State private var requestToolbarSearchFocus = false
    @State private var selectedSection: MainSection = .sounds
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
    @State private var scrollCoordinator = ScrollCoordinator()
    @State private var soundsScrollPosition: String? = Self.scrollTopAnchorId
    @State private var mixesScrollPosition: String? = Self.scrollTopAnchorId
    @State private var isUserScrolling = false
    @State private var isSaveMixHovered = false
    @State private var isClearHovered = false

    /// La sidebar es siempre visible; el toggle fue eliminado para simplificar la navegación.
    private var isSidebarVisible: Bool { true }

    private var contentSidebarWidth: CGFloat {
        sidebarResizeStartWidth == 0 ? sidebarWidth : sidebarResizeStartWidth
    }

    private var contentTopPadding: CGFloat {
        let base = contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large
        return base + titlebarContentInset
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
        .environment(\.dynamicTypeSize, dynamicTypeSizeFromRaw(textSizeRaw))
        .tint(MoodistTheme.Colors.accent)
        .frame(minWidth: 850, minHeight: 480)
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
        .onChange(of: store.requestedMainSection) { _, requested in
            guard let requested else { return }
            switch requested {
            case SoundStore.mainSectionSounds:
                requestSectionChange(to: .sounds)
            case SoundStore.mainSectionMixes:
                requestSectionChange(to: .mixes)
            default:
                break
            }
            store.requestedMainSection = nil
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
                contentAreaWidth = newWidth
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
            contentAreaWidth = newWidth
        }
    }

    private static let scrollTopAnchorId = "mainScrollTop"

    private enum ScrollContext {
        case sounds
        case mixes
        case soundsSearch
        case mixesSearch
    }

    private var scrollContext: ScrollContext {
        scrollContext(for: selectedSection, searchQuery: store.searchQuery)
    }

    private func scrollContext(for section: MainSection, searchQuery: String) -> ScrollContext {
        let isSearching = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if section == .mixes {
            return isSearching ? .mixesSearch : .mixes
        }
        return isSearching ? .soundsSearch : .sounds
    }

    private func storedScrollAnchorId(for context: ScrollContext) -> String {
        switch context {
        case .sounds:
            return scrollCoordinator.soundsScrollAnchorId
        case .mixes:
            return scrollCoordinator.mixesScrollAnchorId
        case .soundsSearch:
            return scrollCoordinator.soundsSearchScrollAnchorId
        case .mixesSearch:
            return scrollCoordinator.mixesSearchScrollAnchorId
        }
    }

    private func setStoredScrollAnchorId(_ id: String, for context: ScrollContext) {
        switch context {
        case .sounds:
            scrollCoordinator.soundsScrollAnchorId = id
        case .mixes:
            scrollCoordinator.mixesScrollAnchorId = id
        case .soundsSearch:
            scrollCoordinator.soundsSearchScrollAnchorId = id
        case .mixesSearch:
            scrollCoordinator.mixesSearchScrollAnchorId = id
        }
    }

    private static let scrollAnchorPersistenceKeySounds = "sounds"
    private static let scrollAnchorPersistenceKeyMixes = "mixes"
    private static let scrollAnchorPersistenceKeySoundsSearch = "soundsSearch"
    private static let scrollAnchorPersistenceKeyMixesSearch = "mixesSearch"

    private func persistScrollAnchors() {
        var dict: [String: String] = [:]
        if !scrollCoordinator.soundsScrollAnchorId.isEmpty { dict[Self.scrollAnchorPersistenceKeySounds] = scrollCoordinator.soundsScrollAnchorId }
        if !scrollCoordinator.mixesScrollAnchorId.isEmpty { dict[Self.scrollAnchorPersistenceKeyMixes] = scrollCoordinator.mixesScrollAnchorId }
        if !scrollCoordinator.soundsSearchScrollAnchorId.isEmpty { dict[Self.scrollAnchorPersistenceKeySoundsSearch] = scrollCoordinator.soundsSearchScrollAnchorId }
        if !scrollCoordinator.mixesSearchScrollAnchorId.isEmpty { dict[Self.scrollAnchorPersistenceKeyMixesSearch] = scrollCoordinator.mixesSearchScrollAnchorId }
        if !dict.isEmpty { PersistenceService.saveScrollAnchorIds(dict) }
    }

    private func schedulePersistScrollAnchors() {
        scrollCoordinator.persistScrollTask?.cancel()
        scrollCoordinator.persistScrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            persistScrollAnchors()
        }
    }

    private func persistScrollAnchorsNow() {
        scrollCoordinator.persistScrollTask?.cancel()
        scrollCoordinator.persistScrollTask = nil
        persistScrollAnchors()
    }

    private func isRelevantScrollAnchorId(_ id: String, for context: ScrollContext) -> Bool {
        if id == Self.scrollTopAnchorId { return true }
        switch context {
        case .sounds:
            return id.hasPrefix("category-")
        case .mixes:
            return id.hasPrefix("mix-category-")
        case .soundsSearch:
            return id.hasPrefix("search-category-")
        case .mixesSearch:
            return id.hasPrefix("mix-search-")
        }
    }

    private func scheduleSoundsScrollRestore(for context: ScrollContext, scrollToTopFirst: Bool) {
        let rawTargetId = storedScrollAnchorId(for: context)
        let targetId = isRelevantScrollAnchorId(rawTargetId, for: context) ? rawTargetId : Self.scrollTopAnchorId
        scrollCoordinator.soundsRestoreTask?.cancel()
        scrollCoordinator.soundsRestoreGeneration += 1
        let generation = scrollCoordinator.soundsRestoreGeneration
        scrollCoordinator.soundsRestoreTask = Task { @MainActor in
            scrollCoordinator.suppressSoundsScrollMemoryUpdates = true
            defer {
                if scrollCoordinator.soundsRestoreGeneration == generation {
                    scrollCoordinator.suppressSoundsScrollMemoryUpdates = false
                }
            }
            if scrollToTopFirst {
                soundsScrollPosition = Self.scrollTopAnchorId
                try? await Task.sleep(nanoseconds: 70_000_000)
                guard !Task.isCancelled, scrollCoordinator.soundsRestoreGeneration == generation else { return }
            }
            soundsScrollPosition = targetId
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled, scrollCoordinator.soundsRestoreGeneration == generation else { return }
            soundsScrollPosition = targetId
        }
    }

    private func scheduleMixesScrollRestore(for context: ScrollContext, scrollToTopFirst: Bool) {
        let rawTargetId = storedScrollAnchorId(for: context)
        let targetId = isRelevantScrollAnchorId(rawTargetId, for: context) ? rawTargetId : Self.scrollTopAnchorId
        scrollCoordinator.mixesRestoreTask?.cancel()
        scrollCoordinator.mixesRestoreGeneration += 1
        let generation = scrollCoordinator.mixesRestoreGeneration
        scrollCoordinator.mixesRestoreTask = Task { @MainActor in
            scrollCoordinator.suppressMixesScrollMemoryUpdates = true
            defer {
                if scrollCoordinator.mixesRestoreGeneration == generation {
                    scrollCoordinator.suppressMixesScrollMemoryUpdates = false
                }
            }
            if scrollToTopFirst {
                mixesScrollPosition = Self.scrollTopAnchorId
                try? await Task.sleep(nanoseconds: 70_000_000)
                guard !Task.isCancelled, scrollCoordinator.mixesRestoreGeneration == generation else { return }
            }
            mixesScrollPosition = targetId
            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled, scrollCoordinator.mixesRestoreGeneration == generation else { return }
            mixesScrollPosition = targetId
        }
    }

    private func requestSectionChange(to newSection: MainSection) {
        guard selectedSection != newSection else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedSection = newSection
        }
    }

    private var mainScrollContent: some View {
        ZStack {
            soundsScrollContent
                .opacity(selectedSection == .sounds ? 1 : 0)
                .allowsHitTesting(selectedSection == .sounds)
                .accessibilityHidden(selectedSection != .sounds)
            mixesScrollContent
                .opacity(selectedSection == .mixes ? 1 : 0)
                .allowsHitTesting(selectedSection == .mixes)
                .accessibilityHidden(selectedSection != .mixes)
        }
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
            set: { store.showSavePresetSheet = $0 }
        )) {
            SavePresetSheet(store: store) {
                store.showSavePresetSheet = false
            }
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
            guard !scrollCoordinator.suppressSoundsScrollMemoryUpdates else { return }
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
            guard !scrollCoordinator.didRestoreSounds else { return }
            scrollCoordinator.didRestoreSounds = true
            let context = scrollContext(for: .sounds, searchQuery: store.searchQuery)
            if scrollCoordinator.forceInitialSoundsTop && store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // En el primer arranque mostramos "Currently playing" en la parte superior.
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: context)
                scheduleSoundsScrollRestore(for: context, scrollToTopFirst: true)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    scheduleSoundsScrollRestore(for: context, scrollToTopFirst: true)
                }
                scrollCoordinator.forceInitialSoundsTop = false
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
            .padding(.top, contentTopPadding)
            .padding(.bottom, (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large) + 88)
        }
        .scrollPosition(id: $mixesScrollPosition, anchor: .top)
        .onScrollPhaseChange { _, phase in
            guard selectedSection == .mixes else { return }
            isUserScrolling = phase != .idle
        }
        .onChange(of: mixesScrollPosition) { _, newValue in
            guard !scrollCoordinator.suppressMixesScrollMemoryUpdates else { return }
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
            guard !scrollCoordinator.didRestoreMixes else { return }
            scrollCoordinator.didRestoreMixes = true
            let context = scrollContext(for: .mixes, searchQuery: store.searchQuery)
            if scrollCoordinator.forceInitialMixesTop && store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // En el primer arranque mostramos el inicio de la lista en Mixes.
                setStoredScrollAnchorId(Self.scrollTopAnchorId, for: context)
                scheduleMixesScrollRestore(for: context, scrollToTopFirst: true)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    scheduleMixesScrollRestore(for: context, scrollToTopFirst: true)
                }
                scrollCoordinator.forceInitialMixesTop = false
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
        let availableToolbarWidth = windowWidth
        if availableToolbarWidth >= toolbarCompactThreshold {
            ToolbarItem(placement: .principal) {
                if availableToolbarWidth >= toolbarMediumThreshold {
                    principalToolbarContent
                } else {
                    sectionPickerMenu
                }
            }
        } else {
            ToolbarItem(placement: .principal) {
                compactToolbarMenu
            }
        }
        ToolbarItem(placement: .automatic) {
            ToolbarSearchField(
                text: $store.searchQuery,
                placeholder: L10n.searchPlaceholder,
                requestFocus: $requestToolbarSearchFocus,
                height: toolbarSearchFieldHeight
            )
            .frame(width: toolbarSearchFieldWidth, height: toolbarSearchFieldHeight)
            .padding(.vertical, toolbarSearchFieldFocusPadding)
            .offset(y: toolbarSearchFieldYOffset)
        }
    }

    /// Menú único de la barra cuando el ancho es insuficiente; evita el desbordamiento del sistema.
    private var compactToolbarMenu: some View {
        Menu {
            Button(L10n.sounds) { requestSectionChange(to: .sounds) }
            Button(L10n.mixes) { requestSectionChange(to: .mixes) }
            Divider()
            Button(L10n.search + "...") {
                requestToolbarSearchFocus = true
            }
            .keyboardShortcut("f", modifiers: [.command])
            Divider()
            Button(store.isPlaying ? L10n.pause : L10n.play) { store.togglePlay() }
                .disabled(!store.hasSelection)
            Button(L10n.shuffle) { store.shuffle() }
            Button(L10n.nextMix) { store.playNextRandomMix() }
            Divider()
            Button(L10n.unselectAll) { store.unselectAll() }
                .disabled(!store.hasSelection)
        } label: {
            Image(systemName: "line.3.horizontal.circle")
        }
        .offset(x: toolbarContentOffset)
        .help(L10n.controls)
    }

    private func setupOnAppear() {
        let w = CGFloat(persistedSidebarWidth)
        sidebarWidth = min(sidebarWidthMax, max(sidebarWidthMin, w))
        updateSidebarForWindowWidth(windowWidth)
        let anchors = PersistenceService.loadScrollAnchorIds()
        if let v = anchors[Self.scrollAnchorPersistenceKeySounds], !v.isEmpty { scrollCoordinator.soundsScrollAnchorId = v }
        if let v = anchors[Self.scrollAnchorPersistenceKeyMixes], !v.isEmpty { scrollCoordinator.mixesScrollAnchorId = v }
        if let v = anchors[Self.scrollAnchorPersistenceKeySoundsSearch], !v.isEmpty { scrollCoordinator.soundsSearchScrollAnchorId = v }
        if let v = anchors[Self.scrollAnchorPersistenceKeyMixesSearch], !v.isEmpty { scrollCoordinator.mixesSearchScrollAnchorId = v }
        scrollCoordinator.forceInitialSoundsTop = true
        scrollCoordinator.forceInitialMixesTop = true
        MediaKeyHandler.shared.setup()
        MediaKeyHandler.shared.setToggleHandler { store.togglePlay() }
        MediaKeyHandler.shared.setNextTrackHandler { store.playNextRandomMix() }
        MediaKeyHandler.shared.updateNowPlaying(isPlaying: store.isPlaying)
    }

    /// Mantiene la sidebar estable al redimensionar la ventana:
    /// - se auto-oculta si la ventana es demasiado estrecha (con hysteresis para evitar parpadeos)
    /// - si está visible, ajusta el ancho para no "aplastar" el contenido principal
    private func updateSidebarForWindowWidth(_ : CGFloat) {
        // Si la sidebar está visible, clamp al ancho "deseado" persistido.
        if sidebarResizeStartWidth == 0 {
            sidebarWidth = clampedSidebarWidth()
        } else {
            // Durante el drag, solo clamp a min/max propios.
            sidebarWidth = min(sidebarWidth, sidebarWidthMax)
        }
    }

    private func maxSidebarWidth() -> CGFloat {
        sidebarWidthMax
    }

    private func clampedSidebarWidth() -> CGFloat {
        let desired = CGFloat(persistedSidebarWidth)
        return min(sidebarWidthMax, max(sidebarWidthMin, desired))
    }

    private var principalToolbarContent: some View {
        Group {
            if #available(macOS 26.0, *) {
                // En Tahoe el segmented se ve "inflado" en toolbars; reducimos padding y quitamos el pill extra.
                segmentedPicker
                    .controlSize(.regular)
                    .frame(height: 26)
                    .fixedSize()
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
            } else {
                segmentedPicker
                    .controlSize(.large)
                    .frame(width: 210, height: 28)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(PlatformColor.windowBackground.opacity(0.9))
                    }
            }
        }
        .offset(x: toolbarContentOffset)
        .accessibilityLabel(L10n.section)
        .accessibilityValue(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
    }

    private var segmentedPicker: some View {
        Picker(
            L10n.section,
            selection: Binding(
                get: { selectedSection },
                set: { requestSectionChange(to: $0) }
            )
        ) {
            Text(L10n.sounds).tag(MainSection.sounds)
            Text(L10n.mixes).tag(MainSection.mixes)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    /// Selector Sounds/Mixes como menú desplegable cuando hay poco espacio horizontal.
    private var sectionPickerMenu: some View {
        Menu {
            Button(L10n.sounds) { requestSectionChange(to: .sounds) }
            Button(L10n.mixes) { requestSectionChange(to: .mixes) }
        } label: {
            HStack(spacing: 4) {
                Text(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .menuStyle(.borderlessButton)
        .frame(minWidth: 44)
        .offset(x: toolbarContentOffset)
        .accessibilityLabel(L10n.section)
        .accessibilityValue(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
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
        .onHover { inside in
            if inside {
                NSCursor.resizeLeftRight.push()
            } else {
                NSCursor.pop()
            }
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    if sidebarResizeStartWidth == 0 {
                        sidebarResizeStartWidth = sidebarWidth
                    }
                    let newWidth = sidebarResizeStartWidth + value.translation.width
                    let maxAllowed = maxSidebarWidth()
                    let clamped = min(maxAllowed, max(sidebarWidthMin, newWidth))
                    let snapped = (clamped / sidebarResizeStep).rounded() * sidebarResizeStep
                    if abs(snapped - sidebarWidth) >= sidebarResizeStep / 2 {
                        sidebarWidth = snapped
                    }
                }
                .onEnded { _ in
                    persistedSidebarWidth = Double(sidebarWidth)
                    sidebarResizeStartWidth = 0
                }
        )
        .accessibilityLabel(L10n.resizeSidebar)
        .accessibilityHint(L10n.resizeSidebarHint)
    }

    /// Sección Mixes: categorías temáticas con mixes aplicables (moodist_presets_en).
    private var mixesPlaceholderSection: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
            ForEach(MixesData.categories, id: \.id) { category in
                MixCategoryView(
                    category: category,
                    store: store,
                    mixesToShow: category.id == MixesData.custom.id ? store.presets.map { $0.toMix() } : nil,
                    isExpanded: Binding(
                        get: { mixCategoryExpandedStates[category.id] ?? true },
                        set: { mixCategoryExpandedStates[category.id] = $0 }
                    )
                )
                .id("mix-category-\(category.id)")
            }
        }
        .onAppear {
            // Inicializar estados si están vacíos
            if mixCategoryExpandedStates.isEmpty {
                for category in MixesData.categories {
                    mixCategoryExpandedStates[category.id] = true
                }
            }
        }
    }

    /// Resultados de búsqueda en Mixes: filtra por nombre de mix o título de categoría.
    private var mixesSearchResultsSection: some View {
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

    private var currentlyPlayingSection: some View {
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
        // Mismo padding horizontal que CategoryView para alinear con categorías y filas de abajo.
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
                        Button(action: { store.promptSaveCurrentPreset() }) {
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
                    Button(action: { store.unselectAll() }) {
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
                        timerInlineRow(remainingSeconds: timer.remainingSeconds)
                    }
                }
            }
            if store.hasSelection {
                let playingSounds = store.selectedIds
                    .compactMap { SoundsData.allSoundsById[$0] }
                    .sorted { L10n.soundLabel($0.id).localizedStandardCompare(L10n.soundLabel($1.id)) == .orderedAscending }
                LazyVStack(spacing: MoodistTheme.Spacing.small) {
                    ForEach(playingSounds, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                    }
                }
            } else {
                Text(L10n.noSoundsPlaying)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, MoodistTheme.Spacing.small)
            }
        }
        .padding(.horizontal, sectionHorizontalPadding)
        .padding(.vertical, isNarrow ? MoodistTheme.Spacing.xSmall : MoodistTheme.Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.currentlyPlaying)
    }

    private func timerInlineRow(remainingSeconds: Int) -> some View {
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
            Button(action: { store.cancelSleepTimer() }) {
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

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xLarge) {
            ForEach(SoundsData.categories, id: \.id) { category in
                CategoryView(
                    category: category,
                    store: store,
                    isExpanded: Binding(
                        get: { categoryExpandedStates[category.id] ?? true },
                        set: { categoryExpandedStates[category.id] = $0 }
                    )
                )
                .id("category-\(category.id)")
            }
        }
        .onAppear {
            // Inicializar estados si están vacíos
            if categoryExpandedStates.isEmpty {
                for category in SoundsData.categories {
                    categoryExpandedStates[category.id] = true
                }
            }
        }
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

    private var allMixCategoriesExpanded: Bool {
        MixesData.categories.allSatisfy { mixCategoryExpandedStates[$0.id] ?? true }
    }

    private func toggleAllMixCategories() {
        let shouldExpand = !allMixCategoriesExpanded
        withAnimation(.easeInOut(duration: 0.2)) {
            for category in MixesData.categories {
                mixCategoryExpandedStates[category.id] = shouldExpand
            }
        }
    }

    /// Motor de búsqueda: filtra categorías y sonidos por texto (label o título de categoría).
    private var searchResultsSection: some View {
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

// MARK: - Save Mix sheet (SwiftUI; evita NSAlert y bloqueos)

private struct SaveMixIconOption: Identifiable {
    let id: String
    let sfSymbolName: String
    let displayName: String
}

private let saveMixIconOptions: [SaveMixIconOption] = [
    SaveMixIconOption(id: "sparkles", sfSymbolName: "sparkles", displayName: "Sparkles"),
    SaveMixIconOption(id: "leaf", sfSymbolName: "leaf.fill", displayName: "Leaf"),
    SaveMixIconOption(id: "moon", sfSymbolName: "moon.zzz.fill", displayName: "Moon / Sleep"),
    SaveMixIconOption(id: "rain", sfSymbolName: "cloud.rain.fill", displayName: "Rain"),
    SaveMixIconOption(id: "wind", sfSymbolName: "wind", displayName: "Wind"),
    SaveMixIconOption(id: "waves", sfSymbolName: "wave.3.forward", displayName: "Waves"),
    SaveMixIconOption(id: "flame", sfSymbolName: "flame.fill", displayName: "Flame"),
    SaveMixIconOption(id: "music", sfSymbolName: "music.note", displayName: "Music note"),
    SaveMixIconOption(id: "drop", sfSymbolName: "drop.fill", displayName: "Drop"),
    SaveMixIconOption(id: "snow", sfSymbolName: "snowflake", displayName: "Snowflake"),
    SaveMixIconOption(id: "sun", sfSymbolName: "sun.max.fill", displayName: "Sun"),
    SaveMixIconOption(id: "moon2", sfSymbolName: "moon.stars.fill", displayName: "Night"),
    SaveMixIconOption(id: "tree", sfSymbolName: "leaf.circle.fill", displayName: "Tree / Nature"),
    SaveMixIconOption(id: "bird", sfSymbolName: "bird.fill", displayName: "Bird"),
    SaveMixIconOption(id: "fish", sfSymbolName: "fish.fill", displayName: "Fish"),
    SaveMixIconOption(id: "paw", sfSymbolName: "pawprint.fill", displayName: "Paw"),
    SaveMixIconOption(id: "heart", sfSymbolName: "heart.fill", displayName: "Heart"),
    SaveMixIconOption(id: "star", sfSymbolName: "star.fill", displayName: "Star"),
    SaveMixIconOption(id: "book", sfSymbolName: "book.fill", displayName: "Book"),
    SaveMixIconOption(id: "cup", sfSymbolName: "cup.and.saucer.fill", displayName: "Coffee"),
    SaveMixIconOption(id: "house", sfSymbolName: "house.fill", displayName: "Home"),
    SaveMixIconOption(id: "beach", sfSymbolName: "beach.umbrella.fill", displayName: "Beach"),
    SaveMixIconOption(id: "water", sfSymbolName: "water.waves", displayName: "Water"),
    SaveMixIconOption(id: "bolt", sfSymbolName: "bolt.fill", displayName: "Lightning"),
    SaveMixIconOption(id: "globe", sfSymbolName: "globe", displayName: "Globe"),
    SaveMixIconOption(id: "airplane", sfSymbolName: "airplane", displayName: "Airplane"),
    SaveMixIconOption(id: "car", sfSymbolName: "car.fill", displayName: "Car"),
    SaveMixIconOption(id: "headphones", sfSymbolName: "headphones", displayName: "Headphones"),
    SaveMixIconOption(id: "speaker", sfSymbolName: "speaker.wave.2.fill", displayName: "Speaker"),
]

private struct SavePresetSheet: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var mixName = ""
    @State private var selectedIconIndex = 0
    @State private var isCancelHovered = false
    @State private var isSaveHovered = false
    @FocusState private var isNameFocused: Bool

    private var canSave: Bool {
        !mixName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentIconOption: SaveMixIconOption {
        saveMixIconOptions.indices.contains(selectedIconIndex)
            ? saveMixIconOptions[selectedIconIndex]
            : saveMixIconOptions[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Cabecera
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

            // Campo nombre (Enter guarda si hay nombre)
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

            // Icono (grid visual)
            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                Text(L10n.iconLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)

                let columns = [GridItem(.adaptive(minimum: 40, maximum: 52), spacing: MoodistTheme.Spacing.small)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: MoodistTheme.Spacing.small) {
                    ForEach(Array(saveMixIconOptions.enumerated()), id: \.element.id) { index, option in
                        let isSelected = index == selectedIconIndex
                        Button {
                            selectedIconIndex = index
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                                    .fill(isSelected ? MoodistTheme.Colors.selectedBackground.opacity(0.9) : MoodistTheme.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                                            .strokeBorder(isSelected ? MoodistTheme.Colors.accent.opacity(0.9) : Color.primary.opacity(0.12),
                                                          lineWidth: isSelected ? 1.5 : 1)
                                    )
                                Image(systemName: option.sfSymbolName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(isSelected ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .help(option.displayName)
                        .accessibilityLabel(option.displayName)
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                .accessibilityHint(L10n.saveMixIconMenuHint)

                Text(L10n.saveMixIconLabel(currentIconOption.displayName))
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, MoodistTheme.Spacing.xLarge)

            // Botones
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
        .frame(width: 360)
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

private struct HeaderActionButtonStyle: ButtonStyle {
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
