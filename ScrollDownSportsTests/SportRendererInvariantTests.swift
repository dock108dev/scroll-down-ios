import XCTest
@testable import ScrollDownSports

@MainActor
final class SportRendererInvariantTests: XCTestCase {
    func testGenericRendererProvidesFallbackStatsForUnknownLeague() {
        let game = TestFixtures.makeGame(id: 1501, leagueCode: "pickleball")
        let detail = GameDetail(
            game: game,
            teamStats: [],
            playerStats: [
                PlayerStat(
                    team: "Away",
                    playerName: "Alex Stone",
                    minutes: nil,
                    points: 14,
                    rebounds: nil,
                    assists: 3,
                    yards: nil,
                    touchdowns: nil,
                    rawStats: [:]
                )
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let stats = SportRendererRegistry.renderer(for: game).statsPresentation(for: detail)

        XCTAssertEqual(stats.playerSections.map(\.id), ["player-stats"])
        XCTAssertEqual(stats.playerSections.first?.tables.map(\.id), ["generic-full-stats"])
        XCTAssertEqual(SportRendererRegistry.renderer(for: game).gameCardPresentation(for: game).sportLabel, "Pickleball")
    }

    func testBaseballRendererRoutesToBaseballStatTables() {
        let game = TestFixtures.makeGame(id: 1502, leagueCode: "mlb")
        let detail = GameDetail(
            game: game,
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: [
                MLBBatterStat(
                    team: "SEA",
                    playerName: "Mara Vale",
                    position: "RF",
                    atBats: 4,
                    hits: 2,
                    runs: 1,
                    rbi: 3,
                    homeRuns: 1,
                    baseOnBalls: 0,
                    strikeOuts: 1
                )
            ],
            mlbPitchers: [
                MLBPitcherStat(
                    team: "SEA",
                    playerName: "Noel King",
                    inningsPitched: "6.1",
                    hits: 4,
                    runs: 2,
                    earnedRuns: 2,
                    baseOnBalls: 1,
                    strikeOuts: 7,
                    homeRuns: 0
                )
            ],
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let stats = SportRendererRegistry.renderer(for: game).statsPresentation(for: detail)

        XCTAssertEqual(stats.playerSections.map(\.id), ["baseball-player-stats"])
        XCTAssertEqual(stats.playerSections.first?.tables.map(\.id), ["baseball-batters", "baseball-pitchers"])
    }

    func testHockeyRendererRoutesToSkaterAndGoalieTables() {
        let game = TestFixtures.makeGame(id: 1503, leagueCode: "nhl")
        let detail = GameDetail(
            game: game,
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: [
                NHLPlayerStat(
                    team: "EV",
                    playerName: "Ira Frost",
                    goals: 2,
                    assists: 1,
                    points: 3,
                    shotsOnGoal: 5,
                    saves: nil,
                    goalsAgainst: nil,
                    rawStats: nil
                )
            ],
            nhlGoalies: [
                NHLPlayerStat(
                    team: "NH",
                    playerName: "Sam North",
                    goals: nil,
                    assists: nil,
                    points: nil,
                    shotsOnGoal: nil,
                    saves: 34,
                    goalsAgainst: 2,
                    rawStats: nil
                )
            ]
        )

        let stats = SportRendererRegistry.renderer(for: game).statsPresentation(for: detail)

        XCTAssertEqual(stats.playerSections.map(\.id), ["hockey-player-stats"])
        XCTAssertEqual(stats.playerSections.first?.tables.map(\.id), ["hockey-skaters", "hockey-goalies"])
    }
}
