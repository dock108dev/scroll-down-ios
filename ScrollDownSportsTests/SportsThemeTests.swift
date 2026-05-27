import SwiftUI
import UIKit
import XCTest
@testable import ScrollDownSports

final class SportsThemeTests: XCTestCase {
    func testRendererRegistryRoutesSpecializedSportsAndFallbacks() {
        XCTAssertTrue(SportRendererRegistry.renderer(for: "mlb") is BaseballRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "NHL") is HockeyRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "nfl") is FootballRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "nba") is BasketballRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "mls") is SoccerRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "pga") is GolfRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "tennis") is TennisRenderer)
        XCTAssertTrue(SportRendererRegistry.renderer(for: "unknown") is GenericSportRenderer)
    }

    func testBaseballRendererOwnsBatterAndPitcherStatPresentation() {
        let detail = GameDetail(
            game: makeGame(leagueCode: "mlb"),
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: [
                MLBBatterStat(
                    team: "Boston Red Sox",
                    playerName: "Example Batter",
                    position: nil,
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
                    team: "Boston Red Sox",
                    playerName: "Example Pitcher",
                    inningsPitched: "6.0",
                    hits: 4,
                    runs: 2,
                    earnedRuns: 2,
                    baseOnBalls: 1,
                    strikeOuts: 5,
                    homeRuns: 0
                )
            ],
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let sections = SportRendererRegistry.renderer(for: detail.game).statsPresentation(for: detail).playerSections

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].highlights.first?.title, "Example Batter")
        XCTAssertEqual(sections[0].highlights.first?.headline, "2-for-4, 1 HR, 3 RBI")
        XCTAssertEqual(sections.map(\.title), ["Batters", "Pitchers"])
        XCTAssertEqual(sections[0].tables.map(\.title), ["Batters"])
        XCTAssertEqual(sections[1].tables.map(\.title), ["Pitchers"])
        XCTAssertEqual(sections[0].tables[0].columns.map(\.label), ["Player", "Team", "Pos", "AB", "H", "R", "RBI", "HR", "BB", "K"])
        XCTAssertEqual(sections[1].tables[0].rows[0].values["ip"], "6.0")
        XCTAssertTrue(sections[0].cards.isEmpty)
    }

    func testGenericStatsUseImpactSummaryAndCompactDynamicColumns() {
        let detail = GameDetail(
            game: makeGame(leagueCode: "nba"),
            teamStats: [],
            playerStats: [
                PlayerStat(
                    team: "LA",
                    playerName: "J. Rivers",
                    minutes: 34,
                    points: 28,
                    rebounds: 8,
                    assists: 6,
                    yards: nil,
                    touchdowns: nil,
                    rawStats: [:]
                ),
                PlayerStat(
                    team: "DAL",
                    playerName: "M. Stone",
                    minutes: nil,
                    points: nil,
                    rebounds: nil,
                    assists: nil,
                    yards: 110,
                    touchdowns: 2,
                    rawStats: [:]
                )
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let section = SportRendererRegistry.renderer(for: detail.game).statsPresentation(for: detail).playerSections[0]

        XCTAssertEqual(section.highlights.map(\.title), ["J. Rivers"])
        XCTAssertEqual(section.highlights[0].stats.map(\.label), ["MIN", "PTS", "REB"])
        XCTAssertEqual(section.tables[0].title, "Full Stats")
        XCTAssertEqual(section.tables[0].columns.map(\.label), ["Player", "Team", "MIN", "PTS", "REB", "AST"])
        XCTAssertTrue(section.cards.isEmpty)
    }

    func testSportSpecificFallbackStatsDoNotLeakWrongColumns() {
        let baseballDetail = GameDetail(
            game: makeGame(leagueCode: "mlb"),
            teamStats: [],
            playerStats: [
                PlayerStat(
                    team: "SEA",
                    playerName: "M. Reed",
                    minutes: 0,
                    points: 0,
                    rebounds: 0,
                    assists: 0,
                    yards: nil,
                    touchdowns: nil,
                    rawStats: ["hits": .number(3), "rbi": .number(2), "homeRuns": .number(1), "strikeOuts": .number(1)]
                )
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
        let baseballSection = SportRendererRegistry.renderer(for: baseballDetail.game).statsPresentation(for: baseballDetail).playerSections[0]

        XCTAssertEqual(baseballSection.tables[0].columns.map(\.label), ["Player", "Team", "H", "RBI", "HR", "K"])
        XCTAssertEqual(baseballSection.highlights[0].headline, "3 H, 2 RBI, 1 HR")
        XCTAssertFalse(baseballSection.tables[0].columns.map(\.label).contains("PTS"))

        let footballDetail = GameDetail(
            game: makeGame(leagueCode: "nfl"),
            teamStats: [],
            playerStats: [
                PlayerStat(
                    team: "NYG",
                    playerName: "T. Field",
                    minutes: nil,
                    points: 14,
                    rebounds: nil,
                    assists: nil,
                    yards: 110,
                    touchdowns: 2,
                    rawStats: [:]
                )
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
        let footballSection = SportRendererRegistry.renderer(for: footballDetail.game).statsPresentation(for: footballDetail).playerSections[0]

        XCTAssertEqual(footballSection.tables[0].columns.map(\.label), ["Player", "Team", "YDS", "TD"])
        XCTAssertFalse(footballSection.tables[0].columns.map(\.label).contains("PTS"))
    }

    func testHockeyStatsIncludeGoalieImpactAndSavePercentageTable() {
        let detail = GameDetail(
            game: makeGame(leagueCode: "nhl"),
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: [
                NHLPlayerStat(
                    team: "SEA",
                    playerName: "A. Nolan",
                    goals: 2,
                    assists: 0,
                    points: 2,
                    shotsOnGoal: 5,
                    saves: nil,
                    goalsAgainst: nil,
                    rawStats: nil
                )
            ],
            nhlGoalies: [
                NHLPlayerStat(
                    team: "VAN",
                    playerName: "B. Cross",
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

        let sections = SportRendererRegistry.renderer(for: detail.game).statsPresentation(for: detail).playerSections

        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections.flatMap { $0.highlights.map(\.title) }, ["A. Nolan", "B. Cross"])
        XCTAssertEqual(sections.map(\.title), ["Skaters", "Goalies"])
        XCTAssertEqual(sections[1].tables[0].columns.map(\.label), ["Player", "Team", "SV", "GA", "SV%"])
        XCTAssertEqual(sections[1].tables[0].rows[0].values["svp"], ".944")
    }

    func testTeamStatsUseHighlightsAndCompactTable() {
        let detail = GameDetail(
            game: makeGame(leagueCode: "mlb"),
            teamStats: [
                TeamStat(
                    team: "Away",
                    isHome: false,
                    stats: [:],
                    normalizedStats: [
                        NormalizedStat(key: "hits", displayLabel: "H", group: nil, value: .number(9)),
                        NormalizedStat(key: "errors", displayLabel: "E", group: nil, value: .number(1))
                    ]
                ),
                TeamStat(
                    team: "Home",
                    isHome: true,
                    stats: [:],
                    normalizedStats: [
                        NormalizedStat(key: "hits", displayLabel: "H", group: nil, value: .number(6)),
                        NormalizedStat(key: "errors", displayLabel: "E", group: nil, value: .number(0))
                    ]
                )
            ],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let section = SportRendererRegistry.renderer(for: detail.game).statsPresentation(for: detail).teamSection

        XCTAssertEqual(section.highlights.map(\.title), [])
        XCTAssertEqual(section.comparison?.columns.map(\.title), ["AWA", "HOM"])
        XCTAssertEqual(section.comparison?.columns.map(\.subtitle), ["Away", "Home"])
        XCTAssertEqual(section.comparison?.rows.map(\.label), ["H", "E"])
        XCTAssertEqual(section.comparison?.rows[0].values["Away-false-0"], "9")
        XCTAssertEqual(section.comparison?.rows[0].values["Home-true-1"], "6")
        XCTAssertTrue(section.tables.isEmpty)
        XCTAssertTrue(section.cards.isEmpty)
    }

    func testInningsPitchedParsingForPitcherImpact() {
        XCTAssertEqual(StatPresentationBuilder.outs(from: "6.0"), 18)
        XCTAssertEqual(StatPresentationBuilder.outs(from: "6.1"), 19)
        XCTAssertEqual(StatPresentationBuilder.outs(from: "6.2"), 20)
        XCTAssertEqual(StatPresentationBuilder.outs(from: nil), 0)
        XCTAssertEqual(StatPresentationBuilder.outs(from: "-"), 0)
    }

    func testGenericFallbackDoesNotUseBaseballTerminology() {
        let detail = GameDetail(
            game: makeGame(leagueCode: "tennis"),
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let renderer = SportRendererRegistry.renderer(for: detail.game)
        let stats = renderer.statsPresentation(for: detail)
        let scoreboard = renderer.scoreboardPresentation(for: detail.game)

        XCTAssertEqual(renderer.theme.sportLabel, "Tennis")
        XCTAssertEqual(stats.playerSections.first?.emptyMessage, "No player stats available yet.")
        XCTAssertFalse(scoreboard.title.localizedCaseInsensitiveContains("inning"))
    }

    func testBaseballScoreboardUsesLineScoreOnlyWithSegments() {
        let game = makeGame(
            leagueCode: "mlb",
            scoreboard: GameScoreboardData(
                layout: "inning_table",
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: "Final",
                scoreline: "Away 4, Home 2",
                competitors: [
                    ScoreboardCompetitorData(
                        id: "away",
                        side: .away,
                        teamName: "Away Team",
                        teamAbbreviation: "AWY",
                        score: 4,
                        scoreText: "4",
                        isWinner: true,
                        recordText: nil
                    ),
                    ScoreboardCompetitorData(
                        id: "home",
                        side: .home,
                        teamName: "Home Team",
                        teamAbbreviation: "HME",
                        score: 2,
                        scoreText: "2",
                        isWinner: false,
                        recordText: nil
                    )
                ],
                segments: [
                    ScoreboardSegmentData(label: "1", away: "1", home: "0"),
                    ScoreboardSegmentData(label: "2", away: "3", home: "2")
                ],
                totals: ScoreboardTotalsData(away: "4", home: "2")
            )
        )

        let presentation = SportRendererRegistry.renderer(for: game).scoreboardPresentation(for: game)

        XCTAssertEqual(presentation.layout, .segmentTable)
        XCTAssertEqual(presentation.title, "Line Score")
        XCTAssertEqual(presentation.totalHeader, "R")
        XCTAssertEqual(presentation.segments.map(\.label), ["1", "2"])
        XCTAssertEqual(presentation.rows.map(\.totalText), ["4", "2"])
        XCTAssertTrue(presentation.rows[0].isWinner)
    }

    func testScoreboardFallsBackToSimpleTotalsWithoutSegments() {
        let game = makeGame(
            leagueCode: "nba",
            scoreboard: GameScoreboardData(
                layout: "period_table",
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: "Final",
                scoreline: nil,
                competitors: [],
                segments: [],
                totals: nil
            )
        )

        let presentation = SportRendererRegistry.renderer(for: game).scoreboardPresentation(for: game)

        XCTAssertEqual(presentation.layout, .simpleTotal)
        XCTAssertTrue(presentation.segments.isEmpty)
        XCTAssertEqual(presentation.rows.map(\.totalText), ["1", "2"])
    }

    func testGolfScoreboardUsesLeaderboardLayoutWhenBackendRequestsIt() {
        let game = makeGame(
            leagueCode: "pga",
            scoreboard: GameScoreboardData(
                layout: "leaderboard",
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: "Final",
                scoreline: nil,
                competitors: [
                    ScoreboardCompetitorData(
                        id: "leader",
                        side: .other("leader"),
                        teamName: "A. Stone",
                        teamAbbreviation: nil,
                        score: nil,
                        scoreText: "-12",
                        isWinner: true,
                        recordText: "F"
                    )
                ],
                segments: [],
                totals: nil
            )
        )

        let presentation = SportRendererRegistry.renderer(for: game).scoreboardPresentation(for: game)

        XCTAssertEqual(presentation.layout, .leaderboard)
        XCTAssertEqual(presentation.title, "Leaderboard")
        XCTAssertEqual(presentation.rows.first?.title, "A. Stone")
        XCTAssertEqual(presentation.rows.first?.totalText, "-12")
    }

    func testGenericRendererCoversStatusLayoutsAndLeagueAccentBranches() {
        let live = TestFixtures.makeGame(
            id: 7001,
            leagueCode: "ncaaf",
            status: "in_progress",
            isLive: true,
            periodOrdinal: nil,
            periodLabel: nil,
            clockLabel: nil
        )
        let scheduled = TestFixtures.makeGame(id: 7002, leagueCode: "wnba", status: "scheduled", isLive: false, isFinal: false)
        let final = TestFixtures.makeGame(id: 7003, leagueCode: "ncaab", status: "final", isLive: false, isFinal: true)
        let catchUp = TestFixtures.makeGame(id: 7004, leagueCode: "nfl", status: "delayed", isLive: false, isFinal: false)

        XCTAssertEqual(GenericSportRenderer(leagueCode: "ncaaf").statusText(for: live), "In progress")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "wnba").statusText(for: scheduled), "Scheduled")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "ncaab").statusText(for: final), "Final")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "nfl").statusText(for: catchUp), "Catch up")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "ncaaf").scoreboardPresentation(for: live).stateText, "In progress")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "wnba").scoreboardPresentation(for: scheduled).stateText, "Scheduled")
        XCTAssertEqual(GenericSportRenderer(leagueCode: "ncaab").scoreboardPresentation(for: final).stateText, "Final")

        for league in ["MLB", "NBA", "WNBA", "NHL", "NFL", "NCAAB", "NCAAF", " "] {
            _ = UIColor(GenericSportRenderer(leagueCode: league).theme.accentColor)
        }

        let soccer = makeGame(
            leagueCode: "mls",
            scoreboard: GameScoreboardData(
                layout: "goals_summary",
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: nil,
                scoreline: nil,
                competitors: [],
                segments: [],
                totals: nil
            )
        )
        let simpleLineScore = makeGame(
            leagueCode: "nba",
            scoreboard: GameScoreboardData(
                layout: "quarter_table",
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: nil,
                scoreline: nil,
                competitors: [],
                segments: [],
                totals: nil
            )
        )

        XCTAssertEqual(GenericSportRenderer(leagueCode: "mls").scoreboardPresentation(for: soccer).layout, .soccerSummary)
        XCTAssertEqual(GenericSportRenderer(leagueCode: "nba").scoreboardPresentation(for: simpleLineScore).layout, .simpleTotal)
    }

    func testGenericSituationFallbackCoversSportMappingAndPriorityBranches() {
        let sportCases: [(String, GameEventSituationSport)] = [
            ("mlb", .baseball),
            ("nfl", .football),
            ("nhl", .hockey),
            ("nba", .basketball),
            ("mls", .soccer),
            ("pga", .golf),
            ("tennis", .tennis),
            ("pickleball", .generic)
        ]

        for (offset, sportCase) in sportCases.enumerated() {
            let event = genericSituationEvent(
                sequence: 7200 + offset,
                importance: .primary,
                importanceMetadata: EventImportanceData(
                    level: nil,
                    rank: 75,
                    bucket: nil,
                    reasons: [],
                    isKeyMoment: true,
                    isScoringPlay: false,
                    isLeadChange: false,
                    isTyingPlay: false,
                    winProbabilityDelta: nil
                )
            )
            let situation = GenericSportRenderer(leagueCode: sportCase.0)
                .eventSituationPresentation(for: event, context: genericSituationContext(for: event, leagueCode: sportCase.0))

            XCTAssertEqual(situation?.sport, sportCase.1, sportCase.0)
            XCTAssertEqual(situation?.layout, .pressureBoardFallback, sportCase.0)
        }

        let critical = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(
                sequence: 7210,
                importance: .secondary,
                importanceMetadata: EventImportanceData(
                    level: "primary",
                    rank: nil,
                    bucket: nil,
                    reasons: [],
                    isKeyMoment: true,
                    isScoringPlay: false,
                    isLeadChange: false,
                    isTyingPlay: false,
                    winProbabilityDelta: nil
                )
            )
        )
        let mediumScoring = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(
                sequence: 7211,
                importance: .secondary,
                scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 10, after: 12, change: 2)
            )
        )
        let mediumKey = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(
                sequence: 7212,
                importance: .secondary,
                importanceMetadata: EventImportanceData(
                    level: nil,
                    rank: 45,
                    bucket: nil,
                    reasons: [],
                    isKeyMoment: true,
                    isScoringPlay: false,
                    isLeadChange: false,
                    isTyingPlay: false,
                    winProbabilityDelta: nil
                )
            )
        )
        let mediumNotable = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(sequence: 7213, importance: .secondary)
        )
        let lowScoring = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(
                sequence: 7214,
                importance: .contextual,
                scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 10, after: 13, change: 3)
            )
        )
        let lowKey = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(
                sequence: 7215,
                importance: .contextual,
                importanceMetadata: EventImportanceData(
                    level: nil,
                    rank: 55,
                    bucket: nil,
                    reasons: [],
                    isKeyMoment: true,
                    isScoringPlay: false,
                    isLeadChange: false,
                    isTyingPlay: false,
                    winProbabilityDelta: nil
                )
            )
        )
        let lowRoutine = genericSituation(
            leagueCode: "nba",
            event: genericSituationEvent(sequence: 7216, importance: .contextual)
        )

        XCTAssertEqual(critical?.accent.tone, .neutral)
        XCTAssertEqual(mediumScoring?.pressureLine, "Scoring play")
        XCTAssertEqual(mediumKey?.pressureLine, "Key play")
        XCTAssertEqual(mediumNotable?.pressureLine, "Notable play")
        XCTAssertEqual(lowScoring?.pressureLine, "Scoring play")
        XCTAssertEqual(lowKey?.pressureLine, "Key play")
        XCTAssertNil(lowRoutine)
    }

    func testSemanticToneInventoryCoversGameAndEventStates() {
        XCTAssertEqual(
            Set(SportsTheme.Tone.allCases),
            [.live, .final, .pinned, .scoring, .critical, .defensivePitching, .neutral, .newPlay, .scoreboard]
        )
    }

    func testSurfaceTokensProvideExpectedSharedShapes() {
        XCTAssertEqual(SportsTheme.Surface.gameCard.radius, SportsTheme.Radius.card)
        XCTAssertEqual(SportsTheme.Surface.gameHeaderCard.radius, SportsTheme.Radius.card)
        XCTAssertEqual(SportsTheme.Surface.eventCard.radius, SportsTheme.Radius.card)
        XCTAssertEqual(SportsTheme.Surface.streamControlBar.radius, SportsTheme.Radius.control)
        XCTAssertEqual(SportsTheme.Surface.scoreboardCard.radius, SportsTheme.Radius.card)
        XCTAssertEqual(SportsTheme.Surface.statSummary.radius, SportsTheme.Radius.card)
        XCTAssertEqual(SportsTheme.Surface.compactTableRow.radius, SportsTheme.Radius.row)
    }

    func testCoreTextAndFillTokensMeetContrastMinimums() {
        let textPairs: [(String, Color, Color)] = [
            ("ink on paper", SportsTheme.Colors.ink, SportsTheme.Colors.paper),
            ("ink on raised paper", SportsTheme.Colors.ink, SportsTheme.Colors.paperRaised),
            ("secondary ink on paper", SportsTheme.Colors.secondaryInk, SportsTheme.Colors.paper),
            ("secondary ink on inset paper", SportsTheme.Colors.secondaryInk, SportsTheme.Colors.paperInset)
        ]

        for (name, foreground, background) in textPairs {
            assertContrast(foreground, on: background, name: name)
        }

        for tone in SportsTheme.Tone.allCases {
            assertContrast(SportsTheme.Colors.textOnFill, on: tone.accent, name: "text on \(tone.rawValue)")
        }
    }

    func testPageBackgroundTokensUseDarkSpecificWashAndOverlayStrength() {
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        let lightPaper = UIColor(SportsTheme.Colors.paper).resolvedColor(with: lightTraits)
        let darkPaper = UIColor(SportsTheme.Colors.paper).resolvedColor(with: darkTraits)
        let darkWashAccent = UIColor(SportsTheme.Background.darkWashAccent).resolvedColor(with: darkTraits)

        XCTAssertGreaterThan(relativeLuminance(lightPaper), 0.78)
        XCTAssertLessThan(relativeLuminance(darkPaper), 0.01)
        XCTAssertLessThan(relativeLuminance(darkWashAccent), 0.03)
        XCTAssertGreaterThan(SportsTheme.Background.darkGridOpacity, SportsTheme.Background.lightGridOpacity)
        XCTAssertLessThan(SportsTheme.Background.darkPaperVeilOpacity, SportsTheme.Background.lightPaperVeilOpacity)
    }

}

private extension SportsThemeTests {
    func genericSituation(
        leagueCode: String,
        event: GameEvent
    ) -> GameEventSituationPresentation? {
        GenericSportRenderer(leagueCode: leagueCode)
            .eventSituationPresentation(for: event, context: genericSituationContext(for: event, leagueCode: leagueCode))
    }

    func genericSituationContext(
        for event: GameEvent,
        leagueCode: String
    ) -> SportRendererSituationContext {
        let selectedMode: DetailStreamMode
        if event.eligibleModes.contains(.timeline) {
            selectedMode = .key
        } else if event.eligibleModes.contains(.flow) {
            selectedMode = .flow
        } else {
            selectedMode = .full
        }
        return SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 7300 + event.sequence, leagueCode: leagueCode),
            selectedMode: selectedMode,
            visibleEvents: [event],
            eventIndex: 0
        )
    }

    func genericSituationEvent(
        sequence: Int,
        importance: GameEventImportance,
        importanceMetadata: EventImportanceData? = nil,
        scoreDelta: ScoreDelta? = nil
    ) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            importance: importance,
            periodLabel: "Q4",
            clockLabel: "00:42",
            scoreDelta: scoreDelta,
            eventType: "Pressure play",
            importanceMetadata: importanceMetadata,
            homeScore: scoreDelta?.before ?? 10,
            awayScore: 10
        )
    }
}
