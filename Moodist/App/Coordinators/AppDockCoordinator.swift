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
        // Rebind the state source and restart observers to avoid orphaned subscriptions.
        soundStore = store
        configureDockObservers()
        updateDockTitle()
    }

    func applicationDockMenu() -> NSMenu? {
        // Dynamically build the Dock icon context menu.
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
        // When the store changes, clear previous subscriptions to avoid duplicates.
        dockCancellables.removeAll()
        guard let store = soundStore else { return }

        // Structural mix, sound, and preset changes that affect visible Dock state.
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

        // Playback state refreshes available actions.
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
        // No badge is currently used; force it clean to avoid visual leftovers.
        NSApp.dockTile.badgeLabel = nil
    }
}
