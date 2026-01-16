import Foundation

/// Game list response matching the /games snapshot endpoint
struct GameListResponse: Decodable {
    let range: String?
    let games: [GameSummary]
    let total: Int?
    let nextOffset: Int?
    let withBoxscoreCount: Int?
    let withPlayerStatsCount: Int?
    let withOddsCount: Int?
    let withSocialCount: Int?
    let withPbpCount: Int?
    let lastUpdatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case range
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
    
    /// Memberwise initializer for creating filtered responses
    init(
        range: String?,
        games: [GameSummary],
        total: Int?,
        nextOffset: Int?,
        withBoxscoreCount: Int?,
        withPlayerStatsCount: Int?,
        withOddsCount: Int?,
        withSocialCount: Int?,
        withPbpCount: Int?,
        lastUpdatedAt: String?
    ) {
        self.range = range
        self.games = games
        self.total = total
        self.nextOffset = nextOffset
        self.withBoxscoreCount = withBoxscoreCount
        self.withPlayerStatsCount = withPlayerStatsCount
        self.withOddsCount = withOddsCount
        self.withSocialCount = withSocialCount
        self.withPbpCount = withPbpCount
        self.lastUpdatedAt = lastUpdatedAt
    }
}


