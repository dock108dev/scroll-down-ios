import Foundation

enum PreviewFixtures {
    static let highlightsHeavyGame: GameDetailResponse = {
        let base: GameDetailResponse = MockLoader.load("game-001")
        return base
    }()

    static let highlightsLightGame: GameDetailResponse = {
        let base: GameDetailResponse = MockLoader.load("game-002")
        return GameDetailResponse(
            game: base.game,
            teamStats: base.teamStats,
            playerStats: base.playerStats,
            odds: base.odds,
            socialPosts: Array(base.socialPosts.prefix(1)),
            plays: base.plays,
            derivedMetrics: base.derivedMetrics,
            rawPayloads: base.rawPayloads
        )
    }()

    static let overtimeGame: GameDetailResponse = {
        let base: GameDetailResponse = MockLoader.load("game-001")
        let extraPlay = PlayEntry(
            playIndex: 999,
            quarter: 5,
            gameClock: "00:45",
            playType: .play,
            teamAbbreviation: "BOS",
            playerName: "J. Tatum",
            description: "Overtime jumper gives the lead.",
            homeScore: 112,
            awayScore: 110
        )
        let plays = base.plays + [extraPlay]
        return GameDetailResponse(
            game: base.game,
            teamStats: base.teamStats,
            playerStats: base.playerStats,
            odds: base.odds,
            socialPosts: base.socialPosts,
            plays: plays,
            derivedMetrics: base.derivedMetrics,
            rawPayloads: base.rawPayloads
        )
    }()

    static let preGameOnlyGame: GameDetailResponse = {
        let base: GameDetailResponse = MockLoader.load("game-001")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let gameDate = formatter.date(from: base.game.gameDate)
        let preGamePosts = base.socialPosts.filter { post in
            guard let gameDate else {
                return true
            }
            guard let postDate = formatter.date(from: post.postedAt) else {
                return true
            }
            return postDate < gameDate
        }
        return GameDetailResponse(
            game: base.game,
            teamStats: [],
            playerStats: [],
            odds: [],
            socialPosts: preGamePosts,
            plays: [],
            derivedMetrics: base.derivedMetrics,
            rawPayloads: base.rawPayloads
        )
    }()
}
