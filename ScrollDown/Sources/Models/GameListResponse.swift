import Foundation

/// Game list response as defined in the OpenAPI spec (GameListResponse schema)
struct GameListResponse: Codable {
    let games: [GameSummary]
    let total: Int
    let nextOffset: Int?
    let withBoxscoreCount: Int?
    let withPlayerStatsCount: Int?
    let withOddsCount: Int?
    let withSocialCount: Int?
    let withPbpCount: Int?
    let lastUpdatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case games
        case total
        case nextOffset = "next_offset"
        case withBoxscoreCount = "with_boxscore_count"
        case withPlayerStatsCount = "with_player_stats_count"
        case withOddsCount = "with_odds_count"
        case withSocialCount = "with_social_count"
        case withPbpCount = "with_pbp_count"
        case lastUpdatedAt = "last_updated_at"
    }
}


