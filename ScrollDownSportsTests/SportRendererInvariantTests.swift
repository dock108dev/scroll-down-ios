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

        XCTAssertEqual(stats.playerSections.map(\.id), ["player-impact", "player-stats-by-team"])
        XCTAssertEqual(stats.playerSections[1].tables.map(\.id), ["generic-full-stats-away"])
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

        XCTAssertEqual(stats.playerSections.map(\.id), ["baseball-impact", "baseball-batter-stats", "baseball-pitcher-stats"])
        XCTAssertEqual(stats.playerSections.map(\.title), [nil, "Batters", "Pitchers"])
        XCTAssertEqual(stats.playerSections.flatMap { $0.tables.map(\.id) }, ["baseball-batters-sea", "baseball-pitchers-sea"])
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

        XCTAssertEqual(stats.playerSections.map(\.id), ["hockey-impact", "hockey-skater-stats", "hockey-goalie-stats"])
        XCTAssertEqual(stats.playerSections.map(\.title), [nil, "Skaters", "Goalies"])
        XCTAssertEqual(stats.playerSections.flatMap { $0.tables.map(\.id) }, ["hockey-skaters-ev", "hockey-goalies-nh"])
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

        let sections = StatPresentationBuilder.genericPlayerSections(for: detail)
        let section = sections[0]
        let tableSection = sections[1]

        XCTAssertEqual(section.highlights.count, 3)
        XCTAssertTrue((1...3).contains(section.highlights.count))
        XCTAssertEqual(StatPresentationBuilder.statString(nil as Int?), "-")
        XCTAssertNil(StatPresentationBuilder.statString(nil as Double?))
        XCTAssertEqual(StatPresentationBuilder.statString(12.0), "12")
        XCTAssertEqual(StatPresentationBuilder.statString(12.5), "12.5")
        XCTAssertEqual(StatPresentationBuilder.outs(from: "5.2"), 17)
        XCTAssertEqual(StatPresentationBuilder.outs(from: "5.3"), 15)
        XCTAssertEqual(StatPresentationBuilder.savePercentage(for: goalie(saves: 31, goalsAgainst: 2)), ".939")
        XCTAssertEqual(tableSection.tables[0].columns.map(\.label), ["Player", "Team", "MIN", "PTS", "REB"])

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

        XCTAssertEqual(stats.playerSections[1].tables[0].rows[0].values["team"], "BAL")
        XCTAssertEqual(stats.playerSections[2].tables[0].rows[0].values["team"], "SEA")
        XCTAssertEqual(scoreboard.rows[0].title, "Baltimore Orioles")
        XCTAssertEqual(scoreboard.rows[0].abbreviation, "BAL")
        XCTAssertFalse(scoreboard.rows.map(\.title).joined(separator: " ").contains("Baltimo..."))
    }

    func testGenericStatsPreferBackendTeamAbbreviationsOverMascotFallbacks() {
        let game = TestFixtures.makeGame(
            id: 1515,
            leagueCode: "nhl",
            awayName: "Vegas Golden Knights",
            awayAbbreviation: "VGK",
            homeName: "Carolina Hurricanes",
            homeAbbreviation: "CAR"
        )
        let detail = GameDetail(
            game: game,
            teamStats: [
                TeamStat(team: "Vegas Golden Knights", teamAbbreviation: "VGK", isHome: false, stats: ["points": .number(5)], normalizedStats: nil),
                TeamStat(team: "Carolina Hurricanes", teamAbbreviation: "CAR", isHome: true, stats: ["points": .number(4)], normalizedStats: nil)
            ],
            playerStats: [
                PlayerStat(
                    team: "Vegas Golden Knights",
                    teamAbbreviation: "VGK",
                    playerName: "S. Theodore",
                    minutes: nil,
                    points: 3,
                    rebounds: nil,
                    assists: 2,
                    yards: nil,
                    touchdowns: nil,
                    rawStats: ["goals": .number(1), "assists": .number(2), "points": .number(3)]
                ),
                PlayerStat(
                    team: "Carolina Hurricanes",
                    teamAbbreviation: "CAR",
                    playerName: "N. Ehlers",
                    minutes: nil,
                    points: 2,
                    rebounds: nil,
                    assists: 0,
                    yards: nil,
                    touchdowns: nil,
                    rawStats: ["goals": .number(2), "assists": .number(0), "points": .number(2)]
                )
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )

        let stats = StatPresentationBuilder.genericPlayerSections(for: detail, sport: .nhl)
        let teamComparison = StatPresentationBuilder.teamComparison(for: detail)

        XCTAssertEqual(stats[1].tables.map(\.title), ["VGK Skaters", "CAR Skaters"])
        XCTAssertEqual(stats[1].tables.flatMap { $0.rows.compactMap { $0.values["team"] } }, ["VGK", "CAR"])
        XCTAssertEqual(teamComparison?.columns.map(\.title), ["VGK", "CAR"])
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
        XCTAssertEqual(scoreboard.rows.map(\.id), ["away", "home"])
        XCTAssertEqual(scoreboard.rows.map(\.abbreviation), ["BAL", "SEA"])
        XCTAssertEqual(scoreboard.stateText, "Baltimore 7, Seattle 6")
    }

    func testNormalizedCardSituationMapsContractFieldsIntoPresentation() {
        let game = TestFixtures.makeGame(id: 1511, leagueCode: "nba")
        let card = NormalizedPlayCard(
            schemaVersion: 1,
            cardID: "card-situation",
            visualImportance: .high,
            accent: NormalizedPlayCardAccent(
                tone: .critical,
                participantRole: .home,
                teamAbbreviation: "SEA"
            ),
            clock: nil,
            leadIn: NormalizedPlayCardText(text: "Late pressure", tone: .context, maxLines: nil),
            headline: NormalizedPlayCardText(text: "Seattle forces overtime", tone: .scoring, maxLines: nil),
            body: NormalizedPlayCardText(text: "The home side gets the stop it needed.", tone: .neutral, maxLines: nil),
            contextItems: [
                NormalizedPlayCardContextItem(
                    id: "clock",
                    kind: .clock,
                    text: "Q4 00:05",
                    tone: .muted,
                    participantRole: nil,
                    teamAbbreviation: nil
                ),
                NormalizedPlayCardContextItem(
                    id: "team",
                    kind: .teamBadge,
                    text: "SEA",
                    tone: .possession,
                    participantRole: .home,
                    teamAbbreviation: "SEA"
                )
            ],
            resultItems: [
                NormalizedPlayCardResultItem(id: "result", text: "Tie game", tone: .secondary, priority: 1)
            ],
            score: NormalizedPlayCardScore(label: "Scoring", value: "SEA 99, NYY 99", isScoringPlay: true),
            team: NormalizedPlayCardTeam(
                participantRole: .home,
                abbreviation: "SEA",
                displayName: "Seattle Mariners",
                label: "Seattle"
            ),
            situation: NormalizedPlayCardSituation(
                title: "Final possession",
                periodText: "Q4",
                setupText: "Five seconds left",
                contextLine: "Seattle has the ball",
                pressureLine: "High leverage",
                sport: "basketball",
                layout: "basketball",
                ownership: NormalizedPlayCardSituationOwnership(
                    role: "possession",
                    participantRole: .home,
                    teamAbbreviation: "SEA",
                    teamLabel: "Seattle",
                    confidence: "derivedFromPeriod"
                ),
                accent: NormalizedPlayCardAccent(
                    tone: .scoring,
                    participantRole: .home,
                    teamAbbreviation: "SEA"
                ),
                dataConfidence: "feedProvided"
            ),
            rawFeed: NormalizedPlayCardRawFeed(
                text: "SEA defensive rebound",
                source: "provider",
                updatedAt: "2026-05-22T23:59:00Z",
                disclosureTitle: "Raw feed"
            ),
            accessibility: NormalizedPlayCardAccessibility(
                label: "Seattle forces overtime",
                value: "Tie game",
                hint: "Double tap for feed details",
                situationSummary: "Seattle possession with five seconds left"
            )
        )

        let presentation = GameEventPresentation(card: card, game: game)

        XCTAssertEqual(presentation.clockText, "Q4 00:05")
        XCTAssertEqual(presentation.scoringLabel, "Scoring")
        XCTAssertEqual(presentation.scoreLabel, "SEA 99, NYY 99")
        XCTAssertEqual(presentation.teamAbbreviation, "SEA")
        XCTAssertEqual(presentation.contextItems.map(\.tone), [.muted, .possession])
        XCTAssertEqual(presentation.resultItems.map(\.text), ["Tie game"])
        XCTAssertEqual(presentation.rawFeedDisclosureTitle, "Raw feed")
        XCTAssertEqual(presentation.situation?.sport, .basketball)
        XCTAssertEqual(presentation.situation?.layout, .basketball)
        XCTAssertEqual(presentation.situation?.ownership?.role, .possession)
        XCTAssertEqual(presentation.situation?.ownership?.confidence, .derivedFromPeriod)
        XCTAssertEqual(presentation.situation?.accent.tone, .scoring)
        XCTAssertEqual(presentation.situation?.dataConfidence, .feedProvided)
        XCTAssertEqual(presentation.situationAccessibilityText, "Seattle possession with five seconds left")
    }

    func testSportRendererDefaultExtensionGroupsAndDelegatesSituations() {
        struct MinimalRenderer: SportRenderer {
            var theme: SportRenderingTheme {
                GenericSportRenderer(leagueCode: "nba").theme
            }

            func gameCardPresentation(for game: Game) -> GameCardPresentation {
                GenericSportRenderer(leagueCode: game.leagueCode).gameCardPresentation(for: game)
            }

            func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation {
                GenericSportRenderer(leagueCode: game.leagueCode).gameHeaderPresentation(for: game)
            }

            func eventPresentation(for event: GameEvent) -> GameEventPresentation {
                GameEventPresentation(event: event)
            }

            func periodGroupLabel(for event: GameEvent) -> String {
                event.periodLabel ?? "Unknown"
            }

            func periodGroupKey(for event: GameEvent) -> String {
                periodGroupLabel(for: event)
            }

            func rowClockText(for event: GameEvent, periodGroupLabel: String?) -> String {
                [periodGroupLabel, event.clockText].compactMap(\.self).joined(separator: " ")
            }

            func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
                GenericSportRenderer(leagueCode: game.leagueCode).scoreboardPresentation(for: game)
            }

            func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
                GenericSportRenderer(leagueCode: detail.game.leagueCode).statsPresentation(for: detail)
            }
        }

        let events = [
            TestFixtures.makeEvent(sequence: 20, sourceEventID: "b", periodLabel: "Q2", clockLabel: "09:00"),
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "a", periodLabel: "Q1", clockLabel: "10:00"),
            TestFixtures.makeEvent(sequence: 30, sourceEventID: "c", periodLabel: "Q2", clockLabel: "08:30")
        ]
        let renderer = MinimalRenderer()
        let context = SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 1512, leagueCode: "nba"),
            selectedMode: .full,
            visibleEvents: events,
            eventIndex: 0
        )

        let groups = renderer.periodGroups(for: events)
        let presentation = renderer.eventPresentation(
            for: events[0],
            periodGroupLabel: "Q2",
            context: context
        )

        XCTAssertEqual(groups.map(\.id), ["Q1", "Q2"])
        XCTAssertEqual(groups[1].events.map(\.id), ["b", "c"])
        XCTAssertEqual(presentation.clockText, "Q2 Q2 · 09:00")
        XCTAssertNil(renderer.eventSituationPresentation(for: events[0]))
        XCTAssertNil(renderer.eventSituationPresentation(for: events[0], context: context))
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
