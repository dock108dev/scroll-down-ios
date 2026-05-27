import XCTest
@testable import ScrollDownSports

final class ScorePressurePresentationTests: XCTestCase {
    func testPressureLineUsesEventOwnerAndPrePlayScore() {
        let event = makeEvent(
            teamOwnership: .away,
            scoreBefore: score(away: 2, home: 5),
            scoreAfter: score(away: 2, home: 5)
        )

        let line = ScorePressurePresentation.line(for: event, teamLabel: "New York")

        XCTAssertEqual(line?.role, .away)
        XCTAssertEqual(line?.before, .trailing(by: 3))
        XCTAssertNil(line?.after)
        XCTAssertNil(line?.scoredPoints)
        XCTAssertEqual(line?.text, "Down 3")
        XCTAssertEqual(line?.accessibilityText, "New York was down by 3 before the play.")
    }

    func testScoringPlayCanShowBeforeToAfterSwing() {
        let event = makeEvent(
            teamOwnership: .home,
            scoreBefore: score(away: 1, home: 1),
            scoreAfter: score(away: 1, home: 2),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 1, after: 2, change: 1)
        )

        let line = ScorePressurePresentation.line(for: event)

        XCTAssertEqual(line?.before, .tied)
        XCTAssertEqual(line?.after, .leading(by: 1))
        XCTAssertEqual(line?.scoredPoints, 1)
        XCTAssertEqual(line?.swingKind, .goAhead)
        XCTAssertEqual(line?.text, "Tied -> Up 1")
    }

    func testMissingOwnershipCanUseTrustworthyScoringDeltaSide() {
        let event = makeEvent(
            teamOwnership: nil,
            scoreBefore: score(away: 2, home: 3),
            scoreAfter: score(away: 4, home: 3),
            scoreDelta: ScoreDelta(participantID: "away", participantRole: .away, before: 2, after: 4, change: 2)
        )

        let line = ScorePressurePresentation.line(for: event)

        XCTAssertEqual(line?.role, .away)
        XCTAssertEqual(line?.opponentRole, .home)
        XCTAssertEqual(line?.swingKind, .leadChange)
        XCTAssertEqual(line?.text, "Down 1 -> Up 1")
    }

    func testPressureLineReturnsNilForIncompleteOrAmbiguousInputs() {
        let missingOwnership = makeEvent(
            teamOwnership: nil,
            scoreBefore: score(away: 1, home: 1),
            scoreAfter: score(away: 1, home: 1)
        )
        let missingBeforeScore = makeEvent(
            teamOwnership: .home,
            scoreBefore: nil,
            scoreAfter: score(away: 3, home: 7)
        )
        let partialBeforeScore = makeEvent(
            teamOwnership: .home,
            scoreBefore: score(away: nil, home: 7),
            scoreAfter: score(away: 3, home: 7)
        )

        XCTAssertNil(ScorePressurePresentation.line(for: missingOwnership))
        XCTAssertNil(ScorePressurePresentation.line(for: missingBeforeScore))
        XCTAssertNil(ScorePressurePresentation.line(for: partialBeforeScore))
    }

    func testNonScoringPlayDoesNotInferSwingFromChangedAfterScore() {
        let event = makeEvent(
            teamOwnership: .home,
            scoreBefore: score(away: 4, home: 4),
            scoreAfter: score(away: 4, home: 7)
        )

        let line = ScorePressurePresentation.line(for: event)

        XCTAssertEqual(line?.text, "Tied")
        XCTAssertNil(line?.after)
        XCTAssertNil(line?.scoredPoints)
    }

    private func makeEvent(
        teamOwnership: GameParticipantRole?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        scoreDelta: ScoreDelta? = nil
    ) -> GameEvent {
        GameEvent(
            id: "event-\(UUID().uuidString)",
            sourceEventID: nil,
            sequence: 1,
            periodOrdinal: 4,
            periodLabel: "Q4",
            clockLabel: "01:18",
            teamOwnership: teamOwnership,
            teamAbbreviation: nil,
            eventType: "play",
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: nil,
            importanceMetadata: nil,
            headline: "Play",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            scoreDelta: scoreDelta,
            sportMetadata: [:]
        )
    }

    private func score(away: Int?, home: Int?) -> ScoreState {
        ScoreState(
            participantScores: [
                ParticipantScore(participantID: "away", participantRole: .away, score: away),
                ParticipantScore(participantID: "home", participantRole: .home, score: home)
            ]
        )
    }
}
