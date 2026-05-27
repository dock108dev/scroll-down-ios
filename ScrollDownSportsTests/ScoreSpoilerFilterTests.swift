import XCTest
@testable import ScrollDownSports

final class ScoreSpoilerFilterTests: XCTestCase {
    func testAbsoluteScoreDetectionCoversScoreLabelsAndFinalOutcomeText() {
        let game = finalGame()

        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("SEA 5, OAK 4", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners 5", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("5-4 Final", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Mariners won in extras", for: game))
        XCTAssertTrue(ScoreSpoilerFilter.containsAbsoluteScoreBearingText("Rodriguez ties it at 4", for: game))
    }

    func testRelativePressureDetectionAvoidsNonScoreBaseballContext() {
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Down 3 -> Tied"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Team was down by 3 before the play"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Tied -> Up 2"))
        XCTAssertTrue(ScoreSpoilerFilter.containsRelativeScorePressureText("Lead change"))

        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("3rd and 7"))
        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("Shot from 24 feet"))
        XCTAssertFalse(ScoreSpoilerFilter.containsRelativeScorePressureText("2 outs"))
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
