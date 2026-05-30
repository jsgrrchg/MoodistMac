import Sparkle
import SwiftUI

struct MoodistCommands: Commands {
    @ObservedObject private var soundStore: SoundStore
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater
    private let showCustomTimerWindow: () -> Void
    private let showAboutPanel: () -> Void
    private let openBuyMeACoffee: () -> Void

    init(
        soundStore: SoundStore,
        updater: SPUUpdater,
        checkForUpdatesViewModel: CheckForUpdatesViewModel,
        showCustomTimerWindow: @escaping () -> Void,
        showAboutPanel: @escaping () -> Void,
        openBuyMeACoffee: @escaping () -> Void
    ) {
        self._soundStore = ObservedObject(wrappedValue: soundStore)
        self.updater = updater
        self._checkForUpdatesViewModel = ObservedObject(wrappedValue: checkForUpdatesViewModel)
        self.showCustomTimerWindow = showCustomTimerWindow
        self.showAboutPanel = showAboutPanel
        self.openBuyMeACoffee = openBuyMeACoffee
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .appInfo) {
            Button(L10n.aboutApp(L10n.appName)) {
                showAboutPanel()
            }
        }
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
        CommandMenu(L10n.playbackMenu) {
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
                showCustomTimerWindow()
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
                        Toggle(
                            isOn: Binding(
                                get: { soundStore.sounds[soundId]?.isSelected ?? false },
                                set: { isOn in
                                    if isOn {
                                        soundStore.select(soundId)
                                    } else {
                                        soundStore.unselect(soundId)
                                    }
                                }
                            )
                        ) {
                            Text(L10n.soundLabel(soundId))
                        }
                    }
                }
                Divider()
            }
            ForEach(SoundsData.categories, id: \.id) { category in
                Menu(L10n.categoryTitle(category.id)) {
                    ForEach(category.sounds) { sound in
                        Toggle(
                            isOn: Binding(
                                get: { soundStore.sounds[sound.id]?.isSelected ?? false },
                                set: { isOn in
                                    if isOn {
                                        soundStore.select(sound.id)
                                    } else {
                                        soundStore.unselect(sound.id)
                                    }
                                }
                            )
                        ) {
                            Text(L10n.soundLabel(sound.id))
                        }
                    }
                }
            }
        }
        CommandMenu(L10n.mixes) {
            let customMixes = soundStore.presets.map { $0.toMix() }
            let mixesById = Dictionary(
                uniqueKeysWithValues: (MixesData.categories.flatMap(\.mixes) + customMixes).map {
                    ($0.id, $0)
                })
            let displayName: (Mix) -> String = { mix in
                let localized = L10n.mixName(mix.id)
                return localized == mix.id ? mix.name : localized
            }
            if !soundStore.favoriteMixIds.isEmpty {
                Menu(L10n.favorites) {
                    ForEach(soundStore.favoriteMixIds, id: \.self) { mixId in
                        if let mix = mixesById[mixId] {
                            Button(displayName(mix)) {
                                soundStore.applyMix(mix)
                            }
                        }
                    }
                }
                Divider()
            }
            ForEach(MixesData.categories, id: \.id) { category in
                let mixes = category.id == MixesData.custom.id ? customMixes : category.mixes
                Menu(L10n.mixCategoryTitle(category.id)) {
                    if mixes.isEmpty, category.id == MixesData.custom.id {
                        Text(L10n.customMixesEmpty).disabled(true)
                    } else {
                        ForEach(mixes) { mix in
                            Button(displayName(mix)) {
                                soundStore.applyMix(mix)
                            }
                        }
                    }
                }
            }
        }
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: updater, viewModel: checkForUpdatesViewModel)
            Button(L10n.buyMeACoffee) {
                openBuyMeACoffee()
            }
        }
    }
}
