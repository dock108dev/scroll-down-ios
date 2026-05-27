import XCTest
@testable import ScrollDownSports

@MainActor
final class SoccerSetPieceSituationTests: XCTestCase {
    func testLateTiedFreeKickUsesExplicitPitchStrip() {
        let event = soccerEvent(
            sequence: 1,
            clockLabel: "88'",
            scoreBefore: soccerScore(home: 1, away: 1),
            sportMetadata: explicitSoccerSituation(
                restartKind: "directFreeKick",
                phase: "setup",
                location: [
                    "zone": .string("attackingThird"),
                    "side": .string("center"),
                    "distanceToGoal": .number(23),
                    "angleToGoalDegrees": .number(12),
                    "x": .number(78),
                    "y": .number(50),
                    "coordinateSystem": .string("normalizedZeroToHundred")
                ],
                confidence: 0.92
            )
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .soccer)
        XCTAssertEqual(situation?.title, "Free kick in range")
        XCTAssertEqual(situation?.periodText, "88'")
        XCTAssertEqual(situation?.contextLine, "Tied")
        XCTAssertEqual(situation?.pressureLine, "Prime shooting range")
        XCTAssertEqual(situation?.ownership?.role, .attackingSide)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.dataConfidence, .explicitPreEvent)
        guard case .soccerPitchStrip(let pitch) = situation?.diagram else {
            return XCTFail("Expected soccer pitch strip")
        }
        XCTAssertEqual(pitch.setPieceText, "Free kick")
        XCTAssertEqual(pitch.locationText, "Attacking third · Central")
        XCTAssertEqual(pitch.ballX, 0.78)
        XCTAssertEqual(pitch.ballY, 0.50)
    }

    func testCornerSetupUsesExplicitSetPieceAndSide() {
        let event = soccerEvent(
            sequence: 2,
            scoreBefore: soccerScore(home: 2, away: 2),
            sportMetadata: explicitSoccerSituation(
                restartKind: "corner",
                phase: "awarded",
                location: [
                    "zone": .string("finalEighth"),
                    "side": .string("right"),
                    "x": .number(0.97),
                    "y": .number(0.90),
                    "coordinateSystem": .string("normalizedZeroToOne")
                ],
                confidence: 0.78
            )
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .soccer)
        XCTAssertEqual(situation?.title, "Corner")
        XCTAssertEqual(situation?.setupText, "Corner · Near goal · Right side")
        XCTAssertEqual(situation?.pressureLine, "Set-piece pressure")
        guard case .soccerPitchStrip(let pitch) = situation?.diagram else {
            return XCTFail("Expected soccer pitch strip")
        }
        XCTAssertTrue(pitch.highlightsGoalArea)
        XCTAssertEqual(pitch.setPieceText, "Corner")
    }

    func testPenaltyContextRequiresHighConfidenceExplicitState() {
        let event = soccerEvent(
            sequence: 3,
            scoreBefore: soccerScore(home: 0, away: 1),
            sportMetadata: explicitSoccerSituation(
                restartKind: "penaltyKick",
                phase: "setup",
                location: [
                    "zone": .string("penaltyArea"),
                    "side": .string("center"),
                    "x": .number(0.88),
                    "y": .number(0.50)
                ],
                confidence: 0.94
            )
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .soccer)
        XCTAssertEqual(situation?.title, "Penalty awarded")
        XCTAssertEqual(situation?.contextLine, "Down 1")
        XCTAssertEqual(situation?.pressureLine, "Penalty")
        guard case .soccerPitchStrip(let pitch) = situation?.diagram else {
            return XCTFail("Expected soccer pitch strip")
        }
        XCTAssertEqual(pitch.setPieceText, "Penalty")
        XCTAssertTrue(pitch.highlightsGoalArea)
    }

    func testMissingLocationFallsBackWithoutSoccerDiagramClaims() {
        let event = soccerEvent(
            sequence: 4,
            scoreBefore: soccerScore(home: 1, away: 1),
            sportMetadata: explicitSoccerSituation(
                restartKind: "directFreeKick",
                phase: "setup",
                location: nil,
                confidence: 0.92
            )
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        if case .soccerPitchStrip = situation?.diagram {
            XCTFail("Missing location should not render a soccer pitch strip")
        }
    }

    func testAmbiguousSetPieceTextDoesNotCreateSoccerCard() {
        let event = soccerEvent(
            sequence: 5,
            eventType: "Corner won",
            scoreBefore: soccerScore(home: 1, away: 1),
            sportMetadata: [
                "setPiece": .string("corner"),
                "location": .string("right corner"),
                "possession": .string("SEA")
            ]
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let boardText = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertFalse(boardText.localizedCaseInsensitiveContains("right corner"))
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
    }

    func testGenericFallbackStillWorksWithoutSoccerMetadata() {
        let event = soccerEvent(
            sequence: 6,
            eventType: "Shot on goal",
            scoreBefore: soccerScore(home: 1, away: 2),
            sportMetadata: [:]
        )

        let situation = SoccerRenderer(leagueCode: "mls").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.sport, .soccer)
        XCTAssertEqual(situation?.contextLine, "Down 1")
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
    }

    private func explicitSoccerSituation(
        restartKind: String,
        phase: String,
        location: [String: JSONValue]?,
        confidence: Double
    ) -> [String: JSONValue] {
        var situation: [String: JSONValue] = [
            "stateTiming": .string("preEvent"),
            "clock": .object(["minute": .number(88)]),
            "setPiece": .object([
                "restartKind": .string(restartKind),
                "phase": .string(phase)
            ]),
            "attackingTeam": .object([
                "teamAbbreviation": .string("SEA"),
                "participantRole": .string("home")
            ]),
            "confidenceScore": .number(confidence)
        ]
        if let location {
            situation["location"] = .object(location)
        }
        return ["soccerSituation": .object(situation)]
    }

    private func soccerEvent(
        sequence: Int,
        clockLabel: String = "88'",
        eventType: String = "Set piece",
        scoreBefore: ScoreState,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        GameEvent(
            id: "soccer-set-piece-\(sequence)",
            sourceEventID: "soccer-set-piece-\(sequence)",
            sequence: sequence,
            periodOrdinal: 2,
            periodLabel: "Second Half",
            clockLabel: clockLabel,
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: clockLabel, eventTypeLabel: eventType),
            importanceMetadata: nil,
            headline: "Soccer event \(sequence)",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: soccerScore(home: nil, away: nil),
            scoreDelta: nil,
            sportMetadata: sportMetadata
        )
    }

    private func context(for event: GameEvent) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 4100 + event.sequence, leagueCode: "mls"),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )
    }
}

private func soccerScore(home: Int?, away: Int?) -> ScoreState {
    ScoreState(participantScores: [
        ParticipantScore(participantID: "home", participantRole: .home, score: home),
        ParticipantScore(participantID: "away", participantRole: .away, score: away)
    ])
}
