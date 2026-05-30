import XCTest
@testable import ScrollDownSports

final class ScoreSpoilerFilterTests: XCTestCase {
    func testAbsoluteScoreDetectionCoversScoreLabelsAndFinalOutcomeText() {
        let game = finalGame()

        XCTAssertTrue(ScoreSpoilerFilter.containsScoreBearingText("SEA 5, OAK 4", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("SEA 5, OAK 4", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("5 Mariners", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Score: 5", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners leads 5-4", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners 5", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("5-4 Final", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners won in extras", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Rodriguez ties it at 4", for: game))
        XCTAssertFalse(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners rally", for: liveGame()))
    }

    func testRelativePressureDetectionAvoidsNonScoreBaseballContext() {
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Down 3 -> Tied"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Team was down by 3 before the play"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Tied -> Up 2"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Lead change"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("go-ahead basket"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("cuts the deficit"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("walk-off chance"))

        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("3rd and 7"))
        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("Shot from 24 feet"))
        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("2 outs"))
    }

    func testTopRegionAndMatchupFilteringFallBackWithoutScoreLeakage() {
        let game = finalGame()

        XCTAssertNil(ScoreSpoilerFilter.topRegionText("SEA 5, OAK 4", for: game))
        XCTAssertNil(ScoreSpoilerFilter.topRegionText("   ", for: game))
        XCTAssertEqual(ScoreSpoilerFilter.topRegionText("Late pitchers duel", for: game), "Late pitchers duel")
        XCTAssertEqual(ScoreSpoilerFilter.matchupText(for: game), "Oakland Athletics at Seattle Mariners")
    }

    func testDefaultHiddenPolicyKeepsRelativeSituationButRemovesAbsoluteScores() {
        let filtered = EventScoreSpoilerFilter.filtered(
            presentation: scoringPresentation(),
            game: finalGame(),
            policy: .hideAbsoluteScores
        )

        XCTAssertEqual(filtered.headline, "Scoring play")
        XCTAssertNil(filtered.detail)
        XCTAssertNil(filtered.scoreLabel)
        XCTAssertEqual(filtered.situation?.setupText, "Runner on 2nd · 1 out")
        XCTAssertEqual(filtered.situation?.contextLine, "Down 1 -> Tied")
        XCTAssertEqual(filtered.situation?.pressureLine, "Lead change")
        XCTAssertEqual(filtered.situationAccessibilityText, "Seattle was down by 1 before the play and tied after the play.")
        if case .baseballDiamond(let diagram) = filtered.situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.second])
        } else {
            XCTFail("Expected non-score baseball setup to remain visible")
        }
    }

    func testStrictHiddenPolicyRemovesRelativePressureWithoutDroppingSetup() {
        let filtered = EventScoreSpoilerFilter.filtered(
            presentation: scoringPresentation(),
            game: finalGame(),
            policy: .hideAllScorePressure
        )

        XCTAssertNil(filtered.scoreLabel)
        XCTAssertEqual(filtered.situation?.setupText, "Runner on 2nd · 1 out")
        XCTAssertNil(filtered.situation?.contextLine)
        XCTAssertNil(filtered.situation?.pressureLine)
        XCTAssertNil(filtered.situationAccessibilityText)
        if case .baseballDiamond(let diagram) = filtered.situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.second])
        } else {
            XCTFail("Expected strict pressure hiding to preserve the baseball diagram")
        }
    }

    func testScoreHiddenBaseballScoringSituationKeepsSetupBeforeReveal() {
        let event = baseballScoringEvent()
        let context = SportRendererSituationContext(
            game: finalGame(),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0,
            scoreSpoilerPolicy: .hideAbsoluteScores
        )

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "B8", context: context)

        XCTAssertEqual(presentation.headline, "Scoring")
        XCTAssertNil(presentation.detail)
        XCTAssertNil(presentation.scoreLabel)
        XCTAssertEqual(presentation.situation?.setupText, "Runner on 2nd · 1 out")
        XCTAssertEqual(presentation.situation?.contextLine, "Down 1 -> Tied")
        XCTAssertEqual(presentation.situation?.pressureLine, "Tying play")
        XCTAssertEqual(presentation.situationAccessibilityText, presentation.situation?.accessibilitySummary)
        if case .baseballDiamond(let diagram) = presentation.situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.second])
        } else {
            XCTFail("Expected a score-hidden baseball row to keep its pre-state diagram")
        }
    }

    func testStrictPolicyRedactsBasketballAndPressureBoardScorePressure() {
        let basketball = GameEventPresentation(
            clockText: "Q4 00:42",
            headline: "Seattle trims it to 79-78",
            detail: "SEA 78, OAK 79",
            eventLabel: nil,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            scoringLabel: "3PT made",
            scoreLabel: "SEA 78, OAK 79",
            rawFeedText: "Down 4 before the shot",
            rawFeedSource: "SEA 78, OAK 79 provider",
            accessibilityLabel: "Seattle makes it 79-78",
            situation: GameEventSituationPresentation(
                title: "Clock pressure",
                periodText: "Q4 00:42",
                setupText: "6 on clock",
                contextLine: "Down 4",
                pressureLine: "Late clock",
                sport: .basketball,
                layout: .basketball,
                ownership: nil,
                diagram: .basketballHalfCourt(
                    BasketballHalfCourtDiagram(
                        possessionText: "SEA ball",
                        clockText: "Q4 00:42",
                        shotClockText: "6",
                        scoreText: "Down 4",
                        bonusText: nil,
                        shotText: "3PT made",
                        locationText: "Right corner",
                        freeThrowText: nil,
                        shotLocation: BasketballDiagramShotLocation(x: 0.80, y: 0.32, label: "Right corner"),
                        pressure: 0.68
                    )
                ),
                accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: "SEA", teamLabel: "Seattle", tone: .critical),
                dataConfidence: .explicitPreEvent
            ),
            situationAccessibilityText: "Seattle down by 4 before the play."
        )
        let filteredBasketball = EventScoreSpoilerFilter.filtered(
            presentation: basketball,
            game: finalGame(),
            policy: .hideAllScorePressure
        )

        XCTAssertEqual(filteredBasketball.headline, "3PT made")
        XCTAssertNil(filteredBasketball.detail)
        XCTAssertNil(filteredBasketball.rawFeedText)
        XCTAssertNil(filteredBasketball.rawFeedSource)
        XCTAssertNil(filteredBasketball.accessibilityLabel)
        XCTAssertNil(filteredBasketball.situationAccessibilityText)
        XCTAssertNil(filteredBasketball.situation?.contextLine)
        XCTAssertNil(filteredBasketball.situation?.pressureLine)
        guard case .basketballHalfCourt(let basketballDiagram) = filteredBasketball.situation?.diagram else {
            return XCTFail("Expected basketball diagram to remain after score-pressure redaction")
        }
        XCTAssertNil(basketballDiagram.scoreText)
        XCTAssertNil(basketballDiagram.pressure)

        let board = GameEventPresentation(
            clockText: "Q4 00:42",
            headline: "SEA 78, OAK 79",
            detail: nil,
            eventLabel: nil,
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            scoringLabel: nil,
            scoreLabel: "SEA 78, OAK 79",
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: nil,
            situation: GameEventSituationPresentation(
                title: "Context",
                periodText: "Q4 00:42",
                setupText: nil,
                contextLine: "Down 1",
                pressureLine: "Lead change",
                sport: .basketball,
                layout: .pressureBoardFallback,
                ownership: nil,
                diagram: .pressureBoardFallback(
                    PressureBoardSituationDiagram(
                        associations: [],
                        metrics: [
                            PressureBoardSituationMetric(label: "Score", value: "SEA 78, OAK 79", emphasis: .primary),
                            PressureBoardSituationMetric(label: "Lead change", value: "Yes", emphasis: .secondary),
                            PressureBoardSituationMetric(label: "Pressure", value: "Down 1", emphasis: .pressure),
                            PressureBoardSituationMetric(label: "Clock", value: "00:42", emphasis: .secondary)
                        ]
                    )
                ),
                accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: "SEA", teamLabel: "Seattle", tone: .critical),
                dataConfidence: .explicitGenericEventContext
            ),
            situationAccessibilityText: nil
        )
        let filteredBoard = EventScoreSpoilerFilter.filtered(
            presentation: board,
            game: finalGame(),
            policy: .hideAllScorePressure
        )

        guard case .pressureBoardFallback(let pressureBoard) = filteredBoard.situation?.diagram else {
            return XCTFail("Expected pressure board fallback to remain after redaction")
        }
        XCTAssertEqual(pressureBoard.metrics.map(\.label), ["Clock"])
    }

    func testHiddenAbsoluteScoreFiltersRawFeedSourceAndMetricLabels() {
        let presentation = GameEventPresentation(
            clockText: "B8",
            headline: "Rodriguez singles to right.",
            detail: nil,
            eventLabel: "Single",
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            scoringLabel: nil,
            scoreLabel: "SEA 5, OAK 4",
            rawFeedText: "Runner on second before the pitch.",
            rawFeedSource: "SEA 5, OAK 4 provider feed",
            accessibilityLabel: nil,
            situation: GameEventSituationPresentation(
                title: "Context",
                periodText: nil,
                setupText: nil,
                contextLine: nil,
                pressureLine: nil,
                sport: .baseball,
                layout: .pressureBoardFallback,
                ownership: nil,
                diagram: .pressureBoardFallback(
                    PressureBoardSituationDiagram(
                        associations: [],
                        metrics: [
                            PressureBoardSituationMetric(label: "SEA 5, OAK 4", value: "Current", emphasis: .primary),
                            PressureBoardSituationMetric(label: "Base state", value: "Runner on second", emphasis: .secondary)
                        ]
                    )
                ),
                accent: GameEventSituationAccent(ownership: .home, teamAbbreviation: "SEA", teamLabel: "Seattle", tone: .neutral),
                dataConfidence: .explicitGenericEventContext
            ),
            situationAccessibilityText: nil
        )

        let filtered = EventScoreSpoilerFilter.filtered(
            presentation: presentation,
            game: finalGame(),
            policy: .hideAbsoluteScores
        )

        XCTAssertEqual(filtered.rawFeedText, "Runner on second before the pitch.")
        XCTAssertNil(filtered.rawFeedSource)
        guard case .pressureBoardFallback(let board) = filtered.situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Base state"])
    }

    private func finalGame() -> Game {
        TestFixtures.makeGame(
            leagueCode: "mlb",
            status: "final",
            isLive: false,
            isFinal: true,
            awayName: "Oakland Athletics",
            awayAbbreviation: "OAK",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA",
            awayScore: 4,
            homeScore: 5
        )
    }

    private func liveGame() -> Game {
        TestFixtures.makeGame(
            leagueCode: "mlb",
            status: "live",
            isLive: true,
            isFinal: false,
            awayName: "Oakland Athletics",
            awayAbbreviation: "OAK",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA",
            awayScore: 4,
            homeScore: 5
        )
    }

    private func scoringPresentation() -> GameEventPresentation {
        let situation = GameEventSituationPresentation(
            title: "Situation",
            periodText: "B8 1 out",
            setupText: "Runner on 2nd · 1 out",
            contextLine: "Down 1 -> Tied",
            pressureLine: "Lead change",
            sport: .baseball,
            layout: .baseball,
            ownership: GameEventSituationOwnership(
                role: .batting,
                participantRole: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle",
                confidence: .explicit
            ),
            diagram: .baseballDiamond(
                BaseballSituationDiagram(
                    occupiedBases: [.second],
                    batting: nil,
                    outs: 1,
                    count: nil
                )
            ),
            accent: GameEventSituationAccent(
                ownership: .home,
                teamAbbreviation: "SEA",
                teamLabel: "Seattle",
                tone: .critical
            ),
            dataConfidence: .explicitPreEvent
        )
        return GameEventPresentation(
            clockText: "B8 1 out",
            headline: "SEA 5, OAK 4 after Rodriguez scores",
            detail: "Final score: SEA 5, OAK 4",
            eventLabel: "Single",
            teamAbbreviation: "SEA",
            teamLabel: "Seattle",
            scoringLabel: "Scoring play",
            scoreLabel: "SEA 5, OAK 4",
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: nil,
            situation: situation,
            situationAccessibilityText: "Seattle was down by 1 before the play and tied after the play."
        )
    }

    private func baseballScoringEvent() -> GameEvent {
        GameEvent(
            id: "hidden-score-scoring-row",
            sourceEventID: nil,
            sequence: 41,
            periodOrdinal: 8,
            periodLabel: "B8",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: "Single",
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(scoreLabel: "SEA 5, OAK 4"),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 96,
                bucket: "scoring",
                reasons: ["late_game"],
                isKeyMoment: true,
                isScoringPlay: true,
                isLeadChange: false,
                isTyingPlay: true,
                winProbabilityDelta: nil
            ),
            headline: "Rodriguez singles to make it 5-5",
            detail: "SEA 5, OAK 5 after the single",
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 4),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 5)
                ]
            ),
            scoreAfter: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 5),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 5)
                ]
            ),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 4, after: 5, change: 1),
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1)
            ]
        )
    }
}
