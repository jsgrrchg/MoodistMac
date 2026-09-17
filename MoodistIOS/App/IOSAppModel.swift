import Combine
import Foundation
import MoodistKit

@MainActor
final class IOSAppModel: ObservableObject {
    let audio: AudioService
    let store: SoundStore
    private var interruptions: AudioInterruptionObserver?
    let session: IOSAudioSessionController

    init() {
        let audio = AudioService()
        let session = IOSAudioSessionController()
        self.audio = audio
        self.session = session
        self.store = SoundStore(audioService: audio)
        interruptions = AudioInterruptionObserver(store: store, session: session)
        audio.preparePlayback = { [weak session] in try session?.prepare() }
        audio.playbackDidStop = { [weak session] in session?.stop() }
    }
}
