import Foundation

/// Full game metadata as defined in the OpenAPI spec (GameMeta schema)
struct Game: Codable, Identifiable, Hashable {
    let id: Int
    let leagueCode: String
    let season: Int
    let seasonType: String?
    let gameDate: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let status: GameStatus
    let scrapeVersion: Int?
    let lastScrapedAt: String?
    let hasBoxscore: Bool?
    let hasPlayerStats: Bool?
    let hasOdds: Bool?
    let hasSocial: Bool?
    let hasPbp: Bool?
    let playCount: Int?
    let socialPostCount: Int?
    let homeTeamXHandle: String?
    let awayTeamXHandle: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case leagueCode = "league_code"
        case season
        case seasonType = "season_type"
        case gameDate = "game_date"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case status
        case scrapeVersion = "scrape_version"
        case lastScrapedAt = "last_scraped_at"
        case hasBoxscore = "has_boxscore"
        case hasPlayerStats = "has_player_stats"
        case hasOdds = "has_odds"
        case hasSocial = "has_social"
        case hasPbp = "has_pbp"
        case playCount = "play_count"
        case socialPostCount = "social_post_count"
        case homeTeamXHandle = "home_team_x_handle"
        case awayTeamXHandle = "away_team_x_handle"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties
extension Game {
    /// Formatted date for display
    var formattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Formatted score string (e.g., "112 - 108")
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "— vs —"
        }
        return "\(home) - \(away)"
    }

    var matchupTitle: String {
        "\(awayTeam) at \(homeTeam)"
    }
    
    /// Parsed game date
    var parsedGameDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: gameDate) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: gameDate)
    }
}

