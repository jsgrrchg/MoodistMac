import Combine
import Foundation
import MoodistKit

enum IOSPresentation: String, Identifiable {
    case player, settings
    var id: String { rawValue }
}

@MainActor
final class IOSAppModel: ObservableObject {
    @Published var presentedSheet: IOSPresentation?
    let sleepNotifications = SleepNotificationController()
    let defaults: UserDefaults
    let audio: AudioService
    let store: SoundStore
    private var nowPlaying: NowPlayingController?
    private var interruptions: AudioInterruptionObserver?
    let session: IOSAudioSessionController

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let suite = "MoodistIOS.UITests"
            let isolated = UserDefaults(suiteName: suite)!
            isolated.removePersistentDomain(forName: suite)
            defaults = isolated
        } else { defaults = .standard }
        #else
        defaults = .standard
        #endif
        let audio = AudioService()
        let session = IOSAudioSessionController(defaults: defaults)
        self.audio = audio
        self.session = session
        self.store = SoundStore(audioService: audio, preferences: PreferencesRepository(defaults: defaults))
        nowPlaying = NowPlayingController(store: store, session: session)
        interruptions = AudioInterruptionObserver(store: store, session: session)
        store.onTimerScheduled = { [weak self] name, date in self?.sleepNotifications.schedule(name: name, at: date) }
        store.onTimerCancelled = { [weak self] in self?.sleepNotifications.cancel() }
        audio.preparePlayback = { [weak session] in try session?.prepare() }
        audio.playbackDidStop = { [weak session] in session?.stop() }
    }
}
