import XCTest
@testable import ScrollDownSports

@MainActor
final class BasketballPossessionPressureTests: XCTestCase {
    func testLateDownTwoPossessionUsesExplicitHalfCourtCard() {
        let event = basketballEvent(
            sequence: 1,
            scoreBefore: scoreState(home: 98, away: 100),
            sportMetadata: explicitSituation(
                possession: ["teamAbbreviation": .string("SEA"), "participantRole": .string("home")],
                shotClock: ["seconds": .number(18), "status": .string("running"), "confidence": .string("explicit")]
            )
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .basketball)
        XCTAssertEqual(situation?.sport, .basketball)
        XCTAssertEqual(situation?.periodText, "Q4 00:42")
        XCTAssertEqual(situation?.contextLine, "Down 2")
        XCTAssertEqual(situation?.ownership?.role, .possession)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(situation?.dataConfidence, .explicitPreEvent)
        guard case .basketballHalfCourt(let diagram) = situation?.diagram else {
            return XCTFail("Expected basketball half-court pressure module")
        }
        XCTAssertEqual(diagram.possessionText, "SEA ball")
        XCTAssertEqual(diagram.clockText, "Q4 00:42")
        XCTAssertEqual(diagram.scoreText, "Down 2")
        XCTAssertEqual(diagram.shotClockText, "18")
    }

    func testShotClockPressureUsesExplicitShotClockOnly() {
        let event = basketballEvent(
            sequence: 2,
            periodLabel: "Q2",
            clockLabel: "08:14",
            sportMetadata: explicitSituation(
                possession: ["teamAbbreviation": .string("SEA"), "participantRole": .string("home")],
                shotClock: ["seconds": .number(4), "status": .string("running"), "confidence": .string("explicit")]
            )
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .basketball)
        XCTAssertEqual(situation?.pressureLine, "Late clock")
        guard case .basketballHalfCourt(let diagram) = situation?.diagram else {
            return XCTFail("Expected basketball half-court pressure module")
        }
        XCTAssertEqual(diagram.shotClockText, "4")
        XCTAssertNil(diagram.bonusText)
        XCTAssertNil(diagram.locationText)
    }

    func testFreeThrowBonusContextUsesExplicitPossessionPhase() {
        let event = basketballEvent(
            sequence: 3,
            eventType: "Free throw",
            sportMetadata: explicitSituation(
                possession: [
                    "teamAbbreviation": .string("SEA"),
                    "participantRole": .string("home"),
                    "phase": .string("freeThrow")
                ],
                bonus: [
                    "possessionTeamBonusStatus": .string("bonus"),
                    "confidence": .string("explicit")
                ],
                freeThrows: [
                    "attemptNumber": .number(2),
                    "totalAttempts": .number(2)
                ]
            )
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.title, "Foul pressure")
        XCTAssertEqual(situation?.setupText, "Free throws · 2 of 2 · In bonus")
        XCTAssertEqual(situation?.pressureLine, "In bonus")
        guard case .basketballHalfCourt(let diagram) = situation?.diagram else {
            return XCTFail("Expected basketball half-court pressure module")
        }
        XCTAssertEqual(diagram.possessionText, "SEA FT")
        XCTAssertEqual(diagram.bonusText, "In bonus")
        XCTAssertEqual(diagram.freeThrowText, "2 of 2")
    }

    func testMissingPossessionFallsBackWithoutBasketballClaims() {
        let event = basketballEvent(
            sequence: 4,
            sportMetadata: explicitSituation(
                possession: nil,
                shotClock: ["seconds": .number(7), "status": .string("running"), "confidence": .string("explicit")]
            )
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        if case .basketballHalfCourt = situation?.diagram {
            XCTFail("Missing possession should not render a basketball half-court module")
        }
    }

    func testGenericFallbackDoesNotInferPossessionOrShotClock() {
        let event = basketballEvent(
            sequence: 5,
            eventType: "Three pointer",
            sportMetadata: [
                "possession": .string("SEA"),
                "shotClock": .number(4),
                "bonus": .bool(true),
                "shotLocation": .string("right corner")
            ]
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let text = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertFalse(text.localizedCaseInsensitiveContains("shot clock"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("bonus"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("corner"))
    }

    private func explicitSituation(
        possession: [String: JSONValue]?,
        shotClock: [String: JSONValue]? = nil,
        bonus: [String: JSONValue]? = nil,
        freeThrows: [String: JSONValue]? = nil,
        shot: [String: JSONValue]? = nil
    ) -> [String: JSONValue] {
        var situation: [String: JSONValue] = [
            "schemaVersion": .number(1),
            "stateTiming": .string("preEvent"),
            "period": .object(["label": .string("Q4")]),
            "clock": .object(["label": .string("00:42")])
        ]
        if var possession {
            if possession["phase"] == nil { possession["phase"] = .string("liveBall") }
            if possession["confidence"] == nil { possession["confidence"] = .string("explicit") }
            situation["possession"] = .object(possession)
        }
        if let shotClock { situation["shotClock"] = .object(shotClock) }
        if let bonus { situation["bonus"] = .object(bonus) }
        if let freeThrows { situation["freeThrows"] = .object(freeThrows) }
        if let shot { situation["shot"] = .object(shot) }
        return ["basketballSituation": .object(situation)]
    }

    private func basketballEvent(
        sequence: Int,
        periodLabel: String = "Q4",
        clockLabel: String = "00:42",
        eventType: String = "Jump shot",
        scoreBefore: ScoreState? = nil,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        GameEvent(
            id: "basketball-pressure-\(sequence)",
            sourceEventID: "basketball-pressure-\(sequence)",
            sequence: sequence,
            periodOrdinal: periodLabel == "Q4" ? 4 : 2,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "\(periodLabel) \(clockLabel)", eventTypeLabel: eventType),
            importanceMetadata: nil,
            headline: "Basketball event \(sequence)",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: scoreState(home: nil, away: nil),
            scoreDelta: nil,
            sportMetadata: sportMetadata
        )
    }

    private func context(for event: GameEvent) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 3100 + event.sequence, leagueCode: "nba"),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )
    }
}

private func scoreState(home: Int?, away: Int?) -> ScoreState {
    ScoreState(participantScores: [
        ParticipantScore(participantID: "home", participantRole: .home, score: home),
        ParticipantScore(participantID: "away", participantRole: .away, score: away)
    ])
}
