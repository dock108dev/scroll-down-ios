import Foundation

/// Full game detail response as defined in the OpenAPI spec (GameDetailResponse schema)
struct GameDetailResponse: Codable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let odds: [OddsEntry]
    let socialPosts: [SocialPostEntry]
    let plays: [PlayEntry]
    let moments: [Moment]?
    let compactMoments: [CompactMoment]?
    let derivedMetrics: [String: AnyCodable]
    let rawPayloads: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case game
        case teamStats = "team_stats"
        case playerStats = "player_stats"
        case odds
        case socialPosts = "social_posts"
        case plays
        case moments
        case compactMoments = "compact_moments"
        case derivedMetrics = "derived_metrics"
        case rawPayloads = "raw_payloads"
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

