import XCTest
import MoodistKit
@testable import MoodistIOS

final class EngineIntegrationTests: XCTestCase {
    func testEngineStartsPausesAndRebuildsWithSession() async throws {
        try await MainActor.run {
            let session = IOSAudioSessionController(defaults: UserDefaults(suiteName: UUID().uuidString)!)
            let audio = AudioService()
            audio.preparePlayback = { try session.prepare() }
            audio.playbackDidStop = { session.stop() }
            let river = SoundsData.allSoundsById["river"]!
            XCTAssertTrue(audio.load(sound: river))
            audio.play(soundId: river.id)
            XCTAssertTrue(audio.isPlaying)
            audio.pauseAll(ids: [river.id])
            XCTAssertFalse(audio.isPlaying)
            audio.rebuild()
            XCTAssertTrue(audio.load(sound: river))
            audio.play(soundId: river.id)
            XCTAssertTrue(audio.isPlaying)
            audio.unloadAll()
            XCTAssertFalse(audio.isPlaying)
        }
    }
}
