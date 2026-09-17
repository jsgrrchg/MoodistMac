import XCTest

final class MoodistFlowTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-MoodistMac.appLanguage", "en"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["open-player"].waitForExistence(timeout: 15))
        return app
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable, element.debugDescription)
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    func testCreateFavoriteAndRecallMix() {
        let app = launch()
        app.buttons["sound-river"].tap()
        app.buttons["open-player"].tap()
        XCTAssertTrue(app.buttons["player-toggle"].waitForExistence(timeout: 5))
        let save = app.buttons["Save as mix"]
        reveal(save, in: app); save.tap()
        let name = app.textFields["mix-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Evening test")
        app.buttons["save-mix"].tap()
        app.navigationBars.buttons["Close"].firstMatch.tap()
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.staticTexts["Evening test"].firstMatch.waitForExistence(timeout: 5))
        let favorite = app.buttons["Favorites: Evening test"].firstMatch
        reveal(favorite, in: app); favorite.tap()
        capture("library-custom-mix", app)
        app.staticTexts["Evening test"].firstMatch.tap()
        app.buttons["open-player"].tap()
        let pause = app.buttons["player-toggle"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertEqual(pause.label, "Pause")
        pause.tap()
        XCTAssertEqual(pause.label, "Play")
        capture("player-paused", app)
    }
    func testCurrentMixShowsSelectedSoundsWhilePausedAndAfterRemoval() {
        let app = launch()
        app.buttons["sound-river"].tap()
        app.buttons["sound-campfire"].tap()
        app.buttons["open-player"].tap()
        let river = app.staticTexts["player-sound-river"]
        let campfire = app.staticTexts["player-sound-campfire"]
        XCTAssertTrue(river.waitForExistence(timeout: 5))
        XCTAssertTrue(river.isHittable)
        XCTAssertTrue(campfire.isHittable)
        capture("player-selected-sounds", app)
        app.buttons["player-toggle"].tap()
        XCTAssertEqual(app.buttons["player-toggle"].label, "Play")
        XCTAssertTrue(river.exists)
        XCTAssertTrue(campfire.exists)
        app.buttons["remove-sound-river"].tap()
        XCTAssertFalse(river.exists)
        XCTAssertTrue(campfire.exists)
        app.buttons["remove-sound-campfire"].tap()
        XCTAssertFalse(campfire.exists)
        XCTAssertFalse(app.buttons["player-toggle"].isEnabled)
    }
    func testLongPressAdjustsOnlyThatSoundsVolumeWithoutTogglingSelection() {
        let app = launch()
        let river = app.buttons["sound-river"]
        river.tap()
        river.press(forDuration: 0.7)
        let volume = app.sliders["sound-volume-river"]
        XCTAssertTrue(volume.waitForExistence(timeout: 5))
        volume.adjust(toNormalizedSliderPosition: 0.25)
        capture("sound-volume-popover", app)
        let changedVolume = volume.value as? String
        XCTAssertNotNil(changedVolume)
        XCTAssertNotEqual(changedVolume, "50%")
        app.buttons["close-sound-volume"].tap()
        XCTAssertEqual(river.value as? String, "selected")
        river.press(forDuration: 0.7)
        XCTAssertTrue(volume.waitForExistence(timeout: 5))
        XCTAssertEqual(volume.value as? String, changedVolume)
        app.buttons["close-sound-volume"].tap()
        let campfire = app.buttons["sound-campfire"]
        campfire.press(forDuration: 0.7)
        let otherVolume = app.sliders["sound-volume-campfire"]
        XCTAssertTrue(otherVolume.waitForExistence(timeout: 5))
        XCTAssertEqual(otherVolume.value as? String, "50%")
        app.buttons["close-sound-volume"].tap()
        XCTAssertEqual(campfire.value as? String, "not selected")
        // A normal tap must still select a sound after dismissing the popover.
        campfire.tap()
        XCTAssertEqual(campfire.value as? String, "selected")
        app.buttons["open-player"].tap()
        let globalVolume = app.sliders["Global volume"]
        XCTAssertTrue(globalVolume.waitForExistence(timeout: 5))
        XCTAssertEqual(globalVolume.value as? String, "100%")
        XCTAssertEqual(app.sliders["Volume for River"].value as? String, changedVolume)
    }
    func testSettingsAndTimerNavigation() {
        let app = launch()
        app.buttons["open-settings"].tap()
        XCTAssertTrue(app.staticTexts["Mix with other apps"].waitForExistence(timeout: 5))
        capture("settings", app)
        app.navigationBars.buttons["Close"].firstMatch.tap()
        app.buttons["sound-river"].tap()
        app.buttons["open-player"].tap()
        let timer = app.buttons["Timer"]
        reveal(timer, in: app); timer.tap()
        XCTAssertTrue(app.buttons["start-sleep-timer"].waitForExistence(timeout: 5))
        capture("sleep-timer", app)
    }
    func testDarkAccessibilityTextLayout() {
        let app = launch(["-MoodistMac.appearanceMode", "dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.buttons["open-player"].isHittable)
        app.buttons["open-player"].tap()
        let shuffle = app.buttons["player-shuffle"]
        XCTAssertTrue(shuffle.waitForExistence(timeout: 5))
        reveal(shuffle, in: app)
        XCTAssertTrue(shuffle.isHittable)
        capture("large-text-dark-player", app)
    }
}
