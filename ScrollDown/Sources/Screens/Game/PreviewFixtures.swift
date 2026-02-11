import Foundation

enum PreviewFixtures {
    static let highlightsHeavyGame: GameDetailResponse = {
        let base: GameDetailResponse = try! MockLoader.load("game-001")
        return base
    }()

    static let highlightsLightGame: GameDetailResponse = {
        let base: GameDetailResponse = try! MockLoader.load("game-002")
        return GameDetailResponse(
            game: base.game,
            teamStats: base.teamStats,
            playerStats: base.playerStats,
            odds: base.odds,
            socialPosts: Array(base.socialPosts.prefix(1)),
            plays: base.plays,
            derivedMetrics: base.derivedMetrics,
            rawPayloads: base.rawPayloads,
            nhlSkaters: nil,
            nhlGoalies: nil,
            dataHealth: nil
        )
    }()

    static let overtimeGame: GameDetailResponse = {
        let base: GameDetailResponse = try! MockLoader.load("game-001")
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
            rawPayloads: base.rawPayloads,
            nhlSkaters: nil,
            nhlGoalies: nil,
            dataHealth: nil
        )
    }()

    static let preGameOnlyGame: GameDetailResponse = {
        let base: GameDetailResponse = try! MockLoader.load("game-001")
        return GameDetailResponse(
            game: base.game,
            teamStats: [],
            playerStats: [],
            odds: [],
            socialPosts: base.socialPosts,
            plays: [],
            derivedMetrics: base.derivedMetrics,
            rawPayloads: base.rawPayloads,
            nhlSkaters: nil,
            nhlGoalies: nil,
            dataHealth: nil
        )
    }()
}
