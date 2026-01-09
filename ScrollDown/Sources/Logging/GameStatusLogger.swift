import Foundation
import OSLog

/// Logs missing or invalid game status values
/// WHY: Helps identify data quality issues from backend where status field is unexpectedly nil
enum GameStatusLogger {
    private static let logger = Logger(subsystem: "com.scrolldown.app", category: "status")
    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func logMissingStatus(gameId: Int, league: String) {
        let timestamp = timestampFormatter.string(from: Date())
        logger.error("missing_status game_id=\(gameId, privacy: .public) league=\(league, privacy: .public) timestamp=\(timestamp, privacy: .public)")
    }
}
