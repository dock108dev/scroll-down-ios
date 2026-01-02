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
        static let startPrefix = "Starts "
        static let dateTemplate = "MMM d"
        static let timeStyle: DateFormatter.Style = .short
        static let dateTimeSeparator = " — "
        static let inProgressText = "Game in progress"
        static let completedText = "Final — tap for recap"
        static let postponedText = "Postponed"
        static let canceledText = "Canceled"
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

    var inferredStatus: GameStatus {
        if let status {
            return status
        }
        if homeScore != nil || awayScore != nil {
            return .completed
        }
        if let playCount, playCount > 0 {
            return .inProgress
        }
        return .scheduled
    }

    var statusLine: String {
        switch inferredStatus {
        case .scheduled:
            guard let date = parsedGameDate else { return formattedDate }
            return Formatting.startPrefix + formattedStartTime(date: date)
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

    private func formattedStartTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate(Formatting.dateTemplate)
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = Formatting.timeStyle
        let dateText = dateFormatter.string(from: date)
        let timeText = timeFormatter.string(from: date)
        return dateText + Formatting.dateTimeSeparator + timeText
    }
}

