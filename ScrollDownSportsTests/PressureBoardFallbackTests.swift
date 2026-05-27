import XCTest
@testable import ScrollDownSports

@MainActor
final class PressureBoardFallbackTests: XCTestCase {
    func testExplicitBaseballPreEventEvidenceUsesSportDiagram() {
        let event = pressureBoardEvent(
            sequence: 29,
            periodLabel: "T8",
            clockLabel: "1 out",
            eventType: "Double",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "baseState": .string("bases_loaded"),
                "outsBefore": .number(1)
            ]
        )
        let game = TestFixtures.makeGame(id: 1900, leagueCode: "mlb")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "T8", context: context).situation

        XCTAssertEqual(situation?.layout, .baseball)
        XCTAssertEqual(situation?.dataConfidence, .explicitPreEvent)
        if case .baseballDiamond(let diamond) = situation?.diagram {
            XCTAssertEqual(diamond.occupiedBases, [.second])
        } else {
            XCTFail("Expected explicit pre-event metadata to render a baseball diagram")
        }
    }

    func testPressureBoardUsesEventLocalScoreAndNotGameScore() {
        let event = pressureBoardEvent(
            sequence: 30,
            periodLabel: "Q4",
            clockLabel: "00:42",
            eventType: "Three pointer",
            scoreBefore: scoreState(home: 76, away: 79),
            scoreAfter: scoreState(home: 79, away: 79),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 76, after: 79, change: 3)
        )
        let game = TestFixtures.makeGame(id: 1901, leagueCode: "nba", awayScore: 99, homeScore: 98)
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = BasketballRenderer(leagueCode: "nba").eventPresentation(
            for: event,
            periodGroupLabel: "Q4",
            context: context
        ).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Time", "Team", "Play", "Score"])
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Score" })?.value, "Down 3 -> Tied")
        XCTAssertFalse(board.metrics.map(\.value).joined(separator: " ").contains("99"))
        XCTAssertEqual(situation?.contextLine, "Down 3 -> Tied")
    }

    func testAmbiguousBaseballMetadataUsesFallbackWithoutBaseClaims() {
        let event = pressureBoardEvent(
            sequence: 33,
            periodLabel: "T8",
            clockLabel: "1 out",
            eventType: "Double",
            importanceMetadata: EventImportanceData(
                level: "secondary",
                rank: 55,
                bucket: "base_runner",
                reasons: ["runner aboard", "bases loaded"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            sportMetadata: ["baseState": .string("runner_on_second")]
        )
        let game = TestFixtures.makeGame(id: 1904, leagueCode: "mlb")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "T8", context: context).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let boardText = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        XCTAssertEqual(board.metrics.map(\.label), ["Inning", "Team", "Play", "Pressure"])
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Inning" })?.value, "Top 8th")
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Pressure" })?.value, "Key play")
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("base"))
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("runner"))
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
    }

    func testImportantBaseballPlayWithMissingBaseDataCanUseFallback() {
        let event = pressureBoardEvent(
            sequence: 34,
            periodLabel: "B9",
            clockLabel: "2 outs",
            eventType: "Single",
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 92,
                bucket: "base_runner",
                reasons: ["bases loaded"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            )
        )
        let game = TestFixtures.makeGame(id: 1905, leagueCode: "mlb")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "B9", context: context).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let boardText = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertEqual(situation?.dataConfidence, .explicitGenericEventContext)
        XCTAssertEqual(board.metrics.map(\.label), ["Inning", "Team", "Play", "Pressure"])
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Inning" })?.value, "Bottom 9th")
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Pressure" })?.value, "Key play")
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("base"))
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("runner"))
    }

    func testBaseballFallbackUsesInningAndPrePlayScoreInBoard() {
        let event = pressureBoardEvent(
            sequence: 35,
            periodLabel: "B3",
            clockLabel: "",
            eventType: "Double",
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 94,
                bucket: "scoring_play",
                reasons: ["scoring play"],
                isKeyMoment: true,
                isScoringPlay: true,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            scoreBefore: scoreState(home: 3, away: 3),
            scoreAfter: scoreState(home: 4, away: 3),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 3, after: 4, change: 1)
        )
        let game = TestFixtures.makeGame(id: 1906, leagueCode: "mlb")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "Bottom 3rd", context: context).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Inning", "Team", "Play", "Score"])
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Inning" })?.value, "Bottom 3rd")
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Score" })?.value, "Tied")
        XCTAssertEqual(situation?.contextLine, "Tied -> Up 1")
        XCTAssertNil(situation?.pressureLine)
    }

    func testDerivedOnlyEvidenceSuppressesSituationBlock() {
        let decision = SituationConfidenceGate.decision(
            for: SituationConfidenceEvidence(
                hasExplicitPreEventState: false,
                hasExplicitGenericContext: false,
                hasDerivedState: true,
                hasAmbiguousMetadata: false,
                hasEventLocalContext: true
            )
        )

        XCTAssertEqual(decision, .none(.derivedState))
    }

    func testPressureBoardFallsBackToTimeTeamAndEventMeaningWithoutScore() {
        let event = pressureBoardEvent(sequence: 31, periodLabel: "P3", clockLabel: "02:11", eventType: "Save")
        let game = TestFixtures.makeGame(id: 1902, leagueCode: "nhl")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = HockeyRenderer().eventPresentation(for: event, periodGroupLabel: "3rd", context: context).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Time", "Team", "Play", "Pressure"])
        XCTAssertEqual(board.metrics.map(\.value), ["P3 02:11", "SEA", "Save", "Key play"])
        XCTAssertNil(situation?.contextLine)
        XCTAssertEqual(situation?.pressureLine, "Key play")
    }

    func testFootballMetadataUsesPressureBoardWithoutFieldClaims() {
        let event = pressureBoardEvent(
            sequence: 32,
            periodLabel: "Q2",
            clockLabel: "08:14",
            eventType: "Pass",
            sportMetadata: ["down": .number(3), "distance": .number(7), "yardLine": .string("SEA 42")]
        )
        let game = TestFixtures.makeGame(id: 1903, leagueCode: "nfl")
        let context = SportRendererSituationContext(game: game, selectedMode: .key, visibleEvents: [event], eventIndex: 0)

        let situation = FootballRenderer(leagueCode: "nfl").eventPresentation(
            for: event,
            periodGroupLabel: "Q2",
            context: context
        ).situation

        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let boardText = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("field"))
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("yard"))
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
    }

    func testReservedSportMetadataUsesPressureBoardWithoutRichDiagramClaims() {
        let cases: [ReservedPressureBoardCase] = [
            ReservedPressureBoardCase(
                name: "football",
                leagueCode: "nfl",
                expectedSport: .football,
                expectedTitle: "Context",
                eventType: "Completion",
                sportMetadata: [
                    "down": .number(3),
                    "distance": .number(7),
                    "yardLine": .string("SEA 42"),
                    "formation": .string("shotgun")
                ],
                forbiddenText: ["field", "yard", "first down", "formation", "possession"],
                render: { FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "hockey",
                leagueCode: "nhl",
                expectedSport: .hockey,
                expectedTitle: "Context",
                periodLabel: "P3",
                clockLabel: "02:11",
                eventType: "Save",
                sportMetadata: [
                    "strength": .string("power_play"),
                    "zone": .string("offensive"),
                    "puckLocation": .string("slot")
                ],
                forbiddenText: ["rink", "zone", "puck", "slot"],
                render: { HockeyRenderer().eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "basketball",
                leagueCode: "nba",
                expectedSport: .basketball,
                expectedTitle: "Context",
                eventType: "Basket",
                sportMetadata: [
                    "possession": .string("home"),
                    "shotClock": .number(12),
                    "bonus": .bool(true),
                    "shotLocation": .string("left corner")
                ],
                forbiddenText: ["possession", "shot clock", "bonus", "corner", "location"],
                render: { BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "soccer",
                leagueCode: "mls",
                expectedSport: .soccer,
                expectedTitle: "Context",
                periodLabel: "Second Half",
                clockLabel: "75'",
                eventType: "Chance",
                sportMetadata: [
                    "setPiece": .string("corner"),
                    "attackingThird": .bool(true),
                    "ballLocation": .string("left channel"),
                    "possession": .string("home")
                ],
                forbiddenText: ["set piece", "attacking third", "ball location", "left channel", "possession"],
                render: { SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "golf",
                leagueCode: "pga",
                expectedSport: .golf,
                expectedTitle: "Leaderboard pressure",
                eventType: "Approach",
                sportMetadata: [
                    "lie": .string("fairway"),
                    "coursePosition": .string("front bunker")
                ],
                forbiddenText: ["course", "hole", "fairway", "bunker", "green"],
                render: { GolfRenderer(leagueCode: "pga").eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "tennis",
                leagueCode: "tennis",
                expectedSport: .tennis,
                expectedTitle: "Score pressure",
                eventType: "Rally",
                sportMetadata: [
                    "courtLocation": .string("ad court")
                ],
                forbiddenText: ["break point", "court", "ad court"],
                render: { TennisRenderer(leagueCode: "tennis").eventSituationPresentation(for: $0, context: $1) }
            ),
            ReservedPressureBoardCase(
                name: "other",
                leagueCode: "pickleball",
                expectedSport: .generic,
                expectedTitle: "Context",
                eventType: "Rally",
                sportMetadata: [
                    "courtLocation": .string("kitchen"),
                    "possession": .string("home")
                ],
                forbiddenText: ["court", "kitchen", "possession"],
                render: { GenericSportRenderer(leagueCode: "pickleball").eventSituationPresentation(for: $0, context: $1) }
            )
        ]

        for (offset, testCase) in cases.enumerated() {
            let event = pressureBoardEvent(
                sequence: 40 + offset,
                periodLabel: testCase.periodLabel,
                clockLabel: testCase.clockLabel,
                eventType: testCase.eventType,
                sportMetadata: testCase.sportMetadata
            )
            let context = SportRendererSituationContext(
                game: TestFixtures.makeGame(id: 2000 + offset, leagueCode: testCase.leagueCode),
                selectedMode: .key,
                visibleEvents: [event],
                eventIndex: 0
            )

            let situation = testCase.render(event, context)

            XCTAssertEqual(situation?.title, testCase.expectedTitle, testCase.name)
            XCTAssertEqual(situation?.sport, testCase.expectedSport, testCase.name)
            XCTAssertEqual(situation?.layout, .pressureBoardFallback, testCase.name)
            XCTAssertFalse(situation?.ownership?.claimsPossession == true, testCase.name)

            guard case .pressureBoardFallback(let board) = situation?.diagram else {
                XCTFail("Expected \(testCase.name) to stay on a pressure board")
                continue
            }

            let boardText = pressureBoardText(situation: situation, board: board)
            XCTAssertEqual(board.metrics.map(\.label), ["Time", "Team", "Play", "Pressure"], testCase.name)
            for forbidden in testCase.forbiddenText {
                XCTAssertFalse(
                    boardText.localizedCaseInsensitiveContains(forbidden),
                    "\(testCase.name) should not render unsupported rich state: \(forbidden)"
                )
            }
        }
    }

    private func pressureBoardEvent(
        sequence: Int,
        periodLabel: String,
        clockLabel: String,
        eventType: String,
        importanceMetadata: EventImportanceData? = nil,
        scoreBefore: ScoreState? = nil,
        scoreAfter: ScoreState = scoreState(home: nil, away: nil),
        scoreDelta: ScoreDelta? = nil,
        sportMetadata: [String: JSONValue] = [:]
    ) -> GameEvent {
        GameEvent(
            id: "pressure-board-\(sequence)",
            sourceEventID: "pressure-board-\(sequence)",
            sequence: sequence,
            periodOrdinal: nil,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "\(periodLabel) \(clockLabel)"),
            importanceMetadata: importanceMetadata,
            headline: "Pressure board event \(sequence)",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            scoreDelta: scoreDelta,
            sportMetadata: sportMetadata
        )
    }

    private func pressureBoardText(
        situation: GameEventSituationPresentation?,
        board: PressureBoardSituationDiagram
    ) -> String {
        let fragments = [
            situation?.title,
            situation?.periodText,
            situation?.setupText,
            situation?.contextLine,
            situation?.pressureLine,
            situation?.ownership?.displayLabel
        ]
            .compactMap { $0?.nilIfBlank }
            + board.metrics.flatMap { [$0.label, $0.value] }
            + board.associations.map(\.displayLabel)
        return fragments.joined(separator: " ")
    }
}

private struct ReservedPressureBoardCase {
    let name: String
    let leagueCode: String
    let expectedSport: GameEventSituationSport
    let expectedTitle: String
    var periodLabel = "Q4"
    var clockLabel = "00:42"
    let eventType: String
    let sportMetadata: [String: JSONValue]
    let forbiddenText: [String]
    let render: (GameEvent, SportRendererSituationContext) -> GameEventSituationPresentation?
}

private func scoreState(home: Int?, away: Int?) -> ScoreState {
    ScoreState(participantScores: [
        ParticipantScore(participantID: "home", participantRole: .home, score: home),
        ParticipantScore(participantID: "away", participantRole: .away, score: away)
    ])
}
