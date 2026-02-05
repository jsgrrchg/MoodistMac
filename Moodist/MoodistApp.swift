//
//  MoodistApp.swift
//  MoodistMac
//
//  Punto de entrada macOS (Sequoia 15.0+).
//

import SwiftUI
import AppKit
import Combine
import Sparkle

@main
struct MoodistApp: App {
    @StateObject private var soundStore: SoundStore
    @StateObject private var updatePresenter: UpdateWindowPresenter
    @NSApplicationDelegateAdaptor(MacOSAppDelegate.self) var appDelegate
    @AppStorage(PersistenceService.appearanceModeKey) private var appearanceModeRaw = "system"
    @AppStorage(PersistenceService.accentColorHexKey) private var accentColorRaw = AccentColorChoice.system.rawValue
    private let updateUserDriver: MoodistUpdateUserDriver
    private let updater: SPUUpdater

    init() {
        let audio = AudioService()
        _soundStore = StateObject(wrappedValue: SoundStore(audioService: audio))

        let presenter = UpdateWindowPresenter()
        _updatePresenter = StateObject(wrappedValue: presenter)

        updateUserDriver = MoodistUpdateUserDriver(presenter: presenter)
        updater = SPUUpdater(hostBundle: .main, applicationBundle: .main, userDriver: updateUserDriver, delegate: nil)

        do {
            try updater.start()
        } catch {
            NSLog("Sparkle updater failed to start: %@", String(describing: error))
        }
    }

    private var accentChoice: AccentColorChoice {
        AccentColorChoice(rawValue: accentColorRaw) ?? .system
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearanceModeRaw {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    var body: some Scene {
        Window(L10n.appName, id: "main") {
            ContentView()
                .environmentObject(soundStore)
                .applyAppAccent(accentChoice.accentColor)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    appDelegate.soundStore = soundStore
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands { commandsContent }

        Window(L10n.optionsTitle, id: "options") {
            OptionsView()
                .environmentObject(soundStore)
                .environmentObject(updatePresenter)
                .environment(\.sparkleUpdater, updater)
                .applyAppAccent(accentChoice.accentColor)
                .preferredColorScheme(preferredColorScheme)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 510, height: 650)
    }

    @CommandsBuilder private var commandsContent: some Commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(before: .appSettings) {
                Button(L10n.search + "...") {
                    soundStore.requestSearchFocus = true
                }
                .keyboardShortcut("f", modifiers: [.command])
                Button(L10n.options + "...") {
                    soundStore.showOptionsPanel = true
                }
                .keyboardShortcut(",", modifiers: [.command])
                Button(L10n.exportPreferences) {
                    _ = soundStore.exportPreferences()
                }
                Button(L10n.importPreferences) {
                    _ = soundStore.importPreferences()
                }
            }
            CommandMenu("Playback") {
                Button(soundStore.isPlaying ? L10n.pause : L10n.play) {
                    soundStore.togglePlay()
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!soundStore.hasSelection)

                Button(L10n.shuffle) {
                    soundStore.shuffle()
                }
                .keyboardShortcut("s", modifiers: [.command])

                Button(L10n.nextMix) {
                    soundStore.playNextRandomMix()
                }
                .keyboardShortcut("n", modifiers: [.command])

                Divider()

                Button(L10n.unselectAll) {
                    soundStore.unselectAll()
                }
                .keyboardShortcut("u", modifiers: [.command])
                .disabled(!soundStore.hasSelection)
            }
            CommandMenu(L10n.timer) {
                if let remaining = soundStore.timerRemainingMenuTitle {
                    Text(remaining).disabled(true)
                    Divider()
                }
                Menu(L10n.timerMinutes) {
                    ForEach(SoundStore.timerMenuMinutesPresets, id: \.self) { seconds in
                        Button(soundStore.timerLabel(forSeconds: seconds)) {
                            soundStore.startSleepTimer(durationSeconds: seconds)
                        }
                    }
                }
                Menu(L10n.timerHours) {
                    ForEach(SoundStore.timerMenuHoursPresets, id: \.self) { seconds in
                        Button(soundStore.timerLabel(forSeconds: seconds)) {
                            soundStore.startSleepTimer(durationSeconds: seconds)
                        }
                    }
                }
                Divider()
                Button(L10n.timerCustom) {
                    soundStore.promptCustomTimer()
                }
                if soundStore.hasActiveTimer {
                    Button(L10n.timerStop) {
                        soundStore.cancelSleepTimer()
                    }
                }
            }
            CommandMenu(L10n.sounds) {
                if !soundStore.orderedFavoriteSoundIds.isEmpty {
                    Menu(L10n.favorites) {
                        ForEach(soundStore.orderedFavoriteSoundIds, id: \.self) { soundId in
                            Toggle(isOn: Binding(
                                get: { soundStore.sounds[soundId]?.isSelected ?? false },
                                set: { isOn in
                                    if isOn {
                                        soundStore.select(soundId)
                                    } else {
                                        soundStore.unselect(soundId)
                                    }
                                }
                            )) {
                                Text(L10n.soundLabel(soundId))
                            }
                        }
                    }
                    Divider()
                }
                ForEach(SoundsData.categories, id: \.id) { category in
                    Menu(L10n.categoryTitle(category.id)) {
                        ForEach(category.sounds) { sound in
                            Toggle(isOn: Binding(
                                get: { soundStore.sounds[sound.id]?.isSelected ?? false },
                                set: { isOn in
                                    if isOn {
                                        soundStore.select(sound.id)
                                    } else {
                                        soundStore.unselect(sound.id)
                                    }
                                }
                            )) {
                                Text(L10n.soundLabel(sound.id))
                            }
                        }
                    }
                }
            }
            CommandMenu(L10n.mixes) {
                let mixesById = Dictionary(uniqueKeysWithValues: MixesData.categories.flatMap(\.mixes).map { ($0.id, $0) })
                if !soundStore.favoriteMixIds.isEmpty {
                    Menu(L10n.favorites) {
                        ForEach(soundStore.favoriteMixIds, id: \.self) { mixId in
                            if let mix = mixesById[mixId] {
                                Button(L10n.mixName(mixId)) {
                                    soundStore.applyMix(mix)
                                }
                            }
                        }
                    }
                    Divider()
                }
                ForEach(MixesData.categories, id: \.id) { category in
                    Menu(L10n.mixCategoryTitle(category.id)) {
                        if category.mixes.isEmpty, category.id == MixesData.custom.id {
                            Text(L10n.customMixesEmpty).disabled(true)
                        } else {
                            ForEach(category.mixes) { mix in
                                Button(L10n.mixName(mix.id)) {
                                    soundStore.applyMix(mix)
                                }
                            }
                        }
                    }
                }
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updater)
            }
        }
}

private extension View {
    @ViewBuilder
    func applyAppAccent(_ color: Color?) -> some View {
        if let color {
            self.accentColor(color).tint(color)
        } else {
            self
        }
    }
}

// MARK: - Sparkle Update Checker

/// View model que publica cuando se pueden comprobar actualizaciones
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false
    
    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

/// Vista para el ítem de menú "Buscar actualizaciones..."
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    
    init(updater: SPUUpdater) {
        self.updater = updater
        // Crear el view model para CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Button(L10n.checkForUpdates) {
            updater.checkForUpdates()
        }
        .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}

// MARK: - Environment: Sparkle updater para OptionsView

private struct SparkleUpdaterKey: EnvironmentKey {
    static let defaultValue: SPUUpdater? = nil
}

extension EnvironmentValues {
    var sparkleUpdater: SPUUpdater? {
        get { self[SparkleUpdaterKey.self] }
        set { self[SparkleUpdaterKey.self] = newValue }
    }
}

// MARK: - Notificaciones

extension Notification.Name {
    static let menuBarPreferenceDidChange = Notification.Name("MoodistMac.menuBarPreferenceDidChange")
    static let appearancePreferenceDidChange = Notification.Name("MoodistMac.appearancePreferenceDidChange")
    static let transparencyPreferenceDidChange = Notification.Name("MoodistMac.transparencyPreferenceDidChange")
    static let timerStateDidChange = Notification.Name("MoodistMac.timerStateDidChange")
}

@MainActor
final class MacOSAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private static let mainWindowFrameName = "MoodistMainWindow"
    private static let mainWindowMinSize = CGSize(width: 850, height: 600)
    private static let defaultMainWindowSize = CGSize(width: 900, height: 700)
    private static let maxMainWindowWidth: CGFloat = 1000
    private static let optionsWindowSize = CGSize(width: 510, height: 650)
    private static let menuBarKey = PersistenceService.menuBarEnabledKey
    private static let frameSaveDebounce: DispatchTimeInterval = .milliseconds(250)
    private static let frameRestoreDelay: DispatchTimeInterval = .milliseconds(300)
    weak var soundStore: SoundStore? {
        didSet {
            configureDockObservers()
            updateDockTitle()
        }
    }
    private var statusItem: NSStatusItem?
    private var menuBarObserver: NSObjectProtocol?
    private var appearanceObserver: NSObjectProtocol?
    private var transparencyObserver: NSObjectProtocol?
    private var timerStateObserver: NSObjectProtocol?
    private var windowDidBecomeKeyObserver: NSObjectProtocol?
    private weak var mainWindow: NSWindow?
    private var mainWindowHasRestoredFrame = false
    private var mainWindowObservers: [NSObjectProtocol] = []
    private var dockCancellables = Set<AnyCancellable>()
    private var pendingFrameSave: DispatchWorkItem?
    private var pendingFrameRestore: DispatchWorkItem?
    private var timerMenuUpdate: Timer?
    private weak var timerRemainingMenuItem: NSMenuItem?
    private var spaceKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyAppearanceMode()
        NSWindow.allowsAutomaticWindowTabbing = false
        windowDidBecomeKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let window = note.object as? NSWindow else { return }
            Task { @MainActor in
                self?.configureMainWindowIfNeeded(window)
                self?.configureOptionsWindowIfNeeded(window)
            }
        }
        DispatchQueue.main.async { [weak self] in
            Task { @MainActor in
                self?.configureExistingMainWindow()
                self?.updateMenuBarVisibility()
            }
        }
        // Configurar de nuevo cuando la ventana ya exista (por si se creó después)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            Task { @MainActor in
                self?.configureExistingMainWindow()
            }
        }
        // Dar tiempo a SwiftUI a dar tamaño real a la ventana principal antes de asignar persistencia de frame.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            Task { @MainActor in
                self?.configureExistingMainWindow()
            }
        }
        menuBarObserver = NotificationCenter.default.addObserver(
            forName: .menuBarPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateMenuBarVisibility() }
        }
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: .appearancePreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.applyAppearanceMode()
            }
        }
        transparencyObserver = NotificationCenter.default.addObserver(
            forName: .transparencyPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.configureExistingMainWindow()
            }
        }
        timerStateObserver = NotificationCenter.default.addObserver(
            forName: .timerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.statusItem?.menu != nil {
                    self.statusItem?.menu = self.buildStatusMenu()
                }
            }
        }
        installSpaceKeyMonitor()
    }

    private func installSpaceKeyMonitor() {
        spaceKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 49 else { return event }
            if let window = NSApp.keyWindow, let first = window.firstResponder {
                let isTextInput = first is NSTextView || first is NSTextField
                if isTextInput { return event }
                if let view = first as? NSView {
                    var current: NSView? = view
                    while let v = current {
                        if v is NSSearchField { return event }
                        current = v.superview
                    }
                }
            }
            Task { @MainActor in
                self?.soundStore?.togglePlay()
            }
            return nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = spaceKeyMonitor { NSEvent.removeMonitor(monitor) }
        spaceKeyMonitor = nil
        persistMainWindowFrameNow()
    }

    @MainActor deinit {
        if let monitor = spaceKeyMonitor { NSEvent.removeMonitor(monitor) }
        if let o = menuBarObserver { NotificationCenter.default.removeObserver(o) }
        if let o = appearanceObserver { NotificationCenter.default.removeObserver(o) }
        if let o = transparencyObserver { NotificationCenter.default.removeObserver(o) }
        if let o = timerStateObserver { NotificationCenter.default.removeObserver(o) }
        if let o = windowDidBecomeKeyObserver { NotificationCenter.default.removeObserver(o) }
        stopObservingMainWindow()
        stopTimerMenuUpdates()
    }

    private func applyAppearanceMode() {
        let raw = UserDefaults.standard.string(forKey: PersistenceService.appearanceModeKey) ?? "system"
        switch raw {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    /// Al hacer clic en el Dock sin ventanas visibles, mostrar la ventana principal (oculta).
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindowIfHidden()
            // Asegurar que la ventana que se muestra reciba el frame restaurado (por si es nueva o se recreó).
            DispatchQueue.main.async { [weak self] in
                Task { @MainActor in
                    self?.configureExistingMainWindow()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                Task { @MainActor in
                    self?.configureExistingMainWindow()
                }
            }
        }
        return true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        showMainWindowIfHidden()
        configureExistingMainWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            Task { @MainActor in
                self?.configureExistingMainWindow()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            Task { @MainActor in
                self?.configureExistingMainWindow()
            }
        }
    }
    
    /// Muestra la ventana principal si está oculta (p. ej. tras cerrar con el botón rojo).
    private func showMainWindowIfHidden() {
        if NSApplication.shared.windows.contains(where: { $0.isVisible && $0.canBecomeKey }) { return }
        if let w = mainWindow, !w.isVisible {
            NSApplication.shared.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
            return
        }
        if let w = bestMainWindowCandidate(in: NSApplication.shared.windows), !w.isVisible {
            NSApplication.shared.activate(ignoringOtherApps: true)
            w.makeKeyAndOrderFront(nil)
        }
    }

    private func configureExistingMainWindow() {
        guard let window = bestMainWindowCandidate(in: NSApplication.shared.windows) else { return }
        configureMainWindowIfNeeded(window)
    }

    private func configureOptionsWindowIfNeeded(_ window: NSWindow) {
        guard window.title == L10n.optionsTitle else { return }
        window.styleMask.remove(.resizable)
        window.minSize = Self.optionsWindowSize
        window.maxSize = Self.optionsWindowSize
        let contentSize = window.contentRect(forFrameRect: window.frame).size
        if contentSize.width != Self.optionsWindowSize.width || contentSize.height != Self.optionsWindowSize.height {
            window.setContentSize(Self.optionsWindowSize)
        }
    }

    private func configureMainWindowIfNeeded(_ window: NSWindow) {
        guard isMainWindowCandidate(window) else { return }
        if mainWindow !== window {
            stopObservingMainWindow()
            pendingFrameRestore?.cancel()
            pendingFrameRestore = nil
            mainWindow = window
            mainWindowHasRestoredFrame = false
        }
        configureMainWindow(window)
        scheduleMainWindowRestoreIfNeeded(for: window)
        if mainWindowObservers.isEmpty {
            startObservingMainWindow(window)
        }
    }

    private func scheduleMainWindowRestoreIfNeeded(for window: NSWindow) {
        guard !mainWindowHasRestoredFrame else { return }
        pendingFrameRestore?.cancel()
        let work = DispatchWorkItem { [weak self, weak window] in
            Task { @MainActor in
                guard let self, let window else { return }
                self.pendingFrameRestore = nil
                self.applyRestoredFrame(to: window)
                self.mainWindowHasRestoredFrame = true
            }
        }
        pendingFrameRestore = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.frameRestoreDelay, execute: work)
    }

    private func isMainWindowCandidate(_ window: NSWindow) -> Bool {
        if window.title == L10n.optionsTitle { return false }
        if !window.canBecomeKey { return false }
        let style = window.styleMask
        return style.contains(.titled) && style.contains(.closable) && style.contains(.resizable)
    }

    private func bestMainWindowCandidate(in windows: [NSWindow]) -> NSWindow? {
        let candidates = windows.filter(isMainWindowCandidate)
        return candidates.max(by: { a, b in
            let aKey = a.isKeyWindow ? 1 : 0
            let bKey = b.isKeyWindow ? 1 : 0
            if aKey != bKey { return aKey < bKey }
            let aArea = a.frame.width * a.frame.height
            let bArea = b.frame.width * b.frame.height
            return aArea < bArea
        })
    }

    private func configureMainWindow(_ window: NSWindow) {
        let transparencyEnabled = UserDefaults.standard.object(forKey: PersistenceService.transparencyEnabledKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: PersistenceService.transparencyEnabledKey)
        // Con transparencia: fondo claro para que la barra lateral pueda hacer frosting al estilo Finder (blur del escritorio).
        // Sin transparencia: ventana opaca.
        if transparencyEnabled {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.isOpaque = true
            window.backgroundColor = NSColor.windowBackgroundColor
        }
        window.maxSize = NSSize(width: Self.maxMainWindowWidth, height: CGFloat.greatestFiniteMagnitude)
        window.minSize = NSSize(width: Self.mainWindowMinSize.width, height: Self.mainWindowMinSize.height)
        
        window.tabbingMode = .disallowed
        window.toolbarStyle = .unified
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        // Arrastrar solo desde la barra de título (no desde el contenido).
        window.isMovableByWindowBackground = false
        // Vincular al nombre de frame para que setFrameUsingName/saveFrame usen la misma clave.
        window.setFrameAutosaveName(Self.mainWindowFrameName)
        // Reasignar delegate cada vez para que windowShouldClose nos llegue (SwiftUI puede sobrescribirlo).
        window.delegate = self
    }

    // MARK: - Dock menu

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let isPlaying = soundStore?.isPlaying == true
        let hasSelection = soundStore?.hasSelection == true

        let playItem = NSMenuItem(
            title: isPlaying ? L10n.pause : L10n.play,
            action: #selector(dockTogglePlay),
            keyEquivalent: ""
        )
        playItem.isEnabled = hasSelection
        playItem.target = self
        menu.addItem(playItem)

        let nextItem = NSMenuItem(
            title: L10n.nextMix,
            action: #selector(dockNextMix),
            keyEquivalent: ""
        )
        nextItem.target = self
        menu.addItem(nextItem)

        let shuffleItem = NSMenuItem(
            title: L10n.shuffle,
            action: #selector(dockShuffle),
            keyEquivalent: ""
        )
        shuffleItem.target = self
        menu.addItem(shuffleItem)

        menu.addItem(.separator())
        appendTimerSection(to: menu)

        return menu
    }

    @objc private func dockTogglePlay() {
        soundStore?.togglePlay()
    }

    @objc private func dockNextMix() {
        soundStore?.playNextRandomMix()
    }

    @objc private func dockShuffle() {
        soundStore?.shuffle()
    }

    private func configureDockObservers() {
        dockCancellables.removeAll()
        guard let store = soundStore else { return }

        Publishers.CombineLatest3(
            store.$currentMixId,
            store.$sounds,
            store.$presets
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _ in
            Task { @MainActor in
                self?.updateDockTitle()
            }
        }
        .store(in: &dockCancellables)

        store.$isPlaying
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateDockTitle()
                }
            }
            .store(in: &dockCancellables)
    }

    private func updateDockTitle() {
        NSApp.dockTile.badgeLabel = nil
    }
    
    /// Clave que usa AppKit en UserDefaults para el frame (véase Saving Window Position en Apple).
    private static var windowFrameDefaultsKey: String { "NSWindow Frame \(mainWindowFrameName)" }

    private func startObservingMainWindow(_ window: NSWindow) {
        window.delegate = self
        let center = NotificationCenter.default
        mainWindowObservers = [
            center.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleMainWindowFrameSave()
                }
            },
            center.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleMainWindowFrameSave()
                }
            },
            center.addObserver(
                forName: NSWindow.didEndLiveResizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.scheduleMainWindowFrameSave()
                }
            },
            center.addObserver(
                forName: NSWindow.willCloseNotification,
                object: window,
                queue: .main
            ) { [weak self] note in
                guard let w = note.object as? NSWindow else { return }
                Task { @MainActor in
                    self?.persistFrameNow(for: w)
                    // Solo limpiar si la ventana se cierra de verdad (no si solo se ocultó con orderOut).
                    if self?.mainWindow === w {
                        self?.mainWindow = nil
                        self?.mainWindowHasRestoredFrame = false
                        self?.stopObservingMainWindow()
                    }
                }
            },
        ]
    }
    
    // MARK: - NSWindowDelegate (ocultar en lugar de cerrar la ventana principal)
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender.title == L10n.optionsTitle { return true }
        if !isMainWindowCandidate(sender) { return true }
        persistFrameNow(for: sender)
        sender.orderOut(nil)
        return false
    }

    private func stopObservingMainWindow() {
        pendingFrameSave?.cancel()
        pendingFrameSave = nil
        pendingFrameRestore?.cancel()
        pendingFrameRestore = nil
        for o in mainWindowObservers {
            NotificationCenter.default.removeObserver(o)
        }
        mainWindowObservers.removeAll()
    }

    private func scheduleMainWindowFrameSave() {
        guard let window = mainWindow else { return }
        guard canPersistFrame(window.frame) else { return }
        if window.inLiveResize, pendingFrameRestore != nil {
            pendingFrameRestore?.cancel()
            pendingFrameRestore = nil
            mainWindowHasRestoredFrame = true
        }
        pendingFrameSave?.cancel()
        let work = DispatchWorkItem { [weak self, weak window] in
            Task { @MainActor in
                guard let self, let window else { return }
                self.persistFrameNow(for: window)
            }
        }
        pendingFrameSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.frameSaveDebounce, execute: work)
    }

    private func persistMainWindowFrameNow() {
        if let window = mainWindow ?? bestMainWindowCandidate(in: NSApplication.shared.windows) {
            persistFrameNow(for: window)
        }
    }

    private func persistFrameNow(for window: NSWindow) {
        guard window.title != L10n.optionsTitle else { return }
        guard canPersistFrame(window.frame) else { return }
        window.saveFrame(usingName: Self.mainWindowFrameName)
        UserDefaults.standard.synchronize()
    }

    private func canPersistFrame(_ frame: NSRect) -> Bool {
        frame.size.width >= Self.mainWindowMinSize.width && frame.size.height >= Self.mainWindowMinSize.height
    }
    
    private func applyRestoredFrame(to window: NSWindow) {
        let restored = window.setFrameUsingName(Self.mainWindowFrameName, force: true)
        var frame = window.frame
        let useRestored = restored && canPersistFrame(frame)
        var shouldPersist = false
        
        // Si había un frame guardado pero es inválido (p. ej. 31×24), borrarlo de Preferences para no seguir restaurándolo (reset como en https://apple.stackexchange.com/questions/195479).
        if restored && !useRestored {
            UserDefaults.standard.removeObject(forKey: Self.windowFrameDefaultsKey)
        }

        if !useRestored {
            if !canPersistFrame(frame) {
                frame = defaultMainWindowFrame()
            }
            shouldPersist = true
        }

        frame = sanitizedMainWindowFrame(frame)
        window.setFrame(frame, display: true)
        if shouldPersist {
            persistFrameNow(for: window)
        }
    }

    private func defaultMainWindowFrame() -> NSRect {
        let width = min(Self.defaultMainWindowSize.width, Self.maxMainWindowWidth)
        let height = max(Self.defaultMainWindowSize.height, Self.mainWindowMinSize.height)
        let size = CGSize(width: width, height: height)
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let visible = screen.visibleFrame
            return NSRect(
                x: visible.midX - size.width / 2,
                y: visible.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        }
        return NSRect(origin: .zero, size: size)
    }

    private func sanitizedMainWindowFrame(_ frame: NSRect) -> NSRect {
        guard let screen = screenForFrame(frame) else { return frame }
        let visible = screen.visibleFrame
        var f = frame

        let maxWidth = min(Self.maxMainWindowWidth, visible.width)
        f.size.width = min(max(f.size.width, Self.mainWindowMinSize.width), maxWidth)
        f.size.height = min(max(f.size.height, Self.mainWindowMinSize.height), visible.height)

        f.origin.x = min(max(f.origin.x, visible.minX), visible.maxX - f.size.width)
        f.origin.y = min(max(f.origin.y, visible.minY), visible.maxY - f.size.height)
        return f
    }

    private func screenForFrame(_ frame: NSRect) -> NSScreen? {
        let center = NSPoint(x: frame.midX, y: frame.midY)
        if let hit = NSScreen.screens.first(where: { $0.frame.contains(center) }) {
            return hit
        }

        let best = NSScreen.screens.max { a, b in
            intersectionArea(frame, a.visibleFrame) < intersectionArea(frame, b.visibleFrame)
        }
        if let best, intersectionArea(frame, best.visibleFrame) > 0 {
            return best
        }

        return NSScreen.main ?? NSScreen.screens.first
    }

    private func intersectionArea(_ a: NSRect, _ b: NSRect) -> CGFloat {
        let i = a.intersection(b)
        if i.isNull { return 0 }
        return i.size.width * i.size.height
    }

    // MARK: - Barra de menú (NSStatusItem)

    @MainActor private func updateMenuBarVisibility() {
        let show = UserDefaults.standard.bool(forKey: Self.menuBarKey)
        if show {
            if statusItem == nil { createStatusItem() }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    @MainActor private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Crear icono translúcido con transparencia
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .ultraLight)
        guard let baseImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: L10n.appName)?
            .withSymbolConfiguration(config) else { return }
        
        // Crear imagen con transparencia aplicada (más translúcida)
        let translucentImage = createTranslucentImage(from: baseImage, opacity: 0.5)
        translucentImage.isTemplate = true
        
        guard let button = statusItem?.button else { return }
        button.image = translucentImage
        button.title = ""
        button.appearsDisabled = false
        button.imagePosition = .imageLeading
        // Configurar el botón para que tenga un estilo más translúcido
        button.bezelStyle = .texturedRounded
        
        statusItem?.menu = buildStatusMenu()
    }
    
    /// Crea una imagen translúcida desde una imagen base aplicando opacidad
    private func createTranslucentImage(from image: NSImage, opacity: CGFloat) -> NSImage {
        func fallbackTemplateImage() -> NSImage {
            let fallbackImage = (image.copy() as? NSImage) ?? image
            fallbackImage.isTemplate = true
            return fallbackImage
        }

        let size = image.size
        
        // Crear imagen usando Core Graphics directamente
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            // Fallback: usar la imagen original con opacidad reducida
            return fallbackTemplateImage()
        }
        
        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return fallbackTemplateImage()
        }
        
        // Aplicar opacidad
        context.setAlpha(opacity)
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        guard let renderedCGImage = context.makeImage() else {
            return fallbackTemplateImage()
        }
        
        let translucentImage = NSImage(cgImage: renderedCGImage, size: size)
        translucentImage.isTemplate = true
        return translucentImage
    }

    @MainActor private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let playTitle = (soundStore?.isPlaying == true) ? L10n.pause : L10n.play
        let playItem = NSMenuItem(title: playTitle, action: #selector(menuPlayPause), keyEquivalent: "r")
        playItem.keyEquivalentModifierMask = .command
        playItem.target = self
        menu.addItem(playItem)

        let mixName = soundStore?.displayedMixName ?? L10n.customMix
        let nowPlayingItem = NSMenuItem(title: mixName, action: nil, keyEquivalent: "")
        nowPlayingItem.isEnabled = false
        menu.addItem(nowPlayingItem)

        let nextMixItem = NSMenuItem(title: L10n.nextMix, action: #selector(menuNextMix), keyEquivalent: "")
        nextMixItem.target = self
        menu.addItem(nextMixItem)

        if let remaining = soundStore?.timerRemainingMenuTitle {
            let remainingItem = NSMenuItem(title: remaining, action: nil, keyEquivalent: "")
            remainingItem.isEnabled = false
            menu.addItem(remainingItem)
            timerRemainingMenuItem = remainingItem
        } else {
            timerRemainingMenuItem = nil
        }

        menu.addItem(NSMenuItem.separator())
        appendTimerSection(to: menu)
        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: L10n.openWindow, action: #selector(menuOpenWindow), keyEquivalent: "o")
        openItem.keyEquivalentModifierMask = .command
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.quit, action: #selector(menuQuit), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @MainActor func menuWillOpen(_ menu: NSMenu) {
        guard menu === statusItem?.menu else { return }
        statusItem?.menu = buildStatusMenu()
        startTimerMenuUpdates()
    }

    @MainActor func menuDidClose(_ menu: NSMenu) {
        guard menu === statusItem?.menu else { return }
        stopTimerMenuUpdates()
    }

    @MainActor private func appendTimerSection(to menu: NSMenu) {
        let header = NSMenuItem(title: L10n.timer, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        let minutesSubmenu = NSMenu()
        for seconds in SoundStore.timerMenuMinutesPresets {
            let title = soundStore?.timerLabel(forSeconds: seconds) ?? timerLabelFallback(seconds: seconds)
            let item = NSMenuItem(title: title, action: #selector(menuStartTimer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = seconds
            minutesSubmenu.addItem(item)
        }
        let minutesItem = NSMenuItem(title: L10n.timerMinutes, action: nil, keyEquivalent: "")
        minutesItem.submenu = minutesSubmenu
        menu.addItem(minutesItem)

        let hoursSubmenu = NSMenu()
        for seconds in SoundStore.timerMenuHoursPresets {
            let title = soundStore?.timerLabel(forSeconds: seconds) ?? timerLabelFallback(seconds: seconds)
            let item = NSMenuItem(title: title, action: #selector(menuStartTimer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = seconds
            hoursSubmenu.addItem(item)
        }
        let hoursItem = NSMenuItem(title: L10n.timerHours, action: nil, keyEquivalent: "")
        hoursItem.submenu = hoursSubmenu
        menu.addItem(hoursItem)

        let customItem = NSMenuItem(title: L10n.timerCustom, action: #selector(menuCustomTimer), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        if soundStore?.hasActiveTimer == true {
            let stopItem = NSMenuItem(title: L10n.timerStop, action: #selector(menuStopTimer), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)
        }
    }

    private func timerLabelFallback(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    @MainActor private func startTimerMenuUpdates() {
        timerMenuUpdate?.invalidate()
        guard soundStore?.hasActiveTimer == true else { return }
        timerMenuUpdate = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(handleTimerMenuTick),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimerMenuUpdates() {
        timerMenuUpdate?.invalidate()
        timerMenuUpdate = nil
    }

    @MainActor private func refreshTimerRemainingMenuItem() {
        guard let item = timerRemainingMenuItem else { return }
        if let title = soundStore?.timerRemainingMenuTitle {
            item.isHidden = false
            item.title = title
        } else {
            item.isHidden = true
        }
    }

    @objc @MainActor private func handleTimerMenuTick() {
        refreshTimerRemainingMenuItem()
    }

    @objc private func menuPlayPause() {
        Task { @MainActor in soundStore?.togglePlay() }
    }

    @objc private func menuNextMix() {
        Task { @MainActor in soundStore?.playNextRandomMix() }
    }

    @objc private func menuStartTimer(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        Task { @MainActor in
            soundStore?.startSleepTimer(durationSeconds: seconds)
        }
    }

    @objc private func menuCustomTimer() {
        Task { @MainActor in
            soundStore?.promptCustomTimer()
        }
    }

    @objc private func menuStopTimer() {
        Task { @MainActor in
            soundStore?.cancelSleepTimer()
        }
    }

    @objc private func menuOpenWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let w = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
            w.makeKeyAndOrderFront(nil)
        } else if let w = mainWindow ?? bestMainWindowCandidate(in: NSApplication.shared.windows) {
            w.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
}
