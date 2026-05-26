import SwiftUI
import XCTest
@testable import ScrollDownSports

final class FormattingUtilityCoverageTests: XCTestCase {
    func testPeriodFormatterCoversSportSpecificOvertimeAndFallbacks() {
        let basketballOvertime = PeriodLabelFormatter.output(
            sport: .nba,
            leagueCode: "NBA",
            periodOrdinal: nil,
            periodLabel: "OT",
            clockLabel: "OT 03:00"
        )
        let baseball = PeriodLabelFormatter.output(
            sport: .mlb,
            leagueCode: "MLB",
            periodOrdinal: nil,
            periodLabel: "Top of the 11th",
            clockLabel: "Top of the 11th 2 outs"
        )
        let footballDoubleOvertime = PeriodLabelFormatter.output(
            sport: .nfl,
            leagueCode: "NFL",
            periodOrdinal: nil,
            periodLabel: "double ot",
            clockLabel: "2OT 01:22"
        )
        let hockeyShootout = PeriodLabelFormatter.output(
            sport: .nhl,
            leagueCode: "NHL",
            periodOrdinal: nil,
            periodLabel: "Shootout",
            clockLabel: "SO"
        )
        let hockeyOvertime = PeriodLabelFormatter.output(
            sport: .nhl,
            leagueCode: "NHL",
            periodOrdinal: nil,
            periodLabel: "OT",
            clockLabel: "OT 01:15"
        )
        let hockeyPrefixedPeriod = PeriodLabelFormatter.output(
            sport: .nhl,
            leagueCode: "NHL",
            periodOrdinal: nil,
            periodLabel: "P2",
            clockLabel: "P2 04:18"
        )
        let soccerFirstByMinute = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: nil,
            periodLabel: nil,
            clockLabel: "30'"
        )
        let soccerSecondByMinute = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: nil,
            periodLabel: nil,
            clockLabel: "75'"
        )
        let soccerExtra = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: nil,
            periodLabel: "Extra Time",
            clockLabel: "91+3"
        )
        let soccerSecond = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: nil,
            periodLabel: "Second Half",
            clockLabel: nil
        )
        let soccerPenalties = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: 4,
            periodLabel: nil,
            clockLabel: nil
        )
        let soccerOrdinalExtra = PeriodLabelFormatter.output(
            sport: .soccer,
            leagueCode: "EPL",
            periodOrdinal: 3,
            periodLabel: nil,
            clockLabel: nil
        )
        let generic = PeriodLabelFormatter.output(
            sport: .tennis,
            leagueCode: "ATP",
            periodOrdinal: nil,
            periodLabel: "Set 3",
            clockLabel: "Set 3 tiebreak"
        )
        let genericOrdinal = PeriodLabelFormatter.output(
            sport: .golf,
            leagueCode: "",
            periodOrdinal: 2,
            periodLabel: nil,
            clockLabel: nil
        )

        XCTAssertEqual(basketballOvertime.groupLabel, "OT")
        XCTAssertEqual(basketballOvertime.rowClockText, "03:00")
        XCTAssertEqual(baseball.groupLabel, "Top 11th")
        XCTAssertEqual(baseball.rowClockText, "2 outs")
        XCTAssertEqual(footballDoubleOvertime.groupLabel, "2OT")
        XCTAssertEqual(footballDoubleOvertime.rowClockText, "01:22")
        XCTAssertEqual(hockeyShootout.groupLabel, "SO")
        XCTAssertEqual(hockeyShootout.rowClockText, "")
        XCTAssertEqual(hockeyOvertime.groupLabel, "OT")
        XCTAssertEqual(hockeyOvertime.rowClockText, "01:15")
        XCTAssertEqual(hockeyPrefixedPeriod.groupLabel, "2nd")
        XCTAssertEqual(hockeyPrefixedPeriod.rowClockText, "04:18")
        XCTAssertEqual(soccerFirstByMinute.groupLabel, "1st Half")
        XCTAssertEqual(soccerFirstByMinute.rowClockText, "30'")
        XCTAssertEqual(soccerSecondByMinute.groupLabel, "2nd Half")
        XCTAssertEqual(soccerSecondByMinute.rowClockText, "75'")
        XCTAssertEqual(soccerExtra.groupLabel, "Extra Time")
        XCTAssertEqual(soccerExtra.rowClockText, "91'+3'")
        XCTAssertEqual(soccerSecond.groupKey, "soccer:half:2")
        XCTAssertEqual(soccerPenalties.groupKey, "soccer:period:penalties")
        XCTAssertEqual(soccerOrdinalExtra.groupLabel, "Extra Time")
        XCTAssertEqual(generic.groupKey, "period:set 3")
        XCTAssertEqual(generic.combinedText, "Set 3 · tiebreak")
        XCTAssertEqual(genericOrdinal.groupKey, "period:generic:2")
        XCTAssertEqual(genericOrdinal.combinedText, "Period 2")
    }

    func testEventLabelResolverCoversHeadlinesAccessibilityAndRawDetection() {
        XCTAssertEqual(EventLabelResolver.customerLabel(from: "GOAL"), "Goal")
        XCTAssertEqual(EventLabelResolver.customerText(from: "PERIOD_END"), "Period end")
        XCTAssertNil(EventLabelResolver.customerText(from: "GAME_UPDATE"))
        XCTAssertNil(EventLabelResolver.customerLabel(from: "UNMAPPED_PROVIDER_ENUM"))
        XCTAssertTrue(EventLabelResolver.isRawEnumLabel("SOME_RAW_LABEL"))
        XCTAssertTrue(EventLabelResolver.isRawEnumLabel("UNKNOWN"))
        XCTAssertFalse(EventLabelResolver.isRawEnumLabel("Q4"))

        XCTAssertEqual(
            EventLabelResolver.customerHeadline(
                presentationHeadline: "   ",
                presentationBody: "Readable body",
                description: "Fallback description",
                displayType: "TOUCHDOWN"
            ),
            "Readable body"
        )
        XCTAssertEqual(
            EventLabelResolver.customerHeadline(
                presentationHeadline: "SOME_RAW_LABEL",
                presentationBody: nil,
                description: nil,
                displayType: "FIELD_GOAL_GOOD"
            ),
            "Field goal"
        )
        XCTAssertEqual(
            EventLabelResolver.customerAccessibilityText(preferred: "UNKNOWN", fallbackPieces: ["Goal scored", "SHOT_ON_GOAL"]),
            "Goal scored. Shot on goal"
        )
        XCTAssertEqual(EventLabelResolver.customerAccessibilityText(preferred: nil, fallbackPieces: []), "Game update")
    }

    func testJSONValueAndAppEnvironmentUtilityBranches() throws {
        let payload = #"{"array":[1,"two"],"bool":true,"decimal":3.25,"integer":4,"null":null,"object":{"nested":"value"},"string":"text"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode([String: JSONValue].self, from: payload)

        XCTAssertEqual(decoded["string"]?.displayString, "text")
        XCTAssertEqual(decoded["integer"]?.displayString, "4")
        XCTAssertEqual(decoded["decimal"]?.displayString, "3.2")
        XCTAssertEqual(decoded["bool"]?.displayString, "Yes")
        XCTAssertEqual(decoded["null"]?.displayString, "-")
        XCTAssertEqual(decoded["array"]?.displayString, "")
        XCTAssertEqual(decoded["object"]?.displayString, "")
        XCTAssertEqual(decoded["integer"]?.numberValue, 4)

        let encoded = try JSONEncoder().encode(decoded)
        XCTAssertFalse(encoded.isEmpty)

        withEnvironment([
            "SDS_UI_TEST_FIXTURE": " critical-final-game ",
            "SDS_HOME_INITIAL_ANCHOR": " today ",
            "SDS_UI_TEST_DYNAMIC_TYPE": "accessibility2",
            "SDS_RESET_STATE": "YES"
        ]) {
            XCTAssertEqual(AppEnvironment.uiTestFixtureName, "critical-final-game")
            XCTAssertTrue(AppEnvironment.isRunningUITests)
            XCTAssertEqual(AppEnvironment.uiTestHomeInitialAnchor, "today")
            XCTAssertEqual(AppEnvironment.uiTestDynamicTypeSize, .accessibility2)
            XCTAssertTrue(AppEnvironment.shouldResetStateForUITests)
        }
    }

    func testStatFormattingCoversHeadlinesCellsRankingAndRawHelpers() {
        let points = player(points: 21, rebounds: 7, assists: 5)
        let football = player(yards: 88, touchdowns: 2)
        let raw = player(rawStats: [
            "goals": .number(2),
            "assists": .string("1"),
            "shots": .number(6),
            "saves": .number(11)
        ])
        let empty = player()

        XCTAssertEqual(StatPresentationBuilder.genericHeadline(for: points), "21 pts, 7 reb, 5 ast")
        XCTAssertEqual(StatPresentationBuilder.genericHeadline(for: football), "88 yds, 2 TD")
        XCTAssertEqual(StatPresentationBuilder.genericHeadline(for: raw), "2 goals, 1 assists, 6 shots")
        XCTAssertEqual(StatPresentationBuilder.genericHeadline(for: empty), "")
        XCTAssertEqual(StatPresentationBuilder.rawString(["missing", "assists"], in: raw.rawStats), "1")
        XCTAssertEqual(StatPresentationBuilder.rawDouble(["assists"], in: raw.rawStats), 1)
        XCTAssertEqual(StatPresentationBuilder.rawDouble(["missing"], in: raw.rawStats), 0)

        XCTAssertEqual(StatPresentationBuilder.batterHeadline(for: batter(hits: 2, atBats: 4, runs: 1, rbi: 3, homeRuns: 1)), "2-for-4, 1 HR, 3 RBI")
        XCTAssertEqual(StatPresentationBuilder.batterHeadline(for: batter(hits: 1, atBats: nil, runs: 1, rbi: 0, homeRuns: 0)), "1 H, 1 R")
        XCTAssertEqual(StatPresentationBuilder.pitcherHeadline(for: pitcher(earnedRuns: 2, hits: 4)), "6.1 IP, 7 K, 2 ER")
        XCTAssertEqual(StatPresentationBuilder.pitcherHeadline(for: pitcher(earnedRuns: nil, hits: 4)), "6.1 IP, 7 K, 4 H")
        XCTAssertEqual(StatPresentationBuilder.skaterHeadline(for: skater(goals: 2, assists: 1, points: 3, shots: 5)), "2 G, 1 A, 5 SOG")
        XCTAssertEqual(StatPresentationBuilder.skaterHeadline(for: skater(goals: 1, assists: 0, points: 1, shots: 4)), "1 goals, 4 shots")
        XCTAssertEqual(StatPresentationBuilder.skaterHeadline(for: skater(goals: 0, assists: 2, points: 2, shots: 3)), "2 assists, 2 pts")
        XCTAssertEqual(StatPresentationBuilder.skaterHeadline(for: skater(goals: 0, assists: 0, points: 0, shots: 3)), "3 shots")
        XCTAssertEqual(StatPresentationBuilder.goalieHeadline(for: goalie(saves: 31, goalsAgainst: 2)), "31 saves, 2 GA")
        XCTAssertEqual(StatPresentationBuilder.goalieHeadline(for: goalie(saves: nil, goalsAgainst: nil)), "0 saves")

        XCTAssertEqual(StatPresentationBuilder.batterCells(for: batter(hits: 2, atBats: 4, runs: 1, rbi: 3, homeRuns: 1)).map(\.label), ["HR", "RBI", "H", "R"])
        XCTAssertEqual(StatPresentationBuilder.pitcherCells(for: pitcher(earnedRuns: nil, hits: 4)).map(\.label), ["IP", "K"])
        XCTAssertEqual(StatPresentationBuilder.skaterCells(for: skater(goals: 1, assists: 2, points: 3, shots: 4)).map(\.label), ["G", "A", "PTS", "SOG"])
        XCTAssertEqual(StatPresentationBuilder.goalieCells(for: goalie(saves: nil, goalsAgainst: 0)).map(\.value), ["0"])

        let highlights = [
            (highlight(id: "b", title: "Beta"), 8.0),
            (highlight(id: "a", title: "Alpha"), 8.0),
            (highlight(id: "c", title: "Charlie"), 7.0)
        ]
        var selected = StatPresentationBuilder.mergeHighlights(highlights, [(highlight(id: "d", title: "Delta"), 9.0)])
        StatPresentationBuilder.includeDiverseHighlight(&selected, candidate: highlight(id: "e", title: "Echo"), score: 6.0)
        StatPresentationBuilder.includeDiverseHighlight(&selected, candidate: highlight(id: "a", title: "Alpha"), score: 10.0)
        StatPresentationBuilder.includeDiverseHighlight(&selected, candidate: nil, score: 10.0)
        StatPresentationBuilder.includeDiverseHighlight(&selected, candidate: highlight(id: "f", title: "Foxtrot"), score: 5.0)
        XCTAssertEqual(StatPresentationBuilder.ranked(selected).map(\.rank), [1, 2, 3, 4])
        XCTAssertEqual(StatPresentationBuilder.ranked(selected).map(\.title).first, "Delta")

        var shortSelection: [(StatHighlightPresentation, Double)] = []
        StatPresentationBuilder.replaceLast(&shortSelection, with: (highlight(id: "solo", title: "Solo"), 2.0))
        XCTAssertEqual(shortSelection.map { $0.0.id }, ["solo"])

        let batters = [ScoredBatter(player: batter(playerName: "Batter A"), score: 4)]
        let pitchers = [ScoredPitcher(player: pitcher(playerName: "Pitcher A"), score: 5)]
        let nhlPlayers = [ScoredNHLPlayer(player: skater(playerName: "Skater A", goals: 1, assists: 0, points: 1, shots: 2), role: "Skater", score: 6)]
        XCTAssertEqual(StatPresentationBuilder.scoreForBatter(id: "SEA-Batter A-batter", in: batters), 4)
        XCTAssertEqual(StatPresentationBuilder.scoreForPitcher(id: "SEA-Pitcher A-pitcher", in: pitchers), 5)
        XCTAssertEqual(StatPresentationBuilder.scoreForNHL(id: "SEA-Skater A-skater", in: nhlPlayers, suffix: "-skater"), 6)
        XCTAssertEqual(StatPresentationBuilder.scoreForBatter(id: "missing", in: batters), 0)
        XCTAssertEqual(StatPresentationBuilder.scoreForPitcher(id: "missing", in: pitchers), 0)
        XCTAssertEqual(StatPresentationBuilder.scoreForNHL(id: "missing-skater", in: nhlPlayers, suffix: "-skater"), 0)
        XCTAssertTrue(StatPresentationBuilder.sortScoredPlayers(ScoredPlayerStat(player: player(playerName: "A"), score: 2), ScoredPlayerStat(player: player(playerName: "B"), score: 1)))
        XCTAssertTrue(StatPresentationBuilder.sortScoredBatters(ScoredBatter(player: batter(playerName: "A"), score: 2), ScoredBatter(player: batter(playerName: "B"), score: 1)))
        XCTAssertTrue(StatPresentationBuilder.sortScoredPitchers(ScoredPitcher(player: pitcher(playerName: "A"), score: 2), ScoredPitcher(player: pitcher(playerName: "B"), score: 1)))
        XCTAssertTrue(StatPresentationBuilder.sortScoredNHLPlayers(ScoredNHLPlayer(player: skater(playerName: "A", goals: 1, assists: 0, points: 1, shots: 1), role: "Skater", score: 2), ScoredNHLPlayer(player: skater(playerName: "B", goals: 1, assists: 0, points: 1, shots: 1), role: "Skater", score: 1)))
        XCTAssertTrue(StatPresentationBuilder.sortScoredPlayers(ScoredPlayerStat(player: player(playerName: "A"), score: 1), ScoredPlayerStat(player: player(playerName: "B"), score: 1)))

        let normalizedTeam = TeamStat(team: "Seattle", isHome: true, stats: [:], normalizedStats: [
            NormalizedStat(key: "hits", displayLabel: "Hits", group: nil, value: .number(9)),
            NormalizedStat(key: "empty", displayLabel: "Empty", group: nil, value: .string("-"))
        ])
        let rawTeam = TeamStat(team: "Seattle", isHome: true, stats: ["totalYards": .number(440), "empty": .string("-")], normalizedStats: nil)
        XCTAssertEqual(StatPresentationBuilder.compactTeamItems(normalizedTeam).first?.label, "Hits")
        XCTAssertEqual(StatPresentationBuilder.compactTeamItems(rawTeam).first?.label, "Total Yards")
        XCTAssertEqual(StatPresentationBuilder.teamComparison(for: [normalizedTeam, rawTeam])?.rows.map(\.label), ["Hits", "Total Yards"])
        XCTAssertEqual(StatPresentationBuilder.tableColumn("pts", "PTS", alignment: .leading).alignment, .leading)

        let splitDetail = GameDetail(
            game: TestFixtures.makeGame(leagueCode: "mlb"),
            teamStats: [normalizedTeam, rawTeam],
            playerStats: [],
            events: [],
            mlbBatters: [batter()],
            mlbPitchers: [pitcher()],
            nhlSkaters: nil,
            nhlGoalies: nil
        )
        XCTAssertEqual(StatPresentationBuilder.baseballPlayerSections(for: splitDetail).map(\.title), ["Batters", "Pitchers"])

        let hockeyDetail = GameDetail(
            game: TestFixtures.makeGame(leagueCode: "nhl"),
            teamStats: [normalizedTeam, rawTeam],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: [skater(goals: 1, assists: 0, points: 1, shots: 3)],
            nhlGoalies: [goalie(saves: 28, goalsAgainst: 2)]
        )
        XCTAssertEqual(StatPresentationBuilder.hockeyPlayerSections(for: hockeyDetail).map(\.title), ["Skaters", "Goalies"])
    }

    private func withEnvironment(_ values: [String: String], body: () throws -> Void) rethrows {
        let previous = values.keys.reduce(into: [String: String?]()) { result, key in
            result[key] = ProcessInfo.processInfo.environment[key]
        }
        for (key, value) in values {
            setenv(key, value, 1)
        }
        defer {
            for (key, value) in previous {
                if let value {
                    setenv(key, value, 1)
                } else {
                    unsetenv(key)
                }
            }
        }
        try body()
    }

    private func player(
        playerName: String = "Jordan Vale",
        points: Double? = nil,
        rebounds: Double? = nil,
        assists: Double? = nil,
        yards: Double? = nil,
        touchdowns: Double? = nil,
        rawStats: [String: JSONValue] = [:]
    ) -> PlayerStat {
        PlayerStat(
            team: "SEA",
            playerName: playerName,
            minutes: nil,
            points: points,
            rebounds: rebounds,
            assists: assists,
            yards: yards,
            touchdowns: touchdowns,
            rawStats: rawStats
        )
    }

    private func batter(
        team: String = "SEA",
        playerName: String = "Batter A",
        hits: Int? = 2,
        atBats: Int? = 4,
        runs: Int? = 1,
        rbi: Int? = 3,
        homeRuns: Int? = 1
    ) -> MLBBatterStat {
        MLBBatterStat(
            team: team,
            playerName: playerName,
            position: nil,
            atBats: atBats,
            hits: hits,
            runs: runs,
            rbi: rbi,
            homeRuns: homeRuns,
            baseOnBalls: 0,
            strikeOuts: 1
        )
    }

    private func pitcher(
        team: String = "SEA",
        playerName: String = "Pitcher A",
        earnedRuns: Int? = 2,
        hits: Int? = 4
    ) -> MLBPitcherStat {
        MLBPitcherStat(
            team: team,
            playerName: playerName,
            inningsPitched: "6.1",
            hits: hits,
            runs: 2,
            earnedRuns: earnedRuns,
            baseOnBalls: 1,
            strikeOuts: 7,
            homeRuns: 0
        )
    }

    private func skater(
        team: String = "SEA",
        playerName: String = "Skater A",
        goals: Int?,
        assists: Int?,
        points: Int?,
        shots: Int?
    ) -> NHLPlayerStat {
        NHLPlayerStat(
            team: team,
            playerName: playerName,
            goals: goals,
            assists: assists,
            points: points,
            shotsOnGoal: shots,
            saves: nil,
            goalsAgainst: nil,
            rawStats: nil
        )
    }

    private func goalie(saves: Int?, goalsAgainst: Int?) -> NHLPlayerStat {
        NHLPlayerStat(
            team: "SEA",
            playerName: "Goalie A",
            goals: nil,
            assists: nil,
            points: nil,
            shotsOnGoal: nil,
            saves: saves,
            goalsAgainst: goalsAgainst,
            rawStats: nil
        )
    }

    private func highlight(id: String, title: String) -> StatHighlightPresentation {
        StatHighlightPresentation(
            id: id,
            rank: nil,
            title: title,
            subtitle: "SEA",
            headline: "Impact",
            stats: [StatPillPresentation(label: "PTS", value: "10")],
            accentTone: .scoring
        )
    }
}
