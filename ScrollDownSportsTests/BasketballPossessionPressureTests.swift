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

    func testFirstClassSnapshotBasketballSituationMergesClockContextAndAliases() {
        let snapshot = GameEventSituationSnapshot(
            schemaVersion: 1,
            sport: "NBA",
            display: nil,
            score: nil,
            period: GameEventSituationPeriod(ordinal: 1, label: "Q1", phase: nil),
            clock: GameEventSituationClock(label: "07:30", secondsRemaining: 450),
            possession: nil,
            sportState: GameEventSituationSportState(
                baseball: nil,
                football: nil,
                hockey: nil,
                basketball: [
                    "basketballSituation": .object([
                        "schemaVersion": .number(1),
                        "timing": .string("before_play"),
                        "possession": .object([
                            "side": .string("away"),
                            "teamName": .string("Storm"),
                            "phase": .string("inbound"),
                            "confidence": .string("verified_derived")
                        ]),
                        "shot_clock": .object([
                            "label": .string("6.5"),
                            "seconds": .number(6.5),
                            "status": .string("running"),
                            "confidence": .string("verified")
                        ]),
                        "bonus": .object([
                            "foulsToBonus": .number(1),
                            "away": .object([
                                "status": .string("none"),
                                "foulsToBonus": .number(1)
                            ]),
                            "confidence": .string("derived")
                        ]),
                        "shot": .object([
                            "points": .number(3),
                            "result": .string("fouled"),
                            "location": .object([
                                "coordinateSystem": .string("normalized_half_court"),
                                "x": .number(0.72),
                                "y": .number(0.36),
                                "zone": .string("right_corner_three"),
                                "confidence": .string("explicit")
                            ])
                        ]),
                        "free_throws": .object([
                            "attempt": .number(1),
                            "total": .number(2)
                        ])
                    ])
                ],
                soccer: nil,
                golf: nil,
                tennis: nil
            ),
            pressure: nil,
            confidence: GameEventSituationConfidence(level: "verified", source: "fixture", reasons: [])
        )
        let event = basketballEvent(
            sequence: 6,
            eventType: "Shooting foul",
            scoreBefore: scoreState(home: 55, away: 56),
            situationBefore: snapshot,
            sportMetadata: [:]
        )

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .basketball)
        XCTAssertEqual(situation?.title, "Shot profile")
        XCTAssertEqual(situation?.periodText, "Q1 07:30")
        XCTAssertEqual(situation?.setupText, "Inbound · 1 of 2 · 6.5 on clock · Right corner")
        XCTAssertEqual(situation?.contextLine, "Up 1")
        XCTAssertEqual(situation?.ownership?.teamLabel, "Storm")
        guard case .basketballHalfCourt(let diagram) = situation?.diagram else {
            return XCTFail("Expected first-class basketball metadata to render the half-court module")
        }
        XCTAssertEqual(diagram.possessionText, "Storm inbound")
        XCTAssertEqual(diagram.shotClockText, "6.5")
        XCTAssertEqual(diagram.shotText, "3PT fouled")
        XCTAssertEqual(diagram.locationText, "Right corner")
        XCTAssertEqual(diagram.freeThrowText, "1 of 2")
        XCTAssertEqual(diagram.shotLocation, BasketballDiagramShotLocation(x: 0.72, y: 0.36, label: "Right corner"))
    }

    func testBasketballValueTypesExposeDisplayAndPressureVariants() {
        XCTAssertEqual(
            BasketballPossessionState(
                participantRole: .other("Neutral"),
                teamAbbreviation: nil,
                teamLabel: nil,
                phase: .jumpBall,
                confidence: .explicit
            ).displayText,
            "Neutral"
        )
        XCTAssertEqual(BasketballPossessionPhase.deadBall.label, "Dead ball")

        XCTAssertEqual(BasketballShotClockState(seconds: 4, displayText: nil, status: .running, confidence: .explicit).metricText, "4")
        XCTAssertEqual(BasketballShotClockState(seconds: 6.5, displayText: nil, status: .stopped, confidence: .explicit).metricText, "Stopped at 6.5")
        XCTAssertEqual(BasketballShotClockState(seconds: nil, displayText: nil, status: .off, confidence: .explicit).metricText, "Off")
        XCTAssertEqual(BasketballShotClockState(seconds: nil, displayText: nil, status: .expired, confidence: .explicit).metricText, "Expired")
        XCTAssertNil(BasketballShotClockState(seconds: nil, displayText: nil, status: .unknown, confidence: .missing).metricText)
        XCTAssertEqual(BasketballShotClockState(seconds: 1, displayText: nil, status: .running, confidence: .explicit).pressureLabel, "End of clock")
        XCTAssertEqual(BasketballShotClockState(seconds: 4, displayText: nil, status: .running, confidence: .explicit).pressureLabel, "Late clock")
        XCTAssertEqual(BasketballShotClockState(seconds: 7, displayText: nil, status: .running, confidence: .explicit).pressureLabel, "Clock pressure")

        XCTAssertEqual(BasketballBonusState(possessionTeamStatus: .doubleBonus, possessionTeamFoulsToBonus: nil, confidence: .explicit).metricText, "Double bonus")
        XCTAssertEqual(BasketballBonusState(possessionTeamStatus: .some(BasketballBonusStatus.none), possessionTeamFoulsToBonus: 2, confidence: .explicit).metricText, "2 to bonus")
        XCTAssertNil(BasketballBonusState(possessionTeamStatus: .unknown, possessionTeamFoulsToBonus: nil, confidence: .missing).metricText)

        XCTAssertEqual(BasketballShotState(result: .made, value: 2, location: nil, confidence: .explicit).metricText, "2PT made")
        XCTAssertEqual(BasketballShotResult.blocked.label, "blocked")
        XCTAssertNil(BasketballShotResult.unknown.label)
        XCTAssertEqual(BasketballShotZone.restrictedArea.label, "Restricted area")
        XCTAssertEqual(BasketballShotZone.paint.label, "Paint")
        XCTAssertEqual(BasketballShotZone.midrange.label, "Midrange")
        XCTAssertEqual(BasketballShotZone.leftCornerThree.label, "Left corner")
        XCTAssertEqual(BasketballShotZone.aboveBreakThree.label, "Above break")
        XCTAssertEqual(BasketballShotZone.backcourt.label, "Backcourt")
        XCTAssertNil(BasketballShotZone.unknown.label)

        XCTAssertNil(BasketballFreeThrowState(attemptNumber: 0, totalAttempts: 2).metricText)
        XCTAssertTrue(BasketballFieldConfidence.verifiedDerived.canRenderAssertiveState)
        XCTAssertFalse(BasketballFieldConfidence.derived.canRenderAssertiveState)
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
        situationBefore: GameEventSituationSnapshot? = nil,
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
            situationBefore: situationBefore,
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
