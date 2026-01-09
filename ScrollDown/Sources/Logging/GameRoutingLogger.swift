import Foundation
import OSLog

enum GameRoutingLogger {
    private static let logger = Logger(subsystem: "com.scrolldown.app", category: "routing")
    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func logTap(gameId: Int, league: String) {
        log(event: "tap", tappedId: gameId, destinationId: gameId, league: league, level: .notice)
    }

    static func logNavigation(tappedId: Int, destinationId: Int, league: String) {
        log(event: "navigate", tappedId: tappedId, destinationId: destinationId, league: league, level: .notice)
    }

    static func logDetailLoad(tappedId: Int, destinationId: Int, league: String?) {
        log(event: "detail_load", tappedId: tappedId, destinationId: destinationId, league: league, level: .notice)
    }

    static func logInvalidNavigation(tappedId: Int, destinationId: Int, league: String?) {
        log(event: "invalid_navigation", tappedId: tappedId, destinationId: destinationId, league: league, level: .error)
    }

    static func logMismatch(tappedId: Int, destinationId: Int, league: String?) {
        log(event: "id_mismatch", tappedId: tappedId, destinationId: destinationId, league: league, level: .error)
    }

    private static func log(
        event: String,
        tappedId: Int,
        destinationId: Int,
        league: String?,
        level: OSLogType
    ) {
        let timestamp = timestampFormatter.string(from: Date())
        let leagueValue = league ?? "unknown"
        logger.log(level: level, "routing_event=\(event, privacy: .public) tapped_id=\(tappedId, privacy: .public) destination_id=\(destinationId, privacy: .public) league=\(leagueValue, privacy: .public) timestamp=\(timestamp, privacy: .public)")
    }
}
