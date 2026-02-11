import XCTest
@testable import ScrollDown

final class AppDateTests: XCTestCase {

    func testStartOfTomorrowAfterStartOfToday() {
        let today = AppDate.startOfToday
        let tomorrow = AppDate.startOfTomorrow
        XCTAssertGreaterThan(tomorrow, today)
    }

    func testEndOfTodaySameCalendarDayAsStartOfToday() {
        let startOfToday = AppDate.startOfToday
        let endOfToday = AppDate.endOfToday
        let calendar = Calendar.current
        XCTAssertEqual(
            calendar.component(.day, from: startOfToday),
            calendar.component(.day, from: endOfToday)
        )
    }

    func testHistoryWindowStartBeforeStartOfToday() {
        let today = AppDate.startOfToday
        let history = AppDate.historyWindowStart
        XCTAssertLessThan(history, today)
    }

    func testHistoryWindowStartIs2DaysBefore() {
        let today = AppDate.startOfToday
        let history = AppDate.historyWindowStart
        let interval = today.timeIntervalSince(history)
        // Should be approximately 2 days (172800 seconds)
        XCTAssertEqual(interval, 172800, accuracy: 1)
    }
}
