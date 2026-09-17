import AVFoundation
import Combine
import Foundation

@MainActor
protocol AudioSessionDriving {
    func configure(mixing: Bool) throws
    func activate() throws
    func deactivate() throws
}

@MainActor
final class SystemAudioSession: AudioSessionDriving {
    private let session = AVAudioSession.sharedInstance()
    func configure(mixing: Bool) throws {
        try session.setCategory(.playback, mode: .default, options: mixing ? [.mixWithOthers] : [])
    }
    func activate() throws { try session.setActive(true) }
    func deactivate() throws { try session.setActive(false, options: .notifyOthersOnDeactivation) }
}

@MainActor
final class IOSAudioSessionController: ObservableObject {
    static let mixingKey = "MoodistIOS.mixWithOthers"
    @Published private(set) var mixesWithOthers: Bool
    private let driver: AudioSessionDriving
    private let defaults: UserDefaults
    private(set) var active = false

    init(driver: AudioSessionDriving? = nil, defaults: UserDefaults = .standard) {
        self.driver = driver ?? SystemAudioSession()
        self.defaults = defaults
        mixesWithOthers = defaults.bool(forKey: Self.mixingKey)
    }
    func prepare() throws {
        guard !active else { return }
        try driver.configure(mixing: mixesWithOthers)
        try driver.activate()
        active = true
    }
    func stop() {
        guard active else { return }
        do { try driver.deactivate(); active = false }
        catch { /* An interruption may already have deactivated the system session. */ }
    }
    func setMixing(_ value: Bool) throws {
        guard value != mixesWithOthers else { return }
        try driver.configure(mixing: value)
        mixesWithOthers = value
        defaults.set(value, forKey: Self.mixingKey)
    }
    func invalidate() { active = false }
}
