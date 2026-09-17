import XCTest
import MoodistKit

@MainActor private final class ManualScheduler: TimerScheduling {
    final class Token: TimerCancellation { func cancel() {} }
    func schedule(at date: Date, action: @escaping @MainActor () -> Void) -> TimerCancellation { Token() }
}
final class TimerTests: XCTestCase {
    func testSleepDominatesRotationAndInterruption() async {
        await MainActor.run {
            var date = Date(timeIntervalSince1970: 1000)
            let store = SoundStore(audioService: AudioService(backend: AudioSpy()), preferences: PreferencesRepository(defaults: UserDefaults(suiteName: UUID().uuidString)!), now: { date }, scheduler: ManualScheduler())
            store.select("river")
            store.startSleepTimer(durationSeconds: 10)
            store.startAutoMixTimer(intervalSeconds: 10)
            store.pauseForInterruption()
            date += 11
            store.recoverFromInterruption(allowed: true)
            XCTAssertFalse(store.isPlaying)
            XCTAssertFalse(store.hasActiveTimer)
            XCTAssertFalse(store.hasActiveAutoMixTimer)
            XCTAssertEqual(store.selectedIds, ["river"])
        }
    }
    func testPausedRotationNeverStartsAudioAndSkipsMissedTicks() async {
        await MainActor.run {
            var date = Date(timeIntervalSince1970: 1000)
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            let store = SoundStore(audioService: AudioService(backend: AudioSpy()), preferences: PreferencesRepository(defaults: defaults), now: { date }, scheduler: ManualScheduler())
            store.select("river"); store.startAutoMixTimer(intervalSeconds: 10); store.stopPlayback()
            date += 100
            store.reconcileTimers()
            XCTAssertFalse(store.isPlaying)
            XCTAssertEqual(store.autoMixNextFireDate, date.addingTimeInterval(10))
            let restored = SoundStore(audioService: AudioService(backend: AudioSpy()), preferences: PreferencesRepository(defaults: defaults), now: { date }, scheduler: ManualScheduler())
            XCTAssertFalse(restored.isPlaying)
            XCTAssertEqual(restored.autoMixIntervalSeconds, 10)
            store.resetAllToDefaults()
            XCTAssertNil(defaults.object(forKey: "Moodist.timerState"))
        }
    }
}
