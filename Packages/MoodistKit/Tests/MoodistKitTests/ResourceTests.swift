import XCTest
import AVFoundation
import MoodistKit

final class ResourceTests: XCTestCase {
    func testEveryBundledSoundDecodes() throws {
        for sound in SoundsData.categories.flatMap(\.sounds) {
            let url = try XCTUnwrap(MoodistResources.soundURL(sound), sound.id)
            let file = try AVAudioFile(forReading: url)
            XCTAssertGreaterThan(file.length, 0, sound.id)
            XCTAssertGreaterThan(file.processingFormat.sampleRate, 0, sound.id)
        }
    }
    func testLanguagesResolveFromPackage() {
        XCTAssertEqual(MoodistResources.localizedString("play", fallback: "missing", language: "en"), "Play")
        XCTAssertNotEqual(MoodistResources.localizedString("play", fallback: "missing", language: "es"), "missing")
        XCTAssertNotEqual(MoodistResources.localizedString("play", fallback: "missing", language: "pt-BR"), "missing")
    }
}
