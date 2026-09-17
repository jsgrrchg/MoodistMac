import Combine
import Foundation
import MoodistKit

@MainActor
final class IOSAppModel: ObservableObject {
    let sleepNotifications = SleepNotificationController()
    let audio: AudioService
    let store: SoundStore
    private var nowPlaying: NowPlayingController?
    private var interruptions: AudioInterruptionObserver?
    let session: IOSAudioSessionController

    init() {
        let audio = AudioService()
        let session = IOSAudioSessionController()
        self.audio = audio
        self.session = session
        self.store = SoundStore(audioService: audio)
        nowPlaying = NowPlayingController(store: store, session: session)
        interruptions = AudioInterruptionObserver(store: store, session: session)
        store.onTimerScheduled = { [weak self] name, date in self?.sleepNotifications.schedule(name: name, at: date) }
        store.onTimerCancelled = { [weak self] in self?.sleepNotifications.cancel() }
        audio.preparePlayback = { [weak session] in try session?.prepare() }
        audio.playbackDidStop = { [weak session] in session?.stop() }
    }
}
