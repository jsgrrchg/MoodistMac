import XCTest
@testable import MoodistIOS

@MainActor
private final class SessionSpy: AudioSessionDriving {
    var events: [String] = []
    var fail = false
    func configure(mixing: Bool) throws { events.append(mixing ? "mix" : "primary") }
    func activate() throws { if fail { throw NSError(domain: "session", code: 1) }; events.append("activate") }
    func deactivate() throws { events.append("deactivate") }
}
final class AudioSessionTests: XCTestCase {
    func testLifecycleAndFailure() async throws {
        try await MainActor.run {
            let driver = SessionSpy()
            let controller = IOSAudioSessionController(driver: driver, defaults: UserDefaults(suiteName: UUID().uuidString)!)
            try controller.prepare(); try controller.prepare(); controller.stop()
            XCTAssertEqual(driver.events, ["primary", "activate", "deactivate"])
            driver.fail = true
            XCTAssertThrowsError(try controller.prepare())
            XCTAssertFalse(controller.active)
        }
    }
}
