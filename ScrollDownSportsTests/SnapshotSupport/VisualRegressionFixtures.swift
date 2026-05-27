import Foundation
import SwiftUI
@testable import ScrollDownSports

@MainActor
enum VisualRegressionFixtures {
    static let now = TestFixtures.fixedDate("2026-05-23T16:00:00Z")

    static func homeViewModel(
        pinned: Bool = false,
        league: LeagueFilter = .all,
        teamQuery: String = ""
    ) -> HomeViewModel {
        let store = InMemoryGameStateStore(now: { now })
        let games = homeGames()
        if pinned {
            store.pin(games[2])
            store.pin(games[3])
            store.recordReadEvent(gameId: games[3].id, eventID: nil, eventIndex: 10, knownEventCount: 28)
        }

        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = games
        viewModel.league = league
        viewModel.teamQuery = teamQuery
        viewModel.lastUpdated = TestFixtures.fixedDate("2026-05-23T15:55:00Z")
        return viewModel
    }

    static func homeGames() -> [Game] {
        [
            ComponentSnapshotFixtures.game(
                id: 5_001,
                scheduledStart: TestFixtures.fixedDate("2026-05-20T23:10:00Z"),
                status: "final",
                isLive: false,
                isFinal: true,
                awayScore: 2,
                homeScore: 4,
                eventCount: 32,
                periodLabel: "Final"
            ),
            ComponentSnapshotFixtures.game(
                id: 5_002,
                scheduledStart: TestFixtures.fixedDate("2026-05-22T23:40:00Z"),
                status: "final",
                isLive: false,
                isFinal: true,
                awayName: "Canal City Comets",
                awayAbbreviation: "CCC",
                homeName: "Bay Harbor Lights",
                homeAbbreviation: "BAY",
                awayScore: 7,
                homeScore: 8,
                eventCount: 41,
                periodLabel: "Final"
            ),
            ComponentSnapshotFixtures.game(
                id: 5_003,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T15:10:00Z"),
                status: "in_progress",
                isLive: true,
                awayName: "North Arc Riders",
                awayAbbreviation: "NAR",
                homeName: "Bay Harbor Lights",
                homeAbbreviation: "BAY",
                awayScore: 4,
                homeScore: 5,
                eventCount: 36,
                periodOrdinal: 7,
                periodLabel: "B7",
                clockLabel: "2 outs"
            ),
            ComponentSnapshotFixtures.game(
                id: 5_004,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T20:20:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false,
                awayName: "Lake Union Hops",
                awayAbbreviation: "LUH",
                homeName: "Market District Nine",
                homeAbbreviation: "MDN",
                eventCount: nil,
                hasTimeline: false,
                hasScoreboard: false,
                presentation: ComponentSnapshotFixtures.previewPresentation()
            ),
            ComponentSnapshotFixtures.game(
                id: 5_005,
                leagueCode: "nba",
                scheduledStart: TestFixtures.fixedDate("2026-05-24T18:00:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false,
                awayName: "South Pier Five",
                awayAbbreviation: "SPF",
                homeName: "Hillcrest Union",
                homeAbbreviation: "HCU",
                eventCount: nil,
                hasTimeline: false,
                hasScoreboard: false,
                presentation: ComponentSnapshotFixtures.previewPresentation()
            ),
            ComponentSnapshotFixtures.game(
                id: 5_006,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T19:30:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false,
                awayName: "TBD",
                awayAbbreviation: "TBD",
                homeName: "Placeholder Park",
                homeAbbreviation: "PPK",
                hasTimeline: false,
                hasScoreboard: false,
                presentation: ComponentSnapshotFixtures.previewPresentation()
            )
        ]
    }

    static func detail(leagueCode: String = "mlb") -> GameDetail {
        let game = ComponentSnapshotFixtures.game(
            id: 5_500,
            leagueCode: leagueCode,
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 24,
            homeScore: 27,
            eventCount: detailEvents.count,
            periodOrdinal: 4,
            periodLabel: "Final",
            clockLabel: nil
        )

        var detail = ComponentSnapshotFixtures.statDetail()
        detail = GameDetail(
            game: game,
            teamStats: detail.teamStats,
            playerStats: detail.playerStats,
            events: detailEvents,
            mlbBatters: detail.mlbBatters,
            mlbPitchers: detail.mlbPitchers,
            nhlSkaters: detail.nhlSkaters,
            nhlGoalies: detail.nhlGoalies
        )
        return detail
    }

    static let detailEvents: [GameEvent] = [
        TestFixtures.makeEvent(
            sequence: 1,
            importance: .primary,
            headline: "North Arc opens with tempo and a clean finish",
            detail: "The first drive establishes pace without exposing the final score early.",
            periodLabel: "Q1",
            clockLabel: "12:00",
            eventType: "drive_start",
            homeScore: 0,
            awayScore: 0
        ),
        TestFixtures.makeEvent(
            sequence: 2,
            importance: .secondary,
            headline: "Bay Harbor answers with pressure at midfield",
            detail: "A short field keeps the catch-up stream dense and readable.",
            periodLabel: "Q2",
            clockLabel: "06:44",
            eventType: "pressure",
            homeScore: 10,
            awayScore: 14
        ),
        TestFixtures.makeEvent(
            sequence: 3,
            importance: .contextual,
            headline: "North Arc drains clock with two inside runs",
            detail: "The possession is useful context but remains visually subordinate.",
            periodLabel: "Q3",
            clockLabel: "03:18",
            eventType: "rush",
            homeScore: 17,
            awayScore: 21
        ),
        TestFixtures.makeEvent(
            sequence: 4,
            importance: .primary,
            headline: "Bay Harbor finishes the comeback with a short scoring run",
            detail: "The Lights convert after a sustained possession inside the red zone.",
            periodLabel: "Q4",
            clockLabel: "01:18",
            scoreDelta: ScoreDelta(participantID: "home-5500", participantRole: .home, before: 20, after: 27, change: 7),
            eventType: "touchdown",
            homeScore: 27,
            awayScore: 24
        )
    ]
}
