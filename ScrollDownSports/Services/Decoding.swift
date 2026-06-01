import Foundation

extension JSONDecoder {
    static var sda: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = ISO8601DateFormatter.sda.date(from: value) {
                return date
            }
            if let date = DateFormatters.apiDate.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported date string: \(value)"
            )
        }
        return decoder
    }
}

extension ISO8601DateFormatter {
    nonisolated(unsafe) static let sda: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension Calendar {
    static var sda: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return calendar
    }
}

enum DateFormatters {
    private static let easternTime = TimeZone(identifier: "America/New_York")

    private static func makeFormatter(timeZone: TimeZone?, dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = dateFormat
        return formatter
    }

    static let apiDate = makeFormatter(
        timeZone: TimeZone(secondsFromGMT: 0),
        dateFormat: "yyyy-MM-dd'T'HH:mm:ssXXXXX"
    )

    static let queryDate = makeFormatter(timeZone: easternTime, dateFormat: "yyyy-MM-dd")

    static let shortTime = makeFormatter(timeZone: easternTime, dateFormat: "EEE, MMM d · h:mm a")

    static let timeOnly = makeFormatter(timeZone: easternTime, dateFormat: "h:mm a")

    static let dayTitle = makeFormatter(timeZone: easternTime, dateFormat: "EEEE")

    static let daySubtitle = makeFormatter(timeZone: easternTime, dateFormat: "MMM d")
}
