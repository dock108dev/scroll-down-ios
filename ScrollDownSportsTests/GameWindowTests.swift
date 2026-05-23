import XCTest
@testable import ScrollDownSports

final class GameWindowTests: XCTestCase {
    func testCurrentWindowCentersOnToday() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let window = GameWindow.current(now: now)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let today = calendar.startOfDay(for: now)

        XCTAssertEqual(window.start, calendar.date(byAdding: .day, value: -7, to: today))
        XCTAssertEqual(window.end, calendar.date(byAdding: DateComponents(day: 8, second: -1), to: today))
        XCTAssertTrue(window.contains(now))
        XCTAssertFalse(window.contains(calendar.date(byAdding: .day, value: -8, to: today)!))
        XCTAssertFalse(window.contains(calendar.date(byAdding: .day, value: 8, to: today)!))
    }

    func testHomeWindowUsesSeventyTwoHourLookbackAndTomorrowUpcoming() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let window = GameWindow.home(now: now)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let today = calendar.startOfDay(for: now)

        XCTAssertEqual(window.start, now.addingTimeInterval(-72 * 60 * 60))
        XCTAssertEqual(window.end, calendar.date(byAdding: DateComponents(day: 2, second: -1), to: today))
        XCTAssertTrue(window.contains(now))
        XCTAssertTrue(window.contains(calendar.date(byAdding: .day, value: 1, to: today)!))
        XCTAssertFalse(window.contains(now.addingTimeInterval(-73 * 60 * 60)))
        XCTAssertFalse(window.contains(calendar.date(byAdding: .day, value: 2, to: today)!))
    }
}
