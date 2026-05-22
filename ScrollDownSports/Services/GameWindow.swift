import Foundation

struct GameWindow: Equatable {
    let start: Date
    let end: Date

    static func current(now: Date = Date()) -> GameWindow {
        GameWindow(
            start: now.addingTimeInterval(-72 * 60 * 60),
            end: now.addingTimeInterval(48 * 60 * 60)
        )
    }

    var startDateQuery: String {
        DateFormatters.queryDate.string(from: start)
    }

    var endDateQuery: String {
        DateFormatters.queryDate.string(from: end)
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }
}

