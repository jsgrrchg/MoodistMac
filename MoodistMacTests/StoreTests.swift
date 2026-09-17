import MoodistKit
import XCTest

@MainActor
final class AudioSpy: AudioPlaybackBackend {
    var loaded = Set<String>()
    var playing = Set<String>()
    var volumes: [String: Double] = [:]
    var failLoading = false
    func load(sound: Sound) -> Bool { if failLoading { return false }; loaded.insert(sound.id); return true }
    func setVolume(soundId: String, volume: Double, globalVolume: Double) { volumes[soundId] = volume * globalVolume }
    func setVolume(soundId: String, volume: Double, globalVolume: Double, fadeDuration: TimeInterval) { setVolume(soundId: soundId, volume: volume, globalVolume: globalVolume) }
    func play(soundId: String) { playing.insert(soundId) }
    func pause(soundId: String) { playing.remove(soundId) }
    func unload(soundId: String) { loaded.remove(soundId); playing.remove(soundId) }
    func unloadAll() { loaded.removeAll(); playing.removeAll() }
    func playAll(ids: [String]) { playing.formUnion(ids) }
    func pauseAll(ids: [String]) { playing.subtract(ids) }
    func updateVolumes(state: [String: SoundStateItem], globalVolume: Double) {
        for (id, item) in state { volumes[id] = item.volume * globalVolume }
    }
    func fadeOutAndUnload(soundId: String, duration: TimeInterval) { unload(soundId: soundId) }
    func scheduleOutgoingCleanup(after duration: TimeInterval) {}
    func cancelCrossfadeAndCleanup() {}
}

final class StoreTests: XCTestCase {
    @MainActor func makeStore() -> (SoundStore, AudioSpy, UserDefaults) {
        let defaults = UserDefaults(suiteName: "MoodistTests.\(UUID().uuidString)")!
        let spy = AudioSpy()
        return (SoundStore(audioService: AudioService(backend: spy), preferences: PreferencesRepository(defaults: defaults)), spy, defaults)
    }

    func testPlaybackSelectionAndShuffle() async {
        await MainActor.run {
            let (store, spy, _) = makeStore()
            store.select("river")
            store.setVolume("river", 0.4)
            store.setGlobalVolume(0.5)
            XCTAssertEqual(spy.volumes["river"], 0.2)
            store.stopPlayback()
            XCTAssertEqual(store.selectedIds, ["river"])
            XCTAssertFalse(store.isPlaying)
            store.shuffle()
            XCTAssertEqual(store.selectedIds.count, 4)
            store.unselectAll()
            XCTAssertTrue(spy.loaded.isEmpty)
            XCTAssertFalse(store.isPlaying)
        }
    }

    func testImportSanitizesAndRejectsFutureVersionAtomically() async throws {
        try await MainActor.run {
            let (store, _, _) = makeStore()
            let preset = Preset(id: "saved", name: " Test ", iconName: "", soundIds: ["river", "river", "missing"], volumes: ["river": 9])
            let payload = ExportedPreferences(exportDate: "test", presets: [preset, preset], favoriteMixIds: ["saved","missing","saved"], favoriteSoundIds: ["river","river","missing"])
            XCTAssertTrue(store.applyImportedPreferences(payload))
            XCTAssertEqual(store.presets.count, 1)
            XCTAssertEqual(store.presets.first?.soundIds, ["river"])
            XCTAssertEqual(store.presets.first?.volume(for: "river"), 1)
            XCTAssertEqual(store.favoriteMixIds, ["saved"])
            let future = ExportedPreferences(version: 2, exportDate: "test", presets: [], favoriteMixIds: [], favoriteSoundIds: [])
            XCTAssertThrowsError(try PreferencesCodec.decode(JSONEncoder().encode(future)))
            XCTAssertFalse(store.applyImportedPreferences(future))
            XCTAssertEqual(store.presets.count, 1)
        }
    }

    func testPresetDeletionAndRecents() async {
        await MainActor.run {
            let (store, _, defaults) = makeStore()
            defaults.set(5, forKey: PersistenceService.maxRecentSoundsCountKey)
            for sound in SoundsData.categories.flatMap(\.sounds).prefix(8) { store.addToRecentSounds(soundId: sound.id) }
            XCTAssertEqual(store.recentSoundIds.count, 5)
            store.select("river")
            store.saveCurrentAsPreset(name: "Focus")
            let id = store.presets[0].id
            store.toggleFavoriteMix(id: id)
            store.applyMix(store.presets[0].toMix())
            store.deletePreset(id: id)
            XCTAssertFalse(store.favoriteMixIds.contains(id))
            XCTAssertFalse(store.recentMixIds.contains(id))
            XCTAssertNil(store.currentMixId)
        }
    }
}
