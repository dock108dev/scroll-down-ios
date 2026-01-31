import Foundation

/// Full game detail response
struct GameDetailResponse: Codable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let odds: [OddsEntry]
    let socialPosts: [SocialPostEntry]
    let plays: [PlayEntry]
    let derivedMetrics: [String: AnyCodable]
    let rawPayloads: [String: AnyCodable]

    // NHL-specific fields
    let nhlSkaters: [NHLSkaterStat]?
    let nhlGoalies: [NHLGoalieStat]?
    let dataHealth: NHLDataHealth?

    enum CodingKeys: String, CodingKey {
        case game
        case teamStats
        case playerStats
        case odds
        case socialPosts
        case plays
        case derivedMetrics
        case rawPayloads
        case nhlSkaters
        case nhlGoalies
        case dataHealth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        game = try container.decode(Game.self, forKey: .game)
        teamStats = try container.decodeIfPresent([TeamStat].self, forKey: .teamStats) ?? []
        playerStats = try container.decodeIfPresent([PlayerStat].self, forKey: .playerStats) ?? []
        odds = try container.decodeIfPresent([OddsEntry].self, forKey: .odds) ?? []
        socialPosts = try container.decodeIfPresent([SocialPostEntry].self, forKey: .socialPosts) ?? []
        plays = try container.decodeIfPresent([PlayEntry].self, forKey: .plays) ?? []
        derivedMetrics = try container.decodeIfPresent([String: AnyCodable].self, forKey: .derivedMetrics) ?? [:]
        rawPayloads = try container.decodeIfPresent([String: AnyCodable].self, forKey: .rawPayloads) ?? [:]
        nhlSkaters = try container.decodeIfPresent([NHLSkaterStat].self, forKey: .nhlSkaters)
        nhlGoalies = try container.decodeIfPresent([NHLGoalieStat].self, forKey: .nhlGoalies)
        dataHealth = try container.decodeIfPresent(NHLDataHealth.self, forKey: .dataHealth)
    }

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

struct NHLSkaterStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let toi: String?
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
}

// MARK: - NHL Goalie Stats

struct NHLGoalieStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let toi: String?
    let shotsAgainst: Int?
    let saves: Int?
    let goalsAgainst: Int?
    let savePercentage: Double?
    let rawStats: [String: AnyCodable]?
    let source: String?
    let updatedAt: String?

    var id: String { "\(team)-\(playerName)" }
}

// MARK: - NHL Data Health

struct NHLDataHealth: Codable {
    let skaterCount: Int?
    let goalieCount: Int?
    let isHealthy: Bool?
    let issues: [String]?
}

// MARK: - Timeline Artifact Response

struct TimelineArtifactResponse: Codable {
    let gameId: Int?
    let sport: String?
    let timelineVersion: String?
    let generatedAt: String?
    let timelineJson: AnyCodable?
    let gameAnalysisJson: AnyCodable?
    let summaryJson: AnyCodable?
}

// MARK: - AnyCodable

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
