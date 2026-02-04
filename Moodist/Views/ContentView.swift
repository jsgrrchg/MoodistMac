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
private let toolbarBackdropTintOpacity: Double = 0.34
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

private struct ScrollAnchorOffsetsKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct ScrollAnchorReporter: View {
    let id: String
    let coordinateSpace: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollAnchorOffsetsKey.self,
                value: [id: proxy.frame(in: .named(coordinateSpace)).minY]
            )
        }
    }
}

/// Barra de búsqueda nativa de macOS (NSSearchField con estilo estándar de Apple).
private struct ToolbarSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    @Binding var requestFocus: Bool

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField(string: "")
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.controlSize = .small
        (field.cell as? NSSearchFieldCell)?.controlSize = .small
        field.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        field.sendsSearchStringImmediately = true
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 28).isActive = true
        // Sin anillo de foco azul: el campo sigue siendo focusable pero no muestra el contorno.
        field.focusRingType = .none
        // Estilo nativo: bisel redondeado estándar de macOS (Human Interface Guidelines).
        (field.cell as? NSSearchFieldCell)?.bezelStyle = .roundedBezel
        return field
    }

    func updateNSView(_ nsView: NSSearchField, context: Context) {
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

/// Diccionario estático para búsquedas O(1) de sonidos por ID.
private let allSoundsDict: [String: Sound] = {
    Dictionary(uniqueKeysWithValues: SoundsData.categories.flatMap(\.sounds).map { ($0.id, $0) })
}()

struct ContentView: View {
    @EnvironmentObject var store: SoundStore
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PersistenceService.textSizeKey) private var textSizeRaw = "medium"
    @AppStorage(PersistenceService.transparencyEnabledKey) private var transparencyEnabled = true
    /// Preferencia del usuario (toggle en la toolbar). La visibilidad final también depende del auto-hide.
    @State private var sidebarUserVisible = true
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
    /// Estado para el gesto de deslizamiento horizontal
    @State private var swipeOffset: CGFloat = 0
    @State private var isSwiping: Bool = false

    @State private var soundsScrollAnchorId: String = Self.scrollTopAnchorId
    @State private var mixesScrollAnchorId: String = Self.scrollTopAnchorId
    @State private var soundsSearchScrollAnchorId: String = Self.scrollTopAnchorId
    @State private var mixesSearchScrollAnchorId: String = Self.scrollTopAnchorId
    @State private var suppressScrollMemoryUpdates = false

    private var isSidebarVisible: Bool {
        sidebarUserVisible
    }

    var body: some View {
        ZStack(alignment: .leading) {
            GeometryReader { proxy in
                let contentWidth = max(0, proxy.size.width - (isSidebarVisible ? sidebarWidth : 0))
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
                selectedSection = .sounds
            case SoundStore.mainSectionMixes:
                selectedSection = .mixes
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
            .overlay(alignment: .trailing) {
                sidebarResizeHandle
            }
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
            .onPreferenceChange(ContentWidthKey.self) { contentAreaWidth = $0 }
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
        .onPreferenceChange(ContentWidthKey.self) { contentAreaWidth = $0 }
    }

    private static let scrollTopAnchorId = "mainScrollTop"
    private static let scrollCoordinateSpaceName = "mainScrollCoordinateSpace"

    private enum ScrollContext {
        case sounds
        case mixes
        case soundsSearch
        case mixesSearch
    }

    private var scrollContext: ScrollContext {
        let isSearching = !store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if selectedSection == .mixes {
            return isSearching ? .mixesSearch : .mixes
        }
        return isSearching ? .soundsSearch : .sounds
    }

    private func storedScrollAnchorId(for context: ScrollContext) -> String {
        switch context {
        case .sounds:
            return soundsScrollAnchorId
        case .mixes:
            return mixesScrollAnchorId
        case .soundsSearch:
            return soundsSearchScrollAnchorId
        case .mixesSearch:
            return mixesSearchScrollAnchorId
        }
    }

    private func setStoredScrollAnchorId(_ id: String, for context: ScrollContext) {
        switch context {
        case .sounds:
            soundsScrollAnchorId = id
        case .mixes:
            mixesScrollAnchorId = id
        case .soundsSearch:
            soundsSearchScrollAnchorId = id
        case .mixesSearch:
            mixesSearchScrollAnchorId = id
        }
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

    private func bestScrollAnchorId(from offsets: [String: CGFloat]) -> String? {
        guard !offsets.isEmpty else { return nil }
        if let best = offsets.filter({ $0.value <= 0 }).max(by: { $0.value < $1.value }) {
            return best.key
        }
        return offsets.min(by: { $0.value < $1.value })?.key
    }

    private func updateScrollMemory(with offsets: [String: CGFloat]) {
        guard !suppressScrollMemoryUpdates else { return }
        let context = scrollContext
        let relevant = offsets.filter { isRelevantScrollAnchorId($0.key, for: context) }
        guard let bestId = bestScrollAnchorId(from: relevant) else { return }
        setStoredScrollAnchorId(bestId, for: context)
    }

    private func restoreScrollPosition(using proxy: ScrollViewProxy) {
        let context = scrollContext
        let target = storedScrollAnchorId(for: context)
        proxy.scrollTo(target, anchor: .top)
    }

    private var mainScrollContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: contentAreaWidth < 400 ? MoodistTheme.Spacing.medium : MoodistTheme.Spacing.xLarge) {
                    Color.clear
                        .frame(height: 0)
                        .id(Self.scrollTopAnchorId)
                        .background(ScrollAnchorReporter(id: Self.scrollTopAnchorId, coordinateSpace: Self.scrollCoordinateSpaceName))
                    mainSections
                }
                .id(selectedSection)
                .padding(.horizontal, contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large)
                .padding(.top, selectedSection == .mixes
                         ? (MoodistTheme.Spacing.xSmall + titlebarContentInset)
                         : (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large) + titlebarContentInset)
                .padding(.bottom, (contentAreaWidth < 400 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.large) + 88)
            }
            .coordinateSpace(name: Self.scrollCoordinateSpaceName)
            .onPreferenceChange(ScrollAnchorOffsetsKey.self) { offsets in
                updateScrollMemory(with: offsets)
            }
            .onChange(of: store.searchQuery) { _, _ in
                proxy.scrollTo(Self.scrollTopAnchorId, anchor: .top)
            }
            .onChange(of: selectedSection) { _, _ in
                // Recordar y restaurar scroll por sección (Sounds/Mixes). Pequeño delay para que el nuevo contenido esté layoutado.
                suppressScrollMemoryUpdates = true
                DispatchQueue.main.async {
                    restoreScrollPosition(using: proxy)
                    // Evita que el estado del nuevo tab se "contamine" con el offset del tab anterior
                    // mientras se aplica el scroll programático.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        suppressScrollMemoryUpdates = false
                    }
                }
            }
        }
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // Solo procesar si el movimiento es principalmente horizontal
                    // Esto permite que el scroll vertical funcione normalmente
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    if horizontalMovement > verticalMovement * 2.0 {
                        isSwiping = true
                        swipeOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    isSwiping = false
                    let threshold: CGFloat = 60
                    
                    // Solo cambiar si el movimiento fue principalmente horizontal
                    let horizontalMovement = abs(value.translation.width)
                    let verticalMovement = abs(value.translation.height)
                    
                    guard horizontalMovement > verticalMovement * 2.0 else {
                        swipeOffset = 0
                        return
                    }
                    
                    // Deslizar hacia la izquierda (negativo) = ir a Mixes
                    // Deslizar hacia la derecha (positivo) = ir a Sounds
                    if value.translation.width < -threshold {
                        // Cambiar a Mixes si estamos en Sounds
                        if selectedSection == .sounds {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSection = .mixes
                            }
                        }
                    } else if value.translation.width > threshold {
                        // Cambiar a Sounds si estamos en Mixes
                        if selectedSection == .mixes {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedSection = .sounds
                            }
                        }
                    }
                    
                    swipeOffset = 0
                }
        )
    }

    private var mainSections: some View {
        Group {
            if selectedSection == .mixes {
                if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    mixesPlaceholderSection
                } else {
                    mixesSearchResultsSection
                }
            } else {
                if store.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    currentlyPlayingSection
                    categoriesSection
                } else {
                    searchResultsSection
                }
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
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        sidebarUserVisible.toggle()
                    }
                    updateSidebarForWindowWidth(windowWidth)
                }) {
                    Image(systemName: sidebarUserVisible ? "sidebar.left" : "sidebar.leading")
                }
                .help(sidebarUserVisible ? L10n.sidebarHide : L10n.sidebarShow)
            }
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
        if selectedSection == .sounds {
            ToolbarItem(placement: .automatic) {
                Button(action: toggleAllCategories) {
                    Image(systemName: allCategoriesExpanded ? "chevron.down.circle" : "chevron.right.circle")
                }
                .buttonStyle(.plain)
                .help(allCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
            }
        }
        if selectedSection == .mixes {
            ToolbarItem(placement: .automatic) {
                Button(action: toggleAllMixCategories) {
                    Image(systemName: allMixCategoriesExpanded ? "chevron.down.circle" : "chevron.right.circle")
                }
                .buttonStyle(.plain)
                .help(allMixCategoriesExpanded ? L10n.collapseAllCategories : L10n.expandAllCategories)
            }
        }
        ToolbarItem(placement: .automatic) {
            ToolbarSearchField(
                text: $store.searchQuery,
                placeholder: L10n.searchPlaceholder,
                requestFocus: $requestToolbarSearchFocus
            )
            .frame(width: toolbarSearchFieldWidth, height: 28)
            .offset(y: toolbarSearchFieldYOffset)
        }
    }

    /// Menú único de la barra cuando el ancho es insuficiente; evita el desbordamiento del sistema.
    private var compactToolbarMenu: some View {
        Menu {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    sidebarUserVisible.toggle()
                }
                updateSidebarForWindowWidth(windowWidth)
            }) {
                Text(sidebarUserVisible ? L10n.sidebarHide : L10n.sidebarShow)
            }
            Divider()
            Button(L10n.sounds) { selectedSection = .sounds }
            Button(L10n.mixes) { selectedSection = .mixes }
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
        Picker(L10n.section, selection: $selectedSection) {
            Text(L10n.sounds).tag(MainSection.sounds)
            Text(L10n.mixes).tag(MainSection.mixes)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .controlSize(.large)
        .frame(width: 210, height: 28)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(PlatformColor.windowBackground.opacity(0.9))
        }
        .offset(x: toolbarContentOffset)
        .accessibilityLabel(L10n.section)
        .accessibilityValue(selectedSection == .sounds ? L10n.sounds : L10n.mixes)
    }

    /// Selector Sounds/Mixes como menú desplegable cuando hay poco espacio horizontal.
    private var sectionPickerMenu: some View {
        Menu {
            Button(L10n.sounds) { selectedSection = .sounds }
            Button(L10n.mixes) { selectedSection = .mixes }
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

    private var topControlsBackdrop: some View {
        let height = toolbarBackdropHeight + toolbarBackdropFadeHeight
        return ZStack {
            // Solo la barra lateral tiene frosting; la barra superior es opaca para buena legibilidad.
            PlatformColor.windowBackground
        }
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
        .ignoresSafeArea(.container, edges: .top)
        .allowsHitTesting(false)
    }

    private var sidebarResizeHandle: some View {
        Color.clear
            .frame(width: 10)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if sidebarResizeStartWidth == 0 {
                            sidebarResizeStartWidth = sidebarWidth
                        }
                        let newWidth = sidebarResizeStartWidth + value.translation.width
                        let maxAllowed = maxSidebarWidth()
                        sidebarWidth = min(maxAllowed, max(sidebarWidthMin, newWidth))
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
                .background(ScrollAnchorReporter(id: "mix-category-\(category.id)", coordinateSpace: Self.scrollCoordinateSpaceName))
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
                            .background(ScrollAnchorReporter(id: "mix-search-\(category.id)", coordinateSpace: Self.scrollCoordinateSpaceName))
                    }
                }
            }
        }
    }

    private var currentlyPlayingSection: some View {
        let title: String = {
            guard let mixName = store.displayedMixName else { return L10n.currentlyPlaying }
            // En ventanas angostas evitamos prefijos largos para no romper el layout.
            if contentAreaWidth < 420 { return mixName }
            return "\(L10n.currentlyPlaying) / \(mixName)"
        }()

        return VStack(alignment: .leading, spacing: MoodistTheme.Spacing.small) {
            HStack(spacing: MoodistTheme.Spacing.xSmall) {
                Text(title)
                    .font(MoodistTheme.Typography.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(1)
                Image(systemName: store.isPlaying ? "waveform" : "waveform.slash")
                    .font(.system(size: 14))
                    .foregroundStyle(store.isPlaying ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                if store.hasActiveTimer {
                    TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                        if let timer = store.activeTimer {
                            timerRemainingBadge(remainingSeconds: timer.remainingSeconds)
                        }
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: MoodistTheme.Spacing.small) {
                    if store.canSaveCustomMix {
                        Button(L10n.addCustom) { store.promptSaveCurrentPreset() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(MoodistTheme.Colors.accent)
                            .help(L10n.presetSaveCurrent)
                            .accessibilityLabel(L10n.addCustom)
                    }
                    Button(L10n.clear) { store.unselectAll() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!store.hasSelection)
                        .help(L10n.unselectAll)
                        .accessibilityLabel(L10n.clear)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            if store.hasSelection {
                let playingSounds = store.selectedIds
                    .compactMap { allSoundsDict[$0] }
                    .sorted { L10n.soundLabel($0.id).localizedStandardCompare(L10n.soundLabel($1.id)) == .orderedAscending }
                LazyVStack(spacing: MoodistTheme.Spacing.small) {
                    ForEach(playingSounds, id: \.id) { sound in
                        SoundRow(sound: sound, store: store)
                            .id("playing-sound-\(sound.id)")
                    }
                }
            } else {
                Text(L10n.noSoundsPlaying)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, MoodistTheme.Spacing.small)
                    .padding(.horizontal, MoodistTheme.Spacing.medium)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.currentlyPlaying)
    }

    private func timerRemainingBadge(remainingSeconds: Int) -> some View {
        HStack(spacing: MoodistTheme.Spacing.xSmall) {
            Image(systemName: "timer")
                .font(.system(size: 12))
            Text(formatTimerRemaining(seconds: remainingSeconds))
                .font(MoodistTheme.Typography.subheadline)
                .monospacedDigit()
        }
        .foregroundStyle(MoodistTheme.Colors.secondaryText)
        .padding(.horizontal, MoodistTheme.Spacing.small)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                .fill(MoodistTheme.Colors.selectedBackground.opacity(0.5))
        )
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
                .background(ScrollAnchorReporter(id: "category-\(category.id)", coordinateSpace: Self.scrollCoordinateSpaceName))
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
                                        .id("search-sound-\(sound.id)")
                                }
                            }
                        }
                        .padding(.vertical, MoodistTheme.Spacing.small)
                        .padding(.horizontal, contentAreaWidth < 420 ? MoodistTheme.Spacing.small : MoodistTheme.Spacing.medium)
                        .id("search-category-\(category.id)")
                        .background(ScrollAnchorReporter(id: "search-category-\(category.id)", coordinateSpace: Self.scrollCoordinateSpaceName))
                    }
                }
            }
        }
    }
}

// MARK: - Save preset sheet (SwiftUI; evita NSAlert y bloqueos)

private let presetIconOptions: [String] = [
    "sparkles", "leaf.fill", "moon.zzz.fill", "cloud.rain.fill",
    "wind", "wave.3.forward", "flame.fill", "music.note"
]

private struct SavePresetSheet: View {
    @ObservedObject var store: SoundStore
    var onDismiss: () -> Void

    @State private var presetName = ""
    @State private var selectedIconIndex = 0
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: MoodistTheme.Spacing.large) {
            Text(L10n.presetSaveDialogTitle)
                .font(MoodistTheme.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(L10n.presetNamePlaceholder, text: $presetName)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)

            VStack(alignment: .leading, spacing: MoodistTheme.Spacing.xSmall) {
                Text(L10n.iconLabel)
                    .font(MoodistTheme.Typography.subheadline)
                    .foregroundStyle(MoodistTheme.Colors.secondaryText)
                HStack(spacing: MoodistTheme.Spacing.small) {
                    ForEach(Array(presetIconOptions.enumerated()), id: \.offset) { index, iconName in
                        Button {
                            selectedIconIndex = index
                        } label: {
                            Image(systemName: iconName)
                                .font(.system(size: 18))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: MoodistTheme.Radius.small)
                                        .fill(selectedIconIndex == index ? MoodistTheme.Colors.selectedBackground : Color.clear)
                                )
                                .foregroundStyle(selectedIconIndex == index ? MoodistTheme.Colors.accent : MoodistTheme.Colors.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: MoodistTheme.Spacing.small) {
                Spacer()
                Button(L10n.cancel) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.save) { saveAndDismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(MoodistTheme.Spacing.large)
        .frame(width: 320)
        .onAppear { isNameFocused = true }
    }

    private func saveAndDismiss() {
        let name = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let iconName = presetIconOptions.indices.contains(selectedIconIndex) ? presetIconOptions[selectedIconIndex] : "sparkles"
        store.saveCurrentAsPreset(name: name, iconName: iconName)
        onDismiss()
    }
}

#Preview {
    ContentView()
        .environmentObject(SoundStore(audioService: AudioService()))
        .frame(width: 400, height: 600)
}
