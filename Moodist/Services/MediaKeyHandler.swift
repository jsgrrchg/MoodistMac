//
//  MediaKeyHandler.swift
//  MoodistMac
//

import Foundation

#if canImport(MediaPlayer)
import MediaPlayer
#endif

@MainActor
final class MediaKeyHandler: ObservableObject {
    static let shared = MediaKeyHandler()

    var onTogglePlayPause: (() -> Void)?
    var onNextTrack: (() -> Void)?

    private var didSetup = false

    private init() {}

    func setup() {
        guard !didSetup else { return }
        didSetup = true
        #if canImport(MediaPlayer)
        let center = MPRemoteCommandCenter.shared()

        center.togglePlayPauseCommand.isEnabled = true
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.onTogglePlayPause?()
            }
            return .success
        }

        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.onTogglePlayPause?()
            }
            return .success
        }

        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                self?.onTogglePlayPause?()
            }
            return .success
        }

        center.nextTrackCommand.isEnabled = true
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard PersistenceService.loadMediaKeyNextMix(), let self else { return .commandFailed }
            Task { @MainActor in
                self.onNextTrack?()
            }
            return .success
        }
        #endif
    }

    func setToggleHandler(_ handler: @escaping () -> Void) {
        onTogglePlayPause = handler
    }

    func setNextTrackHandler(_ handler: @escaping () -> Void) {
        onNextTrack = handler
    }

    func updateNowPlaying(isPlaying: Bool) {
        #if canImport(MediaPlayer)
        let infoCenter = MPNowPlayingInfoCenter.default()
        infoCenter.playbackState = isPlaying ? .playing : .paused
        var info = infoCenter.nowPlayingInfo ?? [String: Any]()
        info[MPMediaItemPropertyTitle] = "MoodistMac"
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        infoCenter.nowPlayingInfo = info
        #endif
    }
}
