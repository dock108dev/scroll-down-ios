import Foundation

/// Player boxscore statistics as defined in the OpenAPI spec (PlayerStat schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
struct PlayerStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let minutes: Double?
    let points: Int?
    let rebounds: Int?
    let assists: Int?
    let yards: Int?          // Football only
    let touchdowns: Int?     // Football only
    let rawStats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?

    /// Computed ID for Identifiable conformance
    var id: String { "\(team)-\(playerName)" }

    enum CodingKeys: String, CodingKey {
        case team
        case playerNameSnake = "player_name"
        case playerNameCamel = "playerName"
        case minutes
        case points
        case rebounds
        case assists
        case yards
        case touchdowns
        case rawStatsSnake = "raw_stats"
        case rawStatsCamel = "rawStats"
        case source
        case updatedAtSnake = "updated_at"
        case updatedAtCamel = "updatedAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        team = try container.decode(String.self, forKey: .team)

        playerName = (try? container.decode(String.self, forKey: .playerNameSnake))
            ?? (try? container.decode(String.self, forKey: .playerNameCamel))
            ?? "Unknown"

        minutes = try container.decodeIfPresent(Double.self, forKey: .minutes)
        points = try container.decodeIfPresent(Int.self, forKey: .points)
        rebounds = try container.decodeIfPresent(Int.self, forKey: .rebounds)
        assists = try container.decodeIfPresent(Int.self, forKey: .assists)
        yards = try container.decodeIfPresent(Int.self, forKey: .yards)
        touchdowns = try container.decodeIfPresent(Int.self, forKey: .touchdowns)

        rawStats = (try? container.decode([String: AnyCodable].self, forKey: .rawStatsSnake))
            ?? (try? container.decode([String: AnyCodable].self, forKey: .rawStatsCamel))
            ?? [:]

        source = try container.decodeIfPresent(String.self, forKey: .source)

        updatedAt = (try? container.decode(String.self, forKey: .updatedAtSnake))
            ?? (try? container.decode(String.self, forKey: .updatedAtCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team, forKey: .team)
        try container.encode(playerName, forKey: .playerNameSnake)
        try container.encodeIfPresent(minutes, forKey: .minutes)
        try container.encodeIfPresent(points, forKey: .points)
        try container.encodeIfPresent(rebounds, forKey: .rebounds)
        try container.encodeIfPresent(assists, forKey: .assists)
        try container.encodeIfPresent(yards, forKey: .yards)
        try container.encodeIfPresent(touchdowns, forKey: .touchdowns)
        try container.encode(rawStats, forKey: .rawStatsSnake)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAtSnake)
    }

    init(
        team: String,
        playerName: String,
        minutes: Double? = nil,
        points: Int? = nil,
        rebounds: Int? = nil,
        assists: Int? = nil,
        yards: Int? = nil,
        touchdowns: Int? = nil,
        rawStats: [String: AnyCodable] = [:],
        source: String? = nil,
        updatedAt: String? = nil
    ) {
        self.team = team
        self.playerName = playerName
        self.minutes = minutes
        self.points = points
        self.rebounds = rebounds
        self.assists = assists
        self.yards = yards
        self.touchdowns = touchdowns
        self.rawStats = rawStats
        self.source = source
        self.updatedAt = updatedAt
    }
}



