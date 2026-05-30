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

        XCTAssertEqual(stats.playerSections.map(\.id), ["baseball-batter-stats", "baseball-pitcher-stats"])
        XCTAssertEqual(stats.playerSections.map(\.title), ["Batters", "Pitchers"])
        XCTAssertEqual(stats.playerSections.flatMap { $0.tables.map(\.id) }, ["baseball-batters", "baseball-pitchers"])
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

        XCTAssertEqual(stats.playerSections.map(\.id), ["hockey-skater-stats", "hockey-goalie-stats"])
        XCTAssertEqual(stats.playerSections.map(\.title), ["Skaters", "Goalies"])
        XCTAssertEqual(stats.playerSections.flatMap { $0.tables.map(\.id) }, ["hockey-skaters", "hockey-goalies"])
    }

    func testStatFormattingCoversImpactLimitsMissingValuesPercentagesAndSportLabels() {
        let players = (0..<6).map { index in
            PlayerStat(
                team: index.isMultiple(of: 2) ? "Baltimore Orioles" : "Seattle Mariners",
                playerName: "Impact Player \(index)",
                minutes: index == 0 ? nil : Double(30 - index),
                points: Double(30 - index),
                rebounds: Double(index),
                assists: nil,
                yards: nil,
                touchdowns: nil,
                rawStats: [:]
            )
        }
        let detail = GameDetail(
            game: TestFixtures.makeGame(id: 1504, leagueCode: "nba"),
            teamStats: [],
            playerStats: players,
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let section = StatPresentationBuilder.genericPlayerSections(for: detail)[0]

        XCTAssertEqual(section.highlights.count, 4)
        XCTAssertTrue((3...5).contains(section.highlights.count))
        XCTAssertEqual(StatPresentationBuilder.statString(nil as Int?), "-")
        XCTAssertNil(StatPresentationBuilder.statString(nil as Double?))
        XCTAssertEqual(StatPresentationBuilder.statString(12.0), "12")
        XCTAssertEqual(StatPresentationBuilder.statString(12.5), "12.5")
        XCTAssertEqual(StatPresentationBuilder.outs(from: "5.2"), 17)
        XCTAssertEqual(StatPresentationBuilder.outs(from: "5.3"), 15)
        XCTAssertEqual(StatPresentationBuilder.savePercentage(for: goalie(saves: 31, goalsAgainst: 2)), ".939")
        XCTAssertEqual(section.tables[0].columns.map(\.label), ["Player", "Team", "MIN", "PTS", "REB"])

        let baseball = StatPresentationBuilder.baseballBatterTable(
            from: [ScoredBatter(player: batter(team: "Baltimore Orioles", atBats: nil), score: 1)],
            teamAbbreviations: [:]
        )
        XCTAssertEqual(baseball.columns.map(\.label), ["Player", "Team", "Pos", "AB", "H", "R", "RBI", "HR", "BB", "K"])
        XCTAssertEqual(baseball.rows[0].values["pos"], "-")
        XCTAssertEqual(baseball.rows[0].values["ab"], "-")

        let hockey = StatPresentationBuilder.hockeyGoalieTable(
            from: [
                ScoredNHLPlayer(player: goalie(team: "Seattle Mariners", saves: 31, goalsAgainst: 2), role: "Goalie", score: 1),
                ScoredNHLPlayer(player: goalie(team: "Baltimore Orioles", saves: nil, goalsAgainst: nil), role: "Goalie", score: 0)
            ],
            teamAbbreviations: [:]
        )
        XCTAssertEqual(hockey.columns.map(\.label), ["Player", "Team", "SV", "GA", "SV%"])
        XCTAssertEqual(hockey.rows[1].values["svp"], "-")
    }

    func testStatTablesAndScoreboardsPreferAbbreviationsWithoutTruncatingNames() {
        let game = TestFixtures.makeGame(
            id: 1505,
            leagueCode: "mlb",
            awayName: "Baltimore Orioles",
            awayAbbreviation: "BAL",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA",
            scoreboard: scoreboardWithDuplicateRunSegment()
        )
        let detail = GameDetail(
            game: game,
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: [batter(team: "Baltimore Orioles")],
            mlbPitchers: [pitcher(team: "Seattle Mariners")],
            nhlSkaters: nil,
            nhlGoalies: nil
        )
        let stats = BaseballRenderer().statsPresentation(for: detail)
        let scoreboard = BaseballRenderer().scoreboardPresentation(for: game)

        XCTAssertEqual(stats.playerSections[0].tables[0].rows[0].values["team"], "BAL")
        XCTAssertEqual(stats.playerSections[1].tables[0].rows[0].values["team"], "SEA")
        XCTAssertEqual(scoreboard.rows[0].title, "Baltimore Orioles")
        XCTAssertEqual(scoreboard.rows[0].abbreviation, "BAL")
        XCTAssertFalse(scoreboard.rows.map(\.title).joined(separator: " ").contains("Baltimo..."))
    }

    func testScoreboardPresentationDropsDuplicateTotalSegments() {
        let game = TestFixtures.makeGame(id: 1506, leagueCode: "mlb", scoreboard: scoreboardWithDuplicateRunSegment())

        let presentation = BaseballRenderer().scoreboardPresentation(for: game)

        XCTAssertEqual(presentation.layout, .segmentTable)
        XCTAssertEqual(presentation.totalHeader, "R")
        XCTAssertEqual(presentation.rows.map(\.totalText), ["7", "6"])
        XCTAssertEqual(presentation.segments.map(\.label), ["1", "H"])
    }

    func testEventImportanceMapsToDifferentiatedSemanticVisuals() {
        let low = TestFixtures.makeEvent(sequence: 1, importanceMetadata: importance(level: "tertiary"))
        let medium = TestFixtures.makeEvent(sequence: 2, importanceMetadata: importance(level: "secondary"))
        let high = TestFixtures.makeEvent(sequence: 3, importanceMetadata: importance(rank: 50))
        let critical = TestFixtures.makeEvent(sequence: 4, importanceMetadata: importance(isLeadChange: true))
        let visuals = [low.visualImportance, medium.visualImportance, high.visualImportance, critical.visualImportance]

        XCTAssertEqual(visuals, [.low, .medium, .high, .critical])
        XCTAssertEqual(Set(visuals).count, 4)
        XCTAssertEqual(visuals.map(\.title), ["", "Notable", "Key play", "Big moment"])
        XCTAssertFalse(visuals.map(\.title).joined(separator: " ").localizedCaseInsensitiveContains("tertiary"))
    }

    func testDefaultSituationHookIsNilWithVisibleStreamContext() {
        let game = TestFixtures.makeGame(id: 1508, leagueCode: "nba")
        let event = TestFixtures.makeEvent(sequence: 1, importance: .contextual)
        let renderer = GenericSportRenderer(leagueCode: "nba")
        let context = SportRendererSituationContext(
            game: game,
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )

        XCTAssertNil(renderer.eventSituationPresentation(for: event))
        XCTAssertNil(renderer.eventSituationPresentation(for: event, context: context))
        XCTAssertNil(renderer.eventPresentation(for: event, periodGroupLabel: "Q1", context: context).situation)
    }

    func testGenericSituationGateUsesPressureBoardForEventLocalContext() {
        let event = GameEvent(
            id: "event-pressure-board",
            sourceEventID: "event-pressure-board",
            sequence: 2,
            periodOrdinal: 4,
            periodLabel: "Q4",
            clockLabel: "00:42",
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: "Three pointer",
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "Q4 00:42"),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 85,
                bucket: "scoring",
                reasons: [],
                isKeyMoment: true,
                isScoringPlay: true,
                isLeadChange: false,
                isTyingPlay: true,
                winProbabilityDelta: nil
            ),
            headline: "Seattle ties it from the corner.",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 76),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 79)
                ]
            ),
            scoreAfter: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 79),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 79)
                ]
            ),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 76, after: 79, change: 3),
            sportMetadata: [:]
        )

        let context = SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 1510, leagueCode: "nba"),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )
        let presentation = BasketballRenderer(leagueCode: "nba").eventPresentation(
            for: event,
            periodGroupLabel: "Q4",
            context: context
        )
        let situation = presentation.situation

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.sport, .basketball)
        XCTAssertEqual(situation?.dataConfidence, .explicitGenericEventContext)
        XCTAssertEqual(situation?.ownership?.role, .association)
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        XCTAssertTrue(PlayRowContentFilter.situationMetricSuppressionText(for: presentation).contains("Three pointer"))
    }

    func testFootballMetadataDoesNotClaimFieldSituationWithoutStructuredSupport() {
        let event = TestFixtures.makeEvent(
            sequence: 3,
            importance: .primary,
            periodLabel: "Q2",
            clockLabel: "08:14",
            eventType: "Pass",
            sportMetadata: [
                "down": .number(3),
                "distance": .number(7),
                "yardLine": .string("SEA 42")
            ]
        )

        let situation = FootballRenderer(leagueCode: "nfl").eventPresentation(
            for: event,
            periodGroupLabel: "Q2"
        ).situation

        XCTAssertNil(situation)
    }

    func testBaseballSituationHookCanUseVisibleStreamContext() {
        let game = TestFixtures.makeGame(id: 1509, leagueCode: "mlb")
        let event = TestFixtures.makeEvent(
            sequence: 1,
            importance: .primary,
            periodLabel: "T8",
            clockLabel: "1 out",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1),
                "ballsBefore": .number(2),
                "strikesBefore": .number(1)
            ]
        )
        let context = SportRendererSituationContext(
            game: game,
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )

        let situation = BaseballRenderer().eventSituationPresentation(for: event, context: context)
        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "Top 8th", context: context)

        XCTAssertEqual(situation?.setupText, "Runner on 2nd · 1 out · 2-1 count")
        XCTAssertEqual(presentation.situation, situation)
        XCTAssertEqual(presentation.clockText, "1 out")
        XCTAssertTrue(PlayRowContentFilter.situationMetricSuppressionText(for: presentation).contains("Runner on 2nd · 1 out · 2-1 count"))
    }

    func testPresentationBuildersExposeSemanticRolesAndEmptyStates() {
        let game = TestFixtures.makeGame(id: 1507, leagueCode: "nhl", scoreboard: scoreboardWithDuplicateRunSegment())
        let emptyDetail = GameDetail(
            game: game,
            teamStats: [],
            playerStats: [],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
        let stats = GenericSportRenderer(leagueCode: "nhl").statsPresentation(for: emptyDetail)
        let scoreboard = GenericSportRenderer(leagueCode: "nhl").scoreboardPresentation(for: game)

        XCTAssertEqual(stats.playerSections[0].id, "player-stats-empty")
        XCTAssertEqual(stats.playerSections[0].emptyMessage, "No player stats available yet.")
        XCTAssertEqual(stats.teamSection.id, "team-stats-empty")
        XCTAssertEqual(stats.teamSection.emptyMessage, "No team stats available yet.")
        XCTAssertEqual(scoreboard.title, "Box Score")
        XCTAssertEqual(scoreboard.revealTitle, "Score hidden")
        XCTAssertEqual(scoreboard.rows.map(\.id), ["away", "home"])
        XCTAssertEqual(scoreboard.rows.map(\.abbreviation), ["BAL", "SEA"])
        XCTAssertEqual(scoreboard.stateText, "Baltimore 7, Seattle 6")
    }

    private func batter(team: String, atBats: Int? = 4) -> MLBBatterStat {
        MLBBatterStat(
            team: team,
            playerName: "Mara Vale",
            position: nil,
            atBats: atBats,
            hits: 2,
            runs: 1,
            rbi: 3,
            homeRuns: 1,
            baseOnBalls: 0,
            strikeOuts: 1
        )
    }

    private func pitcher(team: String) -> MLBPitcherStat {
        MLBPitcherStat(
            team: team,
            playerName: "Noel King",
            inningsPitched: "6.1",
            hits: 4,
            runs: 2,
            earnedRuns: 2,
            baseOnBalls: 1,
            strikeOuts: 7,
            homeRuns: 0
        )
    }

    private func goalie(team: String = "Seattle Mariners", saves: Int?, goalsAgainst: Int?) -> NHLPlayerStat {
        NHLPlayerStat(
            team: team,
            playerName: "Sam North",
            goals: nil,
            assists: nil,
            points: nil,
            shotsOnGoal: nil,
            saves: saves,
            goalsAgainst: goalsAgainst,
            rawStats: nil
        )
    }

    private func importance(
        level: String? = nil,
        rank: Int? = nil,
        isLeadChange: Bool? = nil
    ) -> EventImportanceData {
        EventImportanceData(
            level: level,
            rank: rank,
            bucket: nil,
            reasons: [],
            isKeyMoment: nil,
            isScoringPlay: nil,
            isLeadChange: isLeadChange,
            isTyingPlay: nil,
            winProbabilityDelta: nil
        )
    }

    private func scoreboardWithDuplicateRunSegment() -> GameScoreboardData {
        GameScoreboardData(
            layout: "inning_table",
            clockLabel: nil,
            periodLabel: nil,
            statusLabel: "Final",
            scoreline: "Baltimore 7, Seattle 6",
            competitors: [
                ScoreboardCompetitorData(
                    id: "away",
                    side: .away,
                    teamName: "Baltimore Orioles",
                    teamAbbreviation: "BAL",
                    score: 7,
                    scoreText: "7",
                    isWinner: true,
                    recordText: nil
                ),
                ScoreboardCompetitorData(
                    id: "home",
                    side: .home,
                    teamName: "Seattle Mariners",
                    teamAbbreviation: "SEA",
                    score: 6,
                    scoreText: "6",
                    isWinner: false,
                    recordText: nil
                )
            ],
            segments: [
                ScoreboardSegmentData(label: "1", away: "1", home: "0"),
                ScoreboardSegmentData(label: "R", away: "7", home: "6"),
                ScoreboardSegmentData(label: "H", away: "9", home: "8")
            ],
            totals: ScoreboardTotalsData(away: "7", home: "6")
        )
    }
}
