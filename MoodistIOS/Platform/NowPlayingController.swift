import Combine
import MediaPlayer
import MoodistKit
import UIKit

@MainActor
final class NowPlayingController {
    private let store: SoundStore
    private let session: IOSAudioSessionController
    private var subscriptions = Set<AnyCancellable>()
    private var handlers: [(MPRemoteCommand, Any)] = []

    init(store: SoundStore, session: IOSAudioSessionController) {
        self.store = store
        self.session = session
        let center = MPRemoteCommandCenter.shared()
        register(center.playCommand) { if !$0.isPlaying { $0.togglePlay() } }
        register(center.pauseCommand) { $0.stopPlayback() }
        register(center.togglePlayPauseCommand) { $0.togglePlay() }
        register(center.nextTrackCommand) {
            guard PersistenceService.loadMediaKeyNextMix() else { return }
            $0.playNextRandomMix()
        }
        store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }.store(in: &subscriptions)
        session.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification).sink { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }.store(in: &subscriptions)
        refresh()
    }

    private func register(_ command: MPRemoteCommand, action: @escaping @MainActor (SoundStore) -> Void) {
        let token = command.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.store.hasSelection, !self.session.mixesWithOthers else { return }
                action(self.store)
            }
            return .success
        }
        handlers.append((command, token))
    }

    func refresh() {
        let center = MPRemoteCommandCenter.shared()
        let eligible = store.hasSelection && !session.mixesWithOthers
        center.playCommand.isEnabled = eligible && !store.isPlaying
        center.pauseCommand.isEnabled = eligible && store.isPlaying
        center.togglePlayPauseCommand.isEnabled = eligible
        center.nextTrackCommand.isEnabled = eligible && PersistenceService.loadMediaKeyNextMix()
            && (!store.autoMixCustomOnly || !store.presets.isEmpty)
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackPositionCommand.isEnabled = false
        guard eligible else { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: store.displayedMixName ?? L10n.currentlyPlaying,
            MPMediaItemPropertyArtist: "Moodist",
            MPNowPlayingInfoPropertyPlaybackRate: store.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
        let image = UIImage(systemName: store.displayedMixIconName ?? "waveform") ?? UIImage(systemName: "waveform")!
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    deinit {
        for (command, token) in handlers { command.removeTarget(token) }
    }
}
