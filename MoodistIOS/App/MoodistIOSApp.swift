import SwiftUI
import MoodistKit

@main
struct MoodistIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PersistenceService.appearanceModeKey) private var appearance = "system"
    @AppStorage(PersistenceService.accentColorHexKey) private var accent = "graphite"
    @StateObject private var model = IOSAppModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
                .tint(IOSAccent.color(accent))
                .environmentObject(model)
                .environmentObject(model.store)
                .environmentObject(model.session)
                .onChange(of: scenePhase) { _, phase in
                    model.store.flushPersistence()
                    model.store.persistTimers()
                    if phase == .active { model.store.reconcileTimers() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    model.store.reconcileTimers()
                }
        }
    }
}
