//
//  MoodistApp.swift
//  MoodistMac
//
//  Punto de entrada macOS (Sequoia 15.0+).
//

import SwiftUI
import Sparkle

@main
struct MoodistApp: App {
    @StateObject private var soundStore: SoundStore
    @StateObject private var updatePresenter: UpdateWindowPresenter
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    @NSApplicationDelegateAdaptor(MacOSAppDelegate.self) var appDelegate
    @AppStorage(PersistenceService.appearanceModeKey) private var appearanceModeRaw = "system"
    @AppStorage(PersistenceService.accentColorHexKey) private var accentColorRaw = AccentColorChoice.graphite.rawValue
    @State private var accentRefreshID = UUID()
    private let updaterCoordinator: MoodistUpdaterCoordinator

    init() {
        let audio = AudioService()
        _soundStore = StateObject(wrappedValue: SoundStore(audioService: audio))

        let updaterCoordinator = MoodistUpdaterCoordinator()
        self.updaterCoordinator = updaterCoordinator
        _updatePresenter = StateObject(wrappedValue: updaterCoordinator.presenter)
        _checkForUpdatesViewModel = StateObject(wrappedValue: updaterCoordinator.checkForUpdatesViewModel)
    }

    private var updater: SPUUpdater {
        updaterCoordinator.updater
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
                .id(accentRefreshID)
                .environmentObject(soundStore)
                .applyAppAccent(accentChoice.accentColor)
                .preferredColorScheme(preferredColorScheme)
                .onAppear {
                    appDelegate.soundStore = soundStore
                }
                .onReceive(NotificationCenter.default.publisher(for: .accentPreferenceDidChange)) { _ in
                    accentRefreshID = UUID()
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            MoodistCommands(
                soundStore: soundStore,
                updater: updater,
                checkForUpdatesViewModel: checkForUpdatesViewModel,
                showCustomTimerWindow: { appDelegate.showCustomTimerWindow() },
                showAboutPanel: MoodistAppActions.showCustomizedAboutPanel,
                openBuyMeACoffee: MoodistAppActions.openBuyMeACoffee
            )
        }

        Window(L10n.optionsTitle, id: "options") {
            OptionsView()
                .environmentObject(soundStore)
                .environmentObject(updatePresenter)
                .environment(\.sparkleUpdater, updater)
                .applyAppAccent(accentChoice.accentColor)
                .preferredColorScheme(preferredColorScheme)
                .frame(width: 510, height: 650)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 510, height: 650)
        .windowResizability(.contentSize)
    }
}
