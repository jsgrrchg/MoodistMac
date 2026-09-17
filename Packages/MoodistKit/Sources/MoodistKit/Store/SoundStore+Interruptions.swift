import Foundation

public extension SoundStore {
    func pauseForInterruption() {
        let resume = isPlaying
        stopPlayback()
        resumeAfterInterruption = resume
    }

    func recoverFromInterruption(allowed: Bool) {
        let resume = resumeAfterInterruption && allowed
        resumeAfterInterruption = false
        guard resume, hasSelection else { return }
        togglePlay()
    }

    func rebuildAudioAfterMediaReset() {
        let resume = isPlaying || resumeAfterInterruption
        stopPlayback()
        audioService.rebuild()
        resumeAfterInterruption = resume
        recoverFromInterruption(allowed: true)
    }
}
