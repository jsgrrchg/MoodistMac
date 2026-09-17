import AVFoundation
import Foundation
import MoodistKit

@MainActor
final class AudioInterruptionObserver {
    private var tokens: [NSObjectProtocol] = []
    init(store: SoundStore, session: IOSAudioSessionController) {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak store, weak session] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor in
                guard let raw, let kind = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                if kind == .began {
                    store?.pauseForInterruption()
                    session?.invalidate()
                } else {
                    store?.recoverFromInterruption(allowed: AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume))
                }
            }
        })
        tokens.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak store] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                Task { @MainActor in store?.stopPlayback() }
            }
        })
        tokens.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak store, weak session] _ in
            Task { @MainActor in
                session?.invalidate()
                store?.rebuildAudioAfterMediaReset()
            }
        })
    }
    deinit { tokens.forEach(NotificationCenter.default.removeObserver) }
}
