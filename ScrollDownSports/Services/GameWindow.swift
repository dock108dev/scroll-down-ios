import Foundation

struct GameWindow: Equatable {
    let start: Date
    let end: Date

    static func current(now: Date = Date()) -> GameWindow {
        centeredOnToday(now: now)
    }

    static func home(now: Date = Date()) -> GameWindow {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let today = calendar.startOfDay(for: now)
        let start = now.addingTimeInterval(-72 * 60 * 60)
        let endOfTomorrow = calendar.date(byAdding: DateComponents(day: 2, second: -1), to: today)
        return GameWindow(
            start: start,
            end: endOfTomorrow ?? now.addingTimeInterval(36 * 60 * 60)
        )
    }

    static func centeredOnToday(now: Date = Date(), pastDays: Int = 7, futureDays: Int = 7) -> GameWindow {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -pastDays, to: today) ?? now.addingTimeInterval(-7 * 24 * 60 * 60)
        let endOfToday = calendar.date(byAdding: DateComponents(day: futureDays + 1, second: -1), to: today)
        let end = endOfToday ?? now.addingTimeInterval(7 * 24 * 60 * 60)
        return GameWindow(
            start: start,
            end: end
        )
    }

    var startDateQuery: String {
        DateFormatters.queryDate.string(from: start)
    }

    var endDateQuery: String {
        DateFormatters.queryDate.string(from: end)
    }

    var stableKey: String {
        "\(startDateQuery):\(endDateQuery)"
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }
}
