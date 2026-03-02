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
        // Limpieza completa de recursos temporales del coordinador.
        stopTimerMenuUpdates()
        closeCustomTimerWindow()
        if let observer = timerWindowCloseObserver {
            NotificationCenter.default.removeObserver(observer)
            timerWindowCloseObserver = nil
        }
    }

    func appendTimerSection(to menu: NSMenu, includeHeader: Bool) {
        // Sección reusable para Dock/MenuBar con presets, custom y stop.
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
        // Enlaza el item que muestra el tiempo restante para refresco por tick.
        timerRemainingMenuItem = item
    }

    func startTimerMenuUpdates() {
        // Ticker de 1s sólo cuando hay timer activo.
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
        // Evita updates de UI mientras el menú no está visible.
        timerMenuUpdate?.invalidate()
        timerMenuUpdate = nil
    }

    func showCustomTimerWindow() {
        // Reutiliza ventana existente para evitar crear múltiples instancias.
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
                // Refresca estilo/acento por si cambió desde la última apertura.
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
        // Libera referencias cuando la ventana se cierra desde AppKit.
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
        // Mantiene sincronizado el contador visible en el menú.
        guard let item = timerRemainingMenuItem else { return }
        if let title = soundStore?.timerRemainingMenuTitle {
            item.isHidden = false
            item.title = title
        } else {
            item.isHidden = true
        }
    }

    private func positionTimerWindow(_ window: NSWindow) {
        // Centra la ventana de timer sobre la ventana principal (o pantalla si no existe).
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
        // Formato defensivo si el store no está disponible.
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
        // Replica la preferencia de apariencia para consistencia visual.
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
        // Toma el acento persistido para aplicar tema en la ventana de timer.
        let raw =
            UserDefaults.standard.string(forKey: PersistenceService.accentColorHexKey)
            ?? AccentColorChoice.graphite.rawValue
        let choice = AccentColorChoice(rawValue: raw) ?? .system
        return choice.accentColor
    }
}
