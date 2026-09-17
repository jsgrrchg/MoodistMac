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
    func testEightHourDeadlineWithRepeatedRotations() async {
        await MainActor.run {
            var date = Date(timeIntervalSince1970: 1000)
            let spy = AudioSpy()
            let store = SoundStore(audioService: AudioService(backend: spy), preferences: PreferencesRepository(defaults: UserDefaults(suiteName: UUID().uuidString)!), now: { date }, scheduler: ManualScheduler())
            store.select("river")
            store.startAutoMixTimer(intervalSeconds: 300)
            store.startSleepTimer(durationSeconds: 8 * 3600)
            let maximum = MixesData.categories.flatMap(\.mixes).map { $0.soundIds.count }.max()!
            for _ in 0..<96 {
                date += 300
                store.reconcileTimers()
                XCTAssertLessThanOrEqual(spy.loaded.count, maximum)
            }
            XCTAssertFalse(store.isPlaying)
            XCTAssertFalse(store.hasActiveAutoMixTimer)
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
