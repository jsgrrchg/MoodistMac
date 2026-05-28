import AppKit
import SwiftUI

@MainActor
final class AppTimerCoordinator: NSObject {
    weak var soundStore: SoundStore?
    var anchorWindowProvider: (() -> NSWindow?)?

    private var timerMenuUpdate: Timer?
    private weak var timerRemainingMenuItem: NSMenuItem?
    private var timerWindowController: NSWindowController?
    private var timerWindowCloseObserver: NSObjectProtocol?

    func stop() {
        // Fully clean up the coordinator's temporary resources.
        stopTimerMenuUpdates()
        closeCustomTimerWindow()
        if let observer = timerWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
            timerWindowCloseObserver = nil
        }
    }

    func appendTimerSection(to menu: NSMenu, includeHeader: Bool) {
        // Reusable Dock/MenuBar section with presets, custom timer, and stop.
        if includeHeader {
            let header = NSMenuItem(title: L10n.timer, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)
        }

        let minutesSubmenu = NSMenu()
        for seconds in SoundStore.timerMenuMinutesPresets {
            let title =
                soundStore?.timerLabel(forSeconds: seconds) ?? timerLabelFallback(seconds: seconds)
            let item = NSMenuItem(
                title: title, action: #selector(menuStartTimer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = seconds
            minutesSubmenu.addItem(item)
        }
        let minutesItem = NSMenuItem(title: L10n.timerMinutes, action: nil, keyEquivalent: "")
        minutesItem.submenu = minutesSubmenu
        menu.addItem(minutesItem)

        let hoursSubmenu = NSMenu()
        for seconds in SoundStore.timerMenuHoursPresets {
            let title =
                soundStore?.timerLabel(forSeconds: seconds) ?? timerLabelFallback(seconds: seconds)
            let item = NSMenuItem(
                title: title, action: #selector(menuStartTimer(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = seconds
            hoursSubmenu.addItem(item)
        }
        let hoursItem = NSMenuItem(title: L10n.timerHours, action: nil, keyEquivalent: "")
        hoursItem.submenu = hoursSubmenu
        menu.addItem(hoursItem)

        let customItem = NSMenuItem(
            title: L10n.timerCustom, action: #selector(menuCustomTimer), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        if soundStore?.hasActiveTimer == true {
            let stopItem = NSMenuItem(
                title: L10n.timerStop, action: #selector(menuStopTimer), keyEquivalent: "")
            stopItem.target = self
            menu.addItem(stopItem)
        }
    }

    func bindTimerRemainingMenuItem(_ item: NSMenuItem?) {
        // Bind the item that shows remaining time for tick-based refresh.
        timerRemainingMenuItem = item
    }

    func startTimerMenuUpdates() {
        // One-second ticker only while a timer is active.
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

    func stopTimerMenuUpdates() {
        // Avoid UI updates while the menu is not visible.
        timerMenuUpdate?.invalidate()
        timerMenuUpdate = nil
    }

    func showCustomTimerWindow() {
        // Reuse the existing window to avoid creating multiple instances.
        guard let store = soundStore else { return }

        let rootView = TimerSetupView(store: store) { [weak self] in
            self?.closeCustomTimerWindow()
        }
        .applyAppAccent(currentAccentColor())
        .preferredColorScheme(currentPreferredColorScheme())

        if let controller = timerWindowController,
            let window = controller.window
        {
            if let host = window.contentViewController as? NSHostingController<AnyView> {
                // Refresh style and accent in case they changed since the last opening.
                host.rootView = AnyView(rootView)
            }
            positionTimerWindow(window)
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let host = NSHostingController(rootView: AnyView(rootView))
        let window = NSWindow(contentViewController: host)
        window.title = L10n.timerCustomTitle
        window.styleMask = NSWindow.StyleMask([.titled, .closable])
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 348, height: 352))
        window.minSize = NSSize(width: 348, height: 352)
        window.maxSize = NSSize(width: 348, height: 352)
        positionTimerWindow(window)

        let controller = NSWindowController(window: window)
        timerWindowController = controller
        // Release references when AppKit closes the window.
        timerWindowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.timerWindowController = nil
                if let observer = self?.timerWindowCloseObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self?.timerWindowCloseObserver = nil
                }
            }
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
        controller.showWindow(self)
        window.makeKeyAndOrderFront(self)
    }

    @objc private func menuStartTimer(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? Int else { return }
        Task { @MainActor in
            soundStore?.startSleepTimer(durationSeconds: seconds)
        }
    }

    @objc private func menuCustomTimer() {
        Task { @MainActor in
            showCustomTimerWindow()
        }
    }

    @objc private func menuStopTimer() {
        Task { @MainActor in
            soundStore?.cancelSleepTimer()
        }
    }

    @objc private func handleTimerMenuTick() {
        refreshTimerRemainingMenuItem()
    }

    private func refreshTimerRemainingMenuItem() {
        // Keep the visible menu countdown synchronized.
        guard let item = timerRemainingMenuItem else { return }
        if let title = soundStore?.timerRemainingMenuTitle {
            item.isHidden = false
            item.title = title
        } else {
            item.isHidden = true
        }
    }

    private func positionTimerWindow(_ window: NSWindow) {
        // Center the timer window over the main window, or the screen if unavailable.
        let anchorWindow = anchorWindowProvider?()
        guard let anchorWindow else {
            window.center()
            return
        }

        let parentFrame = anchorWindow.frame
        let windowFrame = window.frame
        let x = parentFrame.midX - (windowFrame.width / 2)
        let y = parentFrame.midY - (windowFrame.height / 2)
        window.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
    }

    private func closeCustomTimerWindow() {
        timerWindowController?.close()
    }

    private func timerLabelFallback(seconds: Int) -> String {
        // Defensive formatting when the store is unavailable.
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute]
        }
        return formatter.string(from: TimeInterval(seconds)) ?? "\(seconds)s"
    }

    private func currentPreferredColorScheme() -> ColorScheme? {
        // Mirror the appearance preference for visual consistency.
        let raw =
            UserDefaults.standard.string(forKey: PersistenceService.appearanceModeKey) ?? "system"
        switch raw {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    private func currentAccentColor() -> Color? {
        // Use the persisted accent to theme the timer window.
        let raw =
            UserDefaults.standard.string(forKey: PersistenceService.accentColorHexKey)
            ?? AccentColorChoice.graphite.rawValue
        let choice = AccentColorChoice(rawValue: raw) ?? .system
        return choice.accentColor
    }
}
