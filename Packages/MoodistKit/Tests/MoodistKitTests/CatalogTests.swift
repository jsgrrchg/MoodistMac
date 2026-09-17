import MoodistKit
import XCTest

final class CatalogTests: XCTestCase {
    func testCatalogReferencesAndCounts() throws {
        let sounds = SoundsData.categories.flatMap(\.sounds)
        let mixes = MixesData.categories.flatMap(\.mixes)
        XCTAssertEqual(sounds.count, 131)
        XCTAssertEqual(mixes.count, 123)
        XCTAssertEqual(Set(sounds.map(\.id)).count, sounds.count)
        XCTAssertEqual(Set(mixes.map(\.id)).count, mixes.count)
        for mix in mixes {
            XCTAssertTrue(Set(mix.soundIds).isSubset(of: Set(sounds.map(\.id))), mix.id)
            XCTAssertEqual(Set(mix.soundIds).count, mix.soundIds.count, mix.id)
            XCTAssertTrue(mix.volumes.values.allSatisfy { (0...1).contains($0) }, mix.id)
        }
    }

    func testLegacyPresetAndExportRoundTrip() throws {
        let legacy = Data(#"{"id":"test","name":"Rain","soundIds":["river"]}"#.utf8)
        let preset = try JSONDecoder().decode(Preset.self, from: legacy)
        XCTAssertEqual(preset.iconName, "sparkles")
        XCTAssertEqual(preset.volume(for: "river"), 0.5)
        let payload = ExportedPreferences(exportDate: "2026-09-16", presets: [preset], favoriteMixIds: ["test"], favoriteSoundIds: ["river"])
        let restored = try JSONDecoder().decode(ExportedPreferences.self, from: JSONEncoder().encode(payload))
        XCTAssertEqual(restored.version, 1)
        XCTAssertEqual(restored.presets, [preset])
        XCTAssertEqual(restored.favoriteSoundIds, ["river"])
    }

    func testTimerMinimumAndNonpersistedRuntime() throws {
        let timer = TimerItem(name: "Sleep", durationSeconds: 0, state: .running(endDate: Date()))
        XCTAssertEqual(timer.durationSeconds, 1)
        let restored = try JSONDecoder().decode(TimerItem.self, from: JSONEncoder().encode(timer))
        XCTAssertFalse(restored.isRunning)
    }
}
