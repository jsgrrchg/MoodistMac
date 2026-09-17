import SwiftUI
import MoodistKit

@main
struct MoodistIOSApp: App {
    @StateObject private var model = IOSAppModel()
    private var store: SoundStore { model.store }
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Button(store.isPlaying ? L10n.pause : L10n.play) { store.togglePlay() }
                    ForEach(SoundsData.categories.flatMap(\.sounds)) { sound in
                        Button(L10n.soundLabel(sound.id)) { store.select(sound.id) }
                    }
                }
                .navigationTitle("Moodist")
            }
        }
    }
}
