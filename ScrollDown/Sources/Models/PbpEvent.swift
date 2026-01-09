import Foundation

/// Detailed play-by-play event as defined in the OpenAPI spec (PbpEvent schema)
/// Note: id and game_id can be either string or integer per spec
///
/// REVEAL PHILOSOPHY:
/// - homeScore and awayScore are present in the model but NOT displayed by default
/// - The backend provides reveal-aware descriptions that don't leak outcomes
/// - Future phases will add reveal toggles; this phase prepares for that
/// - Timeline rendering must remain spoiler-safe by default
struct PbpEvent: Codable, Identifiable {
    let id: StringOrInt
    let gameId: StringOrInt
    let period: Int?
    let gameClock: String?
    let elapsedSeconds: Double?
    let eventType: String?
    let description: String?
    let team: String?
    let teamId: String?
    let playerName: String?
    let playerId: StringOrInt?
    let homeScore: Int? // Present but not displayed by default (reveal-aware)
    let awayScore: Int? // Present but not displayed by default (reveal-aware)
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case period
        case gameClock = "game_clock"
        case elapsedSeconds = "elapsed_seconds"
        case eventType = "event_type"
        case description
        case team
        case teamId = "team_id"
        case playerName = "player_name"
        case playerId = "player_id"
        case homeScore = "home_score"
        case awayScore = "away_score"
    }
}

/// PBP response as defined in the OpenAPI spec (PbpResponse schema)
struct PbpResponse: Codable {
    let events: [PbpEvent]
}

// MARK: - StringOrInt for flexible ID types
/// Handles fields that can be either string or integer in the API
enum StringOrInt: Codable, Hashable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                StringOrInt.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or Int"
                )
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
    
    /// Get value as String regardless of underlying type
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        }
    }
    
    /// Get value as Int if possible
    var intValue: Int? {
        switch self {
        case .string(let value):
            return Int(value)
        case .int(let value):
            return value
        }
    }
}



