import XCTest
@testable import ScrollDownSports

final class GameWindowTests: XCTestCase {
    func testCurrentWindowUsesMinus72Plus48Hours() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let window = GameWindow.current(now: now)

        XCTAssertEqual(window.start, now.addingTimeInterval(-72 * 60 * 60))
        XCTAssertEqual(window.end, now.addingTimeInterval(48 * 60 * 60))
        XCTAssertTrue(window.contains(now))
        XCTAssertFalse(window.contains(now.addingTimeInterval(-73 * 60 * 60)))
        XCTAssertFalse(window.contains(now.addingTimeInterval(49 * 60 * 60)))
    }
}

