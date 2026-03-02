import AppKit
import Combine

@MainActor
final class AppDockCoordinator: NSObject {
    private weak var soundStore: SoundStore?
    private let timerCoordinator: AppTimerCoordinator
    private var dockCancellables = Set<AnyCancellable>()

    init(timerCoordinator: AppTimerCoordinator) {
        self.timerCoordinator = timerCoordinator
        super.init()
    }

    func updateSoundStore(_ store: SoundStore?) {
        // Reenlaza la fuente de estado y reinicia observadores para evitar suscripciones huérfanas.
        soundStore = store
        configureDockObservers()
        updateDockTitle()
    }

    func applicationDockMenu() -> NSMenu? {
        // Construye dinámicamente el menú contextual del icono en el Dock.
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
        timerCoordinator.appendTimerSection(to: menu, includeHeader: true)

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
        // Al cambiar de store, se limpian subscriptions previas para evitar duplicados.
        dockCancellables.removeAll()
        guard let store = soundStore else { return }

        // Cambios estructurales de mezcla/sonidos/presets que afectan el estado visible del Dock.
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

        // Estado de reproducción para refrescar acciones disponibles.
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
        // Actualmente no se usa badge; se fuerza limpio para evitar residuos visuales.
        NSApp.dockTile.badgeLabel = nil
    }
}
