import XCTest
import MoodistKit

final class InteroperabilityTests: XCTestCase {
    func testTransferBetweenIndependentAppDomains() async throws {
        try await MainActor.run {
            let first = SoundStore(audioService: AudioService(backend: AudioSpy()), preferences: PreferencesRepository(defaults: UserDefaults(suiteName: UUID().uuidString)!))
            let secondDefaults = UserDefaults(suiteName: UUID().uuidString)!
            first.select("river"); first.setVolume("river", 0.27); first.saveCurrentAsPreset(name: "Travel")
            first.toggleFavorite("river")
            let json = try PreferencesCodec.encode(first.exportedPreferences())
            let second = SoundStore(audioService: AudioService(backend: AudioSpy()), preferences: PreferencesRepository(defaults: secondDefaults))
            XCTAssertTrue(second.applyImportedPreferences(try PreferencesCodec.decode(json)))
            second.flushPersistence()
            let reloaded = PreferencesRepository(defaults: secondDefaults)
            XCTAssertEqual(reloaded.loadPresets(), first.presets)
            XCTAssertEqual(reloaded.loadFavoriteSoundIds(), ["river"])
            XCTAssertFalse(second.isPlaying)
            XCTAssertThrowsError(try PreferencesCodec.decode(Data("invalid".utf8)))
            XCTAssertEqual(second.presets, first.presets)
        }
    }
}
