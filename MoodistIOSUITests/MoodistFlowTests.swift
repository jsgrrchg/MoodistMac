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
