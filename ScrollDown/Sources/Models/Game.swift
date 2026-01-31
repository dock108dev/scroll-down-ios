import Foundation

/// Full game metadata as defined in the OpenAPI spec (GameMeta schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
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

    // CodingKeys for both snake_case and camelCase formats
    enum CodingKeys: String, CodingKey {
        case id
        // snake_case keys (app endpoint)
        case leagueCodeSnake = "league_code"
        case seasonType_snake = "season_type"
        case gameDateSnake = "game_date"
        case homeTeamSnake = "home_team"
        case awayTeamSnake = "away_team"
        case homeScoreSnake = "home_score"
        case awayScoreSnake = "away_score"
        case scrapeVersionSnake = "scrape_version"
        case lastScrapedAtSnake = "last_scraped_at"
        case hasBoxscoreSnake = "has_boxscore"
        case hasPlayerStatsSnake = "has_player_stats"
        case hasOddsSnake = "has_odds"
        case hasSocialSnake = "has_social"
        case hasPbpSnake = "has_pbp"
        case playCountSnake = "play_count"
        case socialPostCountSnake = "social_post_count"
        case homeTeamXHandleSnake = "home_team_x_handle"
        case awayTeamXHandleSnake = "away_team_x_handle"
        // camelCase keys (admin endpoint)
        case leagueCodeCamel = "leagueCode"
        case seasonTypeCamel = "seasonType"
        case gameDateCamel = "gameDate"
        case homeTeamCamel = "homeTeam"
        case awayTeamCamel = "awayTeam"
        case homeScoreCamel = "homeScore"
        case awayScoreCamel = "awayScore"
        case scrapeVersionCamel = "scrapeVersion"
        case lastScrapedAtCamel = "lastScrapedAt"
        case hasBoxscoreCamel = "hasBoxscore"
        case hasPlayerStatsCamel = "hasPlayerStats"
        case hasOddsCamel = "hasOdds"
        case hasSocialCamel = "hasSocial"
        case hasPbpCamel = "hasPbp"
        case playCountCamel = "playCount"
        case socialPostCountCamel = "socialPostCount"
        case homeTeamXHandleCamel = "homeTeamXHandle"
        case awayTeamXHandleCamel = "awayTeamXHandle"
        // Common keys
        case season
        case status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        season = try container.decode(Int.self, forKey: .season)
        status = try container.decode(GameStatus.self, forKey: .status)

        // Handle both snake_case and camelCase for each field
        leagueCode = (try? container.decode(String.self, forKey: .leagueCodeSnake))
            ?? (try? container.decode(String.self, forKey: .leagueCodeCamel))
            ?? "Unknown"

        seasonType = (try? container.decode(String.self, forKey: .seasonType_snake))
            ?? (try? container.decode(String.self, forKey: .seasonTypeCamel))

        gameDate = (try? container.decode(String.self, forKey: .gameDateSnake))
            ?? (try? container.decode(String.self, forKey: .gameDateCamel))
            ?? ""

        homeTeam = (try? container.decode(String.self, forKey: .homeTeamSnake))
            ?? (try? container.decode(String.self, forKey: .homeTeamCamel))
            ?? "Home"

        awayTeam = (try? container.decode(String.self, forKey: .awayTeamSnake))
            ?? (try? container.decode(String.self, forKey: .awayTeamCamel))
            ?? "Away"

        homeScore = (try? container.decode(Int.self, forKey: .homeScoreSnake))
            ?? (try? container.decode(Int.self, forKey: .homeScoreCamel))

        awayScore = (try? container.decode(Int.self, forKey: .awayScoreSnake))
            ?? (try? container.decode(Int.self, forKey: .awayScoreCamel))

        scrapeVersion = (try? container.decode(Int.self, forKey: .scrapeVersionSnake))
            ?? (try? container.decode(Int.self, forKey: .scrapeVersionCamel))

        lastScrapedAt = (try? container.decode(String.self, forKey: .lastScrapedAtSnake))
            ?? (try? container.decode(String.self, forKey: .lastScrapedAtCamel))

        hasBoxscore = (try? container.decode(Bool.self, forKey: .hasBoxscoreSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasBoxscoreCamel))

        hasPlayerStats = (try? container.decode(Bool.self, forKey: .hasPlayerStatsSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasPlayerStatsCamel))

        hasOdds = (try? container.decode(Bool.self, forKey: .hasOddsSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasOddsCamel))

        hasSocial = (try? container.decode(Bool.self, forKey: .hasSocialSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasSocialCamel))

        hasPbp = (try? container.decode(Bool.self, forKey: .hasPbpSnake))
            ?? (try? container.decode(Bool.self, forKey: .hasPbpCamel))

        playCount = (try? container.decode(Int.self, forKey: .playCountSnake))
            ?? (try? container.decode(Int.self, forKey: .playCountCamel))

        socialPostCount = (try? container.decode(Int.self, forKey: .socialPostCountSnake))
            ?? (try? container.decode(Int.self, forKey: .socialPostCountCamel))

        homeTeamXHandle = (try? container.decode(String.self, forKey: .homeTeamXHandleSnake))
            ?? (try? container.decode(String.self, forKey: .homeTeamXHandleCamel))

        awayTeamXHandle = (try? container.decode(String.self, forKey: .awayTeamXHandleSnake))
            ?? (try? container.decode(String.self, forKey: .awayTeamXHandleCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(leagueCode, forKey: .leagueCodeSnake)
        try container.encode(season, forKey: .season)
        try container.encodeIfPresent(seasonType, forKey: .seasonType_snake)
        try container.encode(gameDate, forKey: .gameDateSnake)
        try container.encode(homeTeam, forKey: .homeTeamSnake)
        try container.encode(awayTeam, forKey: .awayTeamSnake)
        try container.encodeIfPresent(homeScore, forKey: .homeScoreSnake)
        try container.encodeIfPresent(awayScore, forKey: .awayScoreSnake)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(scrapeVersion, forKey: .scrapeVersionSnake)
        try container.encodeIfPresent(lastScrapedAt, forKey: .lastScrapedAtSnake)
        try container.encodeIfPresent(hasBoxscore, forKey: .hasBoxscoreSnake)
        try container.encodeIfPresent(hasPlayerStats, forKey: .hasPlayerStatsSnake)
        try container.encodeIfPresent(hasOdds, forKey: .hasOddsSnake)
        try container.encodeIfPresent(hasSocial, forKey: .hasSocialSnake)
        try container.encodeIfPresent(hasPbp, forKey: .hasPbpSnake)
        try container.encodeIfPresent(playCount, forKey: .playCountSnake)
        try container.encodeIfPresent(socialPostCount, forKey: .socialPostCountSnake)
        try container.encodeIfPresent(homeTeamXHandle, forKey: .homeTeamXHandleSnake)
        try container.encodeIfPresent(awayTeamXHandle, forKey: .awayTeamXHandleSnake)
    }

    // Memberwise initializer for mock data and testing
    init(
        id: Int,
        leagueCode: String,
        season: Int,
        seasonType: String? = nil,
        gameDate: String,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        status: GameStatus,
        scrapeVersion: Int? = nil,
        lastScrapedAt: String? = nil,
        hasBoxscore: Bool? = nil,
        hasPlayerStats: Bool? = nil,
        hasOdds: Bool? = nil,
        hasSocial: Bool? = nil,
        hasPbp: Bool? = nil,
        playCount: Int? = nil,
        socialPostCount: Int? = nil,
        homeTeamXHandle: String? = nil,
        awayTeamXHandle: String? = nil
    ) {
        self.id = id
        self.leagueCode = leagueCode
        self.season = season
        self.seasonType = seasonType
        self.gameDate = gameDate
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.status = status
        self.scrapeVersion = scrapeVersion
        self.lastScrapedAt = lastScrapedAt
        self.hasBoxscore = hasBoxscore
        self.hasPlayerStats = hasPlayerStats
        self.hasOdds = hasOdds
        self.hasSocial = hasSocial
        self.hasPbp = hasPbp
        self.playCount = playCount
        self.socialPostCount = socialPostCount
        self.homeTeamXHandle = homeTeamXHandle
        self.awayTeamXHandle = awayTeamXHandle
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

