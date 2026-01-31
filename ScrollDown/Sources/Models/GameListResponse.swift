import Foundation

/// Game list response from the admin API
struct GameListResponse: Decodable {
    let games: [GameSummary]
    let startDate: String?
    let endDate: String?
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
        withStoryCount: Int? = nil,
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
        self.withStoryCount = withStoryCount
        self.lastUpdatedAt = lastUpdatedAt
    }
}
