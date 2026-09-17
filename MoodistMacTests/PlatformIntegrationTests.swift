import XCTest
import MoodistKit

final class PlatformIntegrationTests: XCTestCase {
    func testSharedResourceBundleIsAvailableInApplicationBuild() {
        XCTAssertNotNil(MoodistResources.soundURL(SoundsData.categories[0].sounds[0]))
        XCTAssertEqual(PersistenceService.appearanceModeKey, "MoodistMac.appearanceMode")
    }
}
