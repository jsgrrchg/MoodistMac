import SwiftUI
import MoodistKit

@main
struct MoodistIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = IOSAppModel()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .environmentObject(model.store)
                .environmentObject(model.session)
                .onChange(of: scenePhase) { _, phase in
                    model.store.persistTimers()
                    if phase == .active { model.store.reconcileTimers() }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    model.store.reconcileTimers()
                }
        }
    }
}
