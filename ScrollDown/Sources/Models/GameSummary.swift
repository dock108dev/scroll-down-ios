import Foundation

/// Game summary for list views as defined in the OpenAPI spec (GameSummary schema)
struct GameSummary: Codable, Identifiable, Hashable {
    let id: Int
    let leagueCode: String
    let gameDate: String
    let status: GameStatus?
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let hasBoxscore: Bool?
    let hasPlayerStats: Bool?
    let hasOdds: Bool?
    let hasSocial: Bool?
    let hasPbp: Bool?
    let playCount: Int?
    let socialPostCount: Int?
    let hasRequiredData: Bool?
    let scrapeVersion: Int?
    let lastScrapedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case leagueCode = "league_code"
        case gameDate = "game_date"
        case status
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case hasBoxscore = "has_boxscore"
        case hasPlayerStats = "has_player_stats"
        case hasOdds = "has_odds"
        case hasSocial = "has_social"
        case hasPbp = "has_pbp"
        case playCount = "play_count"
        case socialPostCount = "social_post_count"
        case hasRequiredData = "has_required_data"
        case scrapeVersion = "scrape_version"
        case lastScrapedAt = "last_scraped_at"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: GameSummary, rhs: GameSummary) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties
extension GameSummary {
    private enum Formatting {
        static let startsAtPrefix = "Starts at "
        static let inProgressText = "Live"
        static let completedText = "Final — recap available"
        static let postponedText = "Postponed"
        static let canceledText = "Canceled"
        static let statusUnavailableText = "Status unavailable"
    }

    /// Formatted score string (e.g., "112 - 108")
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "— vs —"
        }
        return "\(home) - \(away)"
    }
    
    /// Parsed game date
    var parsedGameDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: gameDate) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: gameDate)
    }
    
    /// Formatted date for display
    var formattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Short formatted date (e.g., "Jan 1 • 7:30 PM")
    var shortFormattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }

    var statusLine: String {
        // The backend status is the source of truth; do not infer from scores or timestamps.
        guard let status else {
            GameStatusLogger.logMissingStatus(gameId: id, league: leagueCode)
            return Formatting.statusUnavailableText
        }

        switch status {
        case .scheduled:
            guard let date = parsedGameDate else { return Formatting.startsAtPrefix + formattedDate }
            return Formatting.startsAtPrefix + formattedTime(date: date)
        case .inProgress:
            return Formatting.inProgressText
        case .completed:
            return Formatting.completedText
        case .postponed:
            return Formatting.postponedText
        case .canceled:
            return Formatting.canceledText
        }
    }
    
    private func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

}

