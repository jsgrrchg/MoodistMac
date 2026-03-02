import AppKit

@MainActor
final class MacOSAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private static let menuBarKey = PersistenceService.menuBarEnabledKey

    weak var soundStore: SoundStore? {
        didSet {
            timerCoordinator.soundStore = soundStore
            menuBarCoordinator.soundStore = soundStore
            dockCoordinator.updateSoundStore(soundStore)
        }
    }

    private let windowCoordinator = AppWindowCoordinator()
    private let timerCoordinator = AppTimerCoordinator()
    private lazy var menuBarCoordinator = AppMenuBarCoordinator(windowCoordinator: windowCoordinator, timerCoordinator: timerCoordinator)
    private lazy var dockCoordinator = AppDockCoordinator(timerCoordinator: timerCoordinator)

    private var menuBarObserver: NSObjectProtocol?
    private var appearanceObserver: NSObjectProtocol?
    private var transparencyObserver: NSObjectProtocol?
    private var timerStateObserver: NSObjectProtocol?
    private var timerWindowRequestObserver: NSObjectProtocol?

    private var spaceKeyMonitor: Any?
    private var searchFocusResetMonitor: Any?

    override init() {
        super.init()
        windowCoordinator.windowDelegate = self
        timerCoordinator.anchorWindowProvider = { [weak self] in
            self?.windowCoordinator.anchorWindow
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowCoordinator.applyAppearanceMode()
        windowCoordinator.start()
        updateMenuBarVisibility()

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
                self?.windowCoordinator.applyAppearanceMode()
            }
        }

        transparencyObserver = NotificationCenter.default.addObserver(
            forName: .transparencyPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.windowCoordinator.refreshMainWindowForTransparencyChange()
            }
        }

        timerStateObserver = NotificationCenter.default.addObserver(
            forName: .timerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.menuBarCoordinator.handleTimerStateDidChange()
            }
        }

        timerWindowRequestObserver = NotificationCenter.default.addObserver(
            forName: .requestShowCustomTimerWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.showCustomTimerWindow()
            }
        }

        installSpaceKeyMonitor()
        installSearchFocusResetMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = spaceKeyMonitor { NSEvent.removeMonitor(monitor) }
        spaceKeyMonitor = nil
        if let monitor = searchFocusResetMonitor { NSEvent.removeMonitor(monitor) }
        searchFocusResetMonitor = nil

        menuBarCoordinator.stop()
        timerCoordinator.stop()
        windowCoordinator.stop()
    }

    @MainActor deinit {
        if let monitor = spaceKeyMonitor { NSEvent.removeMonitor(monitor) }
        if let monitor = searchFocusResetMonitor { NSEvent.removeMonitor(monitor) }
        if let o = menuBarObserver { NotificationCenter.default.removeObserver(o) }
        if let o = appearanceObserver { NotificationCenter.default.removeObserver(o) }
        if let o = transparencyObserver { NotificationCenter.default.removeObserver(o) }
        if let o = timerStateObserver { NotificationCenter.default.removeObserver(o) }
        if let o = timerWindowRequestObserver { NotificationCenter.default.removeObserver(o) }

        menuBarCoordinator.stop()
        timerCoordinator.stop()
        windowCoordinator.stop()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windowCoordinator.handleReopen(hasVisibleWindows: flag)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        windowCoordinator.handleDidBecomeActive()
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockCoordinator.applicationDockMenu()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        windowCoordinator.windowShouldClose(sender)
    }

    func showCustomTimerWindow() {
        timerCoordinator.showCustomTimerWindow()
    }

    private func updateMenuBarVisibility() {
        let show = UserDefaults.standard.bool(forKey: Self.menuBarKey)
        menuBarCoordinator.updateVisibility(show: show)
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

    private func installSearchFocusResetMonitor() {
        searchFocusResetMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self else { return event }
            guard let window = event.window ?? NSApp.keyWindow else { return event }
            guard let firstResponder = window.firstResponder else { return event }
            guard self.isSearchResponder(firstResponder) else { return event }
            guard let contentView = window.contentView else {
                window.makeFirstResponder(nil)
                return event
            }

            let hitPoint = contentView.convert(event.locationInWindow, from: nil)
            guard let hitView = contentView.hitTest(hitPoint) else {
                window.makeFirstResponder(nil)
                return event
            }

            if self.isViewInsideSearchField(hitView) { return event }
            if hitView is NSTextField || hitView is NSTextView { return event }

            window.makeFirstResponder(nil)
            return event
        }
    }

    private func isSearchResponder(_ responder: NSResponder) -> Bool {
        if let searchField = responder as? NSSearchField {
            return isViewInsideSearchField(searchField)
        }
        if let textView = responder as? NSTextView, let delegateView = textView.delegate as? NSView {
            return isViewInsideSearchField(delegateView)
        }
        if let view = responder as? NSView {
            return isViewInsideSearchField(view)
        }
        return false
    }

    private func isViewInsideSearchField(_ view: NSView) -> Bool {
        var current: NSView? = view
        while let node = current {
            if node is NSSearchField { return true }
            current = node.superview
        }
        return false
    }
}
