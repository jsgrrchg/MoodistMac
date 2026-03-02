import AppKit

@MainActor
final class AppMenuBarCoordinator: NSObject, NSMenuDelegate {
    weak var soundStore: SoundStore?

    private let windowCoordinator: AppWindowCoordinator
    private let timerCoordinator: AppTimerCoordinator
    private var statusItem: NSStatusItem?

    init(windowCoordinator: AppWindowCoordinator, timerCoordinator: AppTimerCoordinator) {
        self.windowCoordinator = windowCoordinator
        self.timerCoordinator = timerCoordinator
        super.init()
    }

    func updateVisibility(show: Bool) {
        // Crea o elimina el NSStatusItem según preferencia del usuario.
        if show {
            if statusItem == nil { createStatusItem() }
        } else {
            timerCoordinator.stopTimerMenuUpdates()
            timerCoordinator.bindTimerRemainingMenuItem(nil)
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    func handleTimerStateDidChange() {
        // Si el menú existe, se reconstruye para reflejar timer/acciones en caliente.
        guard statusItem?.menu != nil else { return }
        statusItem?.menu = buildStatusMenu()
    }

    func stop() {
        // Limpieza explícita al terminar la app o al desactivar menubar.
        timerCoordinator.stopTimerMenuUpdates()
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func createStatusItem() {
        // Instala un ícono SF Symbol translúcido para mantener estética sutil en la barra.
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .ultraLight)
        guard
            let baseImage = NSImage(
                systemSymbolName: "waveform", accessibilityDescription: L10n.appName)?
                .withSymbolConfiguration(config)
        else { return }

        let translucentImage = createTranslucentImage(from: baseImage, opacity: 0.5)
        translucentImage.isTemplate = true

        guard let button = statusItem?.button else { return }
        button.image = translucentImage
        button.title = ""
        button.appearsDisabled = false
        button.imagePosition = .imageLeading
        button.bezelStyle = .texturedRounded

        statusItem?.menu = buildStatusMenu()
    }

    private func createTranslucentImage(from image: NSImage, opacity: CGFloat) -> NSImage {
        // Fallback seguro si no se puede rasterizar la imagen original.
        func fallbackTemplateImage() -> NSImage {
            let fallbackImage = (image.copy() as? NSImage) ?? image
            fallbackImage.isTemplate = true
            return fallbackImage
        }

        let size = image.size

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return fallbackTemplateImage()
        }

        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            )
        else {
            return fallbackTemplateImage()
        }

        context.setAlpha(opacity)
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let renderedCGImage = context.makeImage() else {
            return fallbackTemplateImage()
        }

        let translucentImage = NSImage(cgImage: renderedCGImage, size: size)
        translucentImage.isTemplate = true
        return translucentImage
    }

    private func buildStatusMenu() -> NSMenu {
        // Menú reconstruido por apertura para evitar estado stale en títulos/acciones.
        let menu = NSMenu()
        menu.delegate = self

        let playTitle = (soundStore?.isPlaying == true) ? L10n.pause : L10n.play
        let playItem = NSMenuItem(
            title: playTitle, action: #selector(menuPlayPause), keyEquivalent: "r")
        playItem.keyEquivalentModifierMask = .command
        playItem.target = self
        menu.addItem(playItem)

        let mixName = soundStore?.displayedMixName ?? L10n.customMix
        let nowPlayingItem = NSMenuItem(title: mixName, action: nil, keyEquivalent: "")
        nowPlayingItem.isEnabled = false
        menu.addItem(nowPlayingItem)

        let nextMixItem = NSMenuItem(
            title: L10n.nextMix, action: #selector(menuNextMix), keyEquivalent: "")
        nextMixItem.target = self
        menu.addItem(nextMixItem)

        if let remaining = soundStore?.timerRemainingMenuTitle {
            let remainingItem = NSMenuItem(title: remaining, action: nil, keyEquivalent: "")
            remainingItem.isEnabled = false
            menu.addItem(remainingItem)
            timerCoordinator.bindTimerRemainingMenuItem(remainingItem)
        } else {
            timerCoordinator.bindTimerRemainingMenuItem(nil)
        }

        menu.addItem(NSMenuItem.separator())
        timerCoordinator.appendTimerSection(to: menu, includeHeader: true)
        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(
            title: L10n.openWindow, action: #selector(menuOpenWindow), keyEquivalent: "o")
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

    func menuWillOpen(_ menu: NSMenu) {
        // Refresh completo al abrir y arranque de ticker para contador regresivo.
        guard menu.delegate === self else { return }
        statusItem?.menu = buildStatusMenu()
        timerCoordinator.startTimerMenuUpdates()
    }

    func menuDidClose(_ menu: NSMenu) {
        // Detiene el ticker al cerrar para no consumir ciclos innecesarios.
        guard menu.delegate === self else { return }
        timerCoordinator.stopTimerMenuUpdates()
        timerCoordinator.bindTimerRemainingMenuItem(nil)
    }

    @objc private func menuPlayPause() {
        Task { @MainActor in soundStore?.togglePlay() }
    }

    @objc private func menuNextMix() {
        Task { @MainActor in soundStore?.playNextRandomMix() }
    }

    @objc private func menuOpenWindow() {
        windowCoordinator.openMainWindow()
    }

    @objc private func menuQuit() {
        NSApplication.shared.terminate(nil)
    }
}
