import AppKit

@MainActor
final class AppWindowCoordinator {
    private static let mainWindowFrameName = "MoodistMainWindow"
    private static let mainWindowMinSize = CGSize(width: 850, height: 600)
    private static let defaultMainWindowSize = CGSize(width: 900, height: 700)
    private static let maxMainWindowWidth: CGFloat = 1000
    private static let optionsWindowSize = CGSize(width: 510, height: 650)
    private static let frameSaveDebounce: DispatchTimeInterval = .milliseconds(250)

    weak var windowDelegate: NSWindowDelegate?

    private var windowDidBecomeKeyObserver: NSObjectProtocol?
    private weak var mainWindow: NSWindow?
    private var mainWindowHasRestoredFrame = false
    private var mainWindowObservers: [NSObjectProtocol] = []
    private var pendingFrameSave: DispatchWorkItem?
    private var pendingFrameRestore: DispatchWorkItem?

    var anchorWindow: NSWindow? {
        // Reference window for centering auxiliary windows, such as the custom timer.
        mainWindow ?? bestMainWindowCandidate(in: NSApplication.shared.windows)
    }

    func start() {
        // Disable automatic tabbing and attach relevant-window detection.
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
            }
        }
    }

    func stop() {
        // Unregister observers and persist the main window's final frame.
        if let o = windowDidBecomeKeyObserver {
            NotificationCenter.default.removeObserver(o)
            windowDidBecomeKeyObserver = nil
        }
        stopObservingMainWindow()
        persistMainWindowFrameNow()
    }

    func applyAppearanceMode() {
        // Maps the persisted preference to AppKit's global appearance.
        let raw =
            UserDefaults.standard.string(forKey: PersistenceService.appearanceModeKey) ?? "system"
        switch raw {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }

    func refreshMainWindowForTransparencyChange() {
        configureExistingMainWindow()
    }

    @discardableResult
    func handleReopen(hasVisibleWindows flag: Bool) -> Bool {
        // When reopening from the Dock, show or restore the main window even if hidden.
        if !flag {
            showMainWindowIfHidden()
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

    func handleDidBecomeActive() {
        // Staggered retries cover the timing of windows created by SwiftUI.
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

    func openMainWindow() {
        // Open the visible key window or recover the best candidate if none is in front.
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let w = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
            w.makeKeyAndOrderFront(nil)
        } else if let w = anchorWindow {
            w.makeKeyAndOrderFront(nil)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // For the main window, hide instead of closing for utility-app behavior.
        if sender.title == L10n.optionsTitle { return true }
        if !isMainWindowCandidate(sender) { return true }
        persistFrameNow(for: sender)
        sender.orderOut(nil)
        return false
    }

    private func showMainWindowIfHidden() {
        if NSApplication.shared.windows.contains(where: { $0.isVisible && $0.canBecomeKey }) {
            return
        }
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
        if contentSize.width != Self.optionsWindowSize.width
            || contentSize.height != Self.optionsWindowSize.height
        {
            window.setContentSize(Self.optionsWindowSize)
        }
    }

    private func configureMainWindowIfNeeded(_ window: NSWindow) {
        guard isMainWindowCandidate(window) else { return }
        if mainWindow !== window {
            // When the main instance changes, restart the restore/observer cycle.
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
        // Restore on the next run loop to avoid visual jumps while creating the window.
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
        DispatchQueue.main.async(execute: work)
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
        // Shared visual and functional configuration for the main window.
        let transparencyEnabled =
            UserDefaults.standard.object(forKey: PersistenceService.transparencyEnabledKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: PersistenceService.transparencyEnabledKey)

        if transparencyEnabled {
            window.isOpaque = false
            window.backgroundColor = .clear
        } else {
            window.isOpaque = true
            window.backgroundColor = NSColor.windowBackgroundColor
        }
        window.maxSize = NSSize(
            width: Self.maxMainWindowWidth, height: CGFloat.greatestFiniteMagnitude)
        window.minSize = NSSize(
            width: Self.mainWindowMinSize.width, height: Self.mainWindowMinSize.height)

        window.tabbingMode = .disallowed
        window.toolbarStyle = .unified
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = false
        window.delegate = windowDelegate
    }

    /// AppKit UserDefaults key for the frame; see Apple's Saving Window Position docs.
    private static var windowFrameDefaultsKey: String { "NSWindow Frame \(mainWindowFrameName)" }

    private func startObservingMainWindow(_ window: NSWindow) {
        // Observe movement, resizing, and closing for robust frame persistence.
        window.delegate = windowDelegate
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
                    if self?.mainWindow === w {
                        self?.mainWindow = nil
                        self?.mainWindowHasRestoredFrame = false
                        self?.stopObservingMainWindow()
                    }
                }
            },
        ]
    }

    private func stopObservingMainWindow() {
        // Cancel debounce and remove all observers associated with the window.
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
        // Debounce persistence to avoid writing defaults on every resize pixel.
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
    }

    private func canPersistFrame(_ frame: NSRect) -> Bool {
        frame.size.width >= Self.mainWindowMinSize.width
            && frame.size.height >= Self.mainWindowMinSize.height
    }

    private func applyRestoredFrame(to window: NSWindow) {
        // Restore, sanitize, and correct historically persisted invalid frames.
        let restored = window.setFrameUsingName(Self.mainWindowFrameName, force: true)
        let currentFrame = window.frame
        var frame = currentFrame
        let useRestored = restored && canPersistFrame(frame)
        var shouldPersist = false

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
        if frameDistance(frame, currentFrame) > 1 {
            window.setFrame(frame, display: true)
        }
        if shouldPersist {
            persistFrameNow(for: window)
        }
    }

    private func frameDistance(_ lhs: NSRect, _ rhs: NSRect) -> CGFloat {
        let dx = abs(lhs.origin.x - rhs.origin.x)
        let dy = abs(lhs.origin.y - rhs.origin.y)
        let dw = abs(lhs.size.width - rhs.size.width)
        let dh = abs(lhs.size.height - rhs.size.height)
        return max(dx, max(dy, max(dw, dh)))
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
        // Clamp size and position to the current screen's visible bounds.
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
        // Find the screen by center point, falling back to the largest intersection.
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
}
