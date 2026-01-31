import Foundation

/// Full game detail response as defined in the OpenAPI spec (GameDetailResponse schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
struct GameDetailResponse: Codable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let odds: [OddsEntry]
    let socialPosts: [SocialPostEntry]
    let plays: [PlayEntry]
    let derivedMetrics: [String: AnyCodable]
    let rawPayloads: [String: AnyCodable]

    // NHL-specific fields (empty for other leagues)
    let nhlSkaters: [NHLSkaterStat]?
    let nhlGoalies: [NHLGoalieStat]?
    let dataHealth: NHLDataHealth?

    enum CodingKeys: String, CodingKey {
        case game
        // snake_case keys (app endpoint)
        case teamStatsSnake = "team_stats"
        case playerStatsSnake = "player_stats"
        case socialPostsSnake = "social_posts"
        case derivedMetricsSnake = "derived_metrics"
        case rawPayloadsSnake = "raw_payloads"
        case nhlSkatersSnake = "nhl_skaters"
        case nhlGoaliesSnake = "nhl_goalies"
        case dataHealthSnake = "data_health"
        // camelCase keys (admin endpoint)
        case teamStatsCamel = "teamStats"
        case playerStatsCamel = "playerStats"
        case socialPostsCamel = "socialPosts"
        case derivedMetricsCamel = "derivedMetrics"
        case rawPayloadsCamel = "rawPayloads"
        case nhlSkatersCamel = "nhlSkaters"
        case nhlGoaliesCamel = "nhlGoalies"
        case dataHealthCamel = "dataHealth"
        // Common keys
        case odds
        case plays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        game = try container.decode(Game.self, forKey: .game)

        // Handle both snake_case and camelCase for each field
        teamStats = (try? container.decode([TeamStat].self, forKey: .teamStatsSnake))
            ?? (try? container.decode([TeamStat].self, forKey: .teamStatsCamel))
            ?? []

        playerStats = (try? container.decode([PlayerStat].self, forKey: .playerStatsSnake))
            ?? (try? container.decode([PlayerStat].self, forKey: .playerStatsCamel))
            ?? []

        odds = (try? container.decode([OddsEntry].self, forKey: .odds)) ?? []
        plays = (try? container.decode([PlayEntry].self, forKey: .plays)) ?? []

        socialPosts = (try? container.decode([SocialPostEntry].self, forKey: .socialPostsSnake))
            ?? (try? container.decode([SocialPostEntry].self, forKey: .socialPostsCamel))
            ?? []

        derivedMetrics = (try? container.decode([String: AnyCodable].self, forKey: .derivedMetricsSnake))
            ?? (try? container.decode([String: AnyCodable].self, forKey: .derivedMetricsCamel))
            ?? [:]

        rawPayloads = (try? container.decode([String: AnyCodable].self, forKey: .rawPayloadsSnake))
            ?? (try? container.decode([String: AnyCodable].self, forKey: .rawPayloadsCamel))
            ?? [:]

        nhlSkaters = (try? container.decode([NHLSkaterStat].self, forKey: .nhlSkatersSnake))
            ?? (try? container.decode([NHLSkaterStat].self, forKey: .nhlSkatersCamel))

        nhlGoalies = (try? container.decode([NHLGoalieStat].self, forKey: .nhlGoaliesSnake))
            ?? (try? container.decode([NHLGoalieStat].self, forKey: .nhlGoaliesCamel))

        dataHealth = (try? container.decode(NHLDataHealth.self, forKey: .dataHealthSnake))
            ?? (try? container.decode(NHLDataHealth.self, forKey: .dataHealthCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(game, forKey: .game)
        try container.encode(teamStats, forKey: .teamStatsSnake)
        try container.encode(playerStats, forKey: .playerStatsSnake)
        try container.encode(odds, forKey: .odds)
        try container.encode(socialPosts, forKey: .socialPostsSnake)
        try container.encode(plays, forKey: .plays)
        try container.encode(derivedMetrics, forKey: .derivedMetricsSnake)
        try container.encode(rawPayloads, forKey: .rawPayloadsSnake)
        try container.encodeIfPresent(nhlSkaters, forKey: .nhlSkatersSnake)
        try container.encodeIfPresent(nhlGoalies, forKey: .nhlGoaliesSnake)
        try container.encodeIfPresent(dataHealth, forKey: .dataHealthSnake)
    }

    // Memberwise initializer for mock data and testing
    init(
        game: Game,
        teamStats: [TeamStat] = [],
        playerStats: [PlayerStat] = [],
        odds: [OddsEntry] = [],
        socialPosts: [SocialPostEntry] = [],
        plays: [PlayEntry] = [],
        derivedMetrics: [String: AnyCodable] = [:],
        rawPayloads: [String: AnyCodable] = [:],
        nhlSkaters: [NHLSkaterStat]? = nil,
        nhlGoalies: [NHLGoalieStat]? = nil,
        dataHealth: NHLDataHealth? = nil
    ) {
        self.game = game
        self.teamStats = teamStats
        self.playerStats = playerStats
        self.odds = odds
        self.socialPosts = socialPosts
        self.plays = plays
        self.derivedMetrics = derivedMetrics
        self.rawPayloads = rawPayloads
        self.nhlSkaters = nhlSkaters
        self.nhlGoalies = nhlGoalies
        self.dataHealth = dataHealth
    }
}

// MARK: - NHL Skater Stats

/// NHL skater statistics (non-goalie players)
struct NHLSkaterStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let toi: String?              // Time on ice (MM:SS format)
    let goals: Int?
    let assists: Int?
    let points: Int?
    let shotsOnGoal: Int?
    let plusMinus: Int?
    let penaltyMinutes: Int?
    let hits: Int?
    let blockedShots: Int?
    let rawStats: [String: AnyCodable]?
    let source: String?
    let updatedAt: String?

    var id: String { "\(team)-\(playerName)" }

    enum CodingKeys: String, CodingKey {
        case team
        case playerName = "player_name"
        case toi
        case goals
        case assists
        case points
        case shotsOnGoal = "shots_on_goal"
        case plusMinus = "plus_minus"
        case penaltyMinutes = "penalty_minutes"
        case hits
        case blockedShots = "blocked_shots"
        case rawStats = "raw_stats"
        case source
        case updatedAt = "updated_at"
    }
}

// MARK: - NHL Goalie Stats

/// NHL goalie statistics
struct NHLGoalieStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let toi: String?              // Time on ice (MM:SS format)
    let shotsAgainst: Int?
    let saves: Int?
    let goalsAgainst: Int?
    let savePercentage: Double?   // Decimal (e.g., 0.923)
    let rawStats: [String: AnyCodable]?
    let source: String?
    let updatedAt: String?

    var id: String { "\(team)-\(playerName)" }

    enum CodingKeys: String, CodingKey {
        case team
        case playerName = "player_name"
        case toi
        case shotsAgainst = "shots_against"
        case saves
        case goalsAgainst = "goals_against"
        case savePercentage = "save_percentage"
        case rawStats = "raw_stats"
        case source
        case updatedAt = "updated_at"
    }
}

// MARK: - NHL Data Health

/// Data health indicators for NHL games
struct NHLDataHealth: Codable {
    let skaterCount: Int?
    let goalieCount: Int?
    let isHealthy: Bool?
    let issues: [String]?

    enum CodingKeys: String, CodingKey {
        case skaterCount = "skater_count"
        case goalieCount = "goalie_count"
        case isHealthy = "is_healthy"
        case issues
    }
}

/// Timeline artifact response as defined in the sports-admin API.
/// Holds pre-generated timeline JSON without client-side transformation.
///
/// Backend guarantees for backfilled games:
/// - `game_id`, `sport`, `timeline_version`, `generated_at` (required top-level)
/// - `timeline_json`: ordered list of events (event_type, synthetic_timestamp)
/// - `game_analysis_json`: segments[], highlights[]
/// - `summary_json`: overall + per-segment narratives
struct TimelineArtifactResponse: Codable {
    // MARK: - Required Top-Level Fields
    let gameId: Int?
    let sport: String?
    let timelineVersion: String?
    let generatedAt: String?
    
    // MARK: - Artifact Payloads
    let timelineJson: AnyCodable?
    let gameAnalysisJson: AnyCodable?
    let summaryJson: AnyCodable?

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case sport
        case timelineVersion = "timeline_version"
        case generatedAt = "generated_at"
        case timelineJson = "timeline_json"
        case gameAnalysisJson = "game_analysis_json"
        case summaryJson = "summary_json"
    }
}

// MARK: - AnyCodable for flexible JSON values
/// A type-erased Codable value for handling dynamic JSON objects
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }
}

