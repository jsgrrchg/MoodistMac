import SwiftUI
import Combine
import Sparkle

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
    @ObservedObject private var viewModel: CheckForUpdatesViewModel
    private let updater: SPUUpdater

    init(updater: SPUUpdater, viewModel: CheckForUpdatesViewModel) {
        self.updater = updater
        self.viewModel = viewModel
    }

    var body: some View {
        Button(L10n.checkForUpdates) {
            updater.checkForUpdates()
        }
        .disabled(!viewModel.canCheckForUpdates)
    }
}

@MainActor
final class MoodistUpdaterCoordinator {
    let presenter: UpdateWindowPresenter
    let updater: SPUUpdater
    let checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let userDriver: MoodistUpdateUserDriver

    init() {
        let presenter = UpdateWindowPresenter()
        self.presenter = presenter

        let userDriver = MoodistUpdateUserDriver(presenter: presenter)
        self.userDriver = userDriver

        let updater = SPUUpdater(hostBundle: .main, applicationBundle: .main, userDriver: userDriver, delegate: nil)
        self.updater = updater

        do {
            try updater.start()
        } catch {
            NSLog("Sparkle updater failed to start: %@", String(describing: error))
        }

        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
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
