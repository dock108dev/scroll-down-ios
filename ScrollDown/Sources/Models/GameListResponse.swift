import Foundation

/// Game list response matching the /api/games endpoint
struct GameListResponse: Decodable {
    let games: [GameSummary]

    // New API format
    let startDate: String?
    let endDate: String?

    // Legacy format (for compatibility)
    let range: String?
    let total: Int?
    let nextOffset: Int?
    let withBoxscoreCount: Int?
    let withPlayerStatsCount: Int?
    let withOddsCount: Int?
    let withSocialCount: Int?
    let withPbpCount: Int?
    let withStoryCount: Int?
    let lastUpdatedAt: String?

    enum CodingKeys: String, CodingKey {
        case games
        case startDate = "start_date"
        case endDate = "end_date"
        case range
        case total
        case nextOffset = "next_offset"
        case withBoxscoreCount = "with_boxscore_count"
        case withPlayerStatsCount = "with_player_stats_count"
        case withOddsCount = "with_odds_count"
        case withSocialCount = "with_social_count"
        case withPbpCount = "with_pbp_count"
        case withStoryCount = "with_story_count"
        case lastUpdatedAt = "last_updated_at"
    }

    /// Memberwise initializer for creating filtered responses
    init(
        games: [GameSummary],
        startDate: String? = nil,
        endDate: String? = nil,
        range: String? = nil,
        total: Int? = nil,
        nextOffset: Int? = nil,
        withBoxscoreCount: Int? = nil,
        withPlayerStatsCount: Int? = nil,
        withOddsCount: Int? = nil,
        withSocialCount: Int? = nil,
        withPbpCount: Int? = nil,
        lastUpdatedAt: String? = nil
    ) {
        self.games = games
        self.startDate = startDate
        self.endDate = endDate
        self.range = range
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
