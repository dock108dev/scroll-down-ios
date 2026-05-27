import XCTest
@testable import ScrollDownSports

@MainActor
final class FootballFieldSituationTests: XCTestCase {
    func testThirdAndLongUsesExplicitPreSnapFieldStrip() {
        let event = footballEvent(
            sequence: 1,
            eventType: "Pass",
            sportMetadata: [
                "preSnap": .object([
                    "down": .number(3),
                    "distance": .number(12),
                    "yardLine": .string("SEA 42"),
                    "possessionTeam": .string("SEA"),
                    "possessionRole": .string("home")
                ])
            ]
        )
        let context = context(for: event)

        let situation = FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: event, context: context)

        XCTAssertEqual(situation?.layout, .football)
        XCTAssertEqual(situation?.sport, .football)
        XCTAssertEqual(situation?.setupText, "3rd & 12 · SEA 42")
        XCTAssertEqual(situation?.periodText, "Q2 · 08:14")
        XCTAssertEqual(situation?.ownership?.role, .offense)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(situation?.pressureLine, "Third down")
        XCTAssertEqual(situation?.dataConfidence, .explicitPreEvent)
        guard case .footballFieldStrip(let strip) = situation?.diagram else {
            return XCTFail("Expected football field strip")
        }
        XCTAssertEqual(strip.downDistanceText, "3rd & 12")
        XCTAssertEqual(strip.yardLineText, "SEA 42")
        XCTAssertEqual(strip.lineOfScrimmageX, 42)
        XCTAssertEqual(strip.firstDownX, 54)
        XCTAssertEqual(strip.offenseDirection, .leftToRight)
        XCTAssertFalse(strip.isRedZone)
    }

    func testGoalToGoRedZoneUsesGoalLineMarker() {
        let event = footballEvent(
            sequence: 2,
            eventType: "Rush",
            sportMetadata: [
                "preSnap": .object([
                    "down": .number(2),
                    "distance": .string("goal to go"),
                    "yardLine": .string("OPP 8"),
                    "possessionTeam": .string("SEA"),
                    "possessionRole": .string("home")
                ])
            ]
        )

        let situation = FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.setupText, "2nd & goal · Opp 8")
        XCTAssertEqual(situation?.pressureLine, "Goal to go")
        guard case .footballFieldStrip(let strip) = situation?.diagram else {
            return XCTFail("Expected football field strip")
        }
        XCTAssertEqual(strip.lineOfScrimmageX, 92)
        XCTAssertEqual(strip.firstDownX, 100)
        XCTAssertTrue(strip.isRedZone)
    }

    func testMissingPossessionRendersNeutralStripWithoutDirectionOrFirstDownClaim() {
        let event = footballEvent(
            sequence: 3,
            eventType: "Completion",
            sportMetadata: [
                "preSnap": .object([
                    "down": .number(3),
                    "distance": .number(7),
                    "yardLine": .string("SEA 42")
                ])
            ]
        )

        let situation = FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertNil(situation?.ownership)
        guard case .footballFieldStrip(let strip) = situation?.diagram else {
            return XCTFail("Expected neutral football field strip")
        }
        XCTAssertEqual(strip.lineOfScrimmageX, 50)
        XCTAssertNil(strip.firstDownX)
        XCTAssertEqual(strip.offenseDirection, .unknown)
        XCTAssertNil(strip.possessionText)
    }

    func testAmbiguousYardLineMetadataFallsBackWithoutFieldClaims() {
        let event = footballEvent(
            sequence: 4,
            eventType: "Pass",
            sportMetadata: [
                "down": .number(3),
                "distance": .number(7),
                "yardLine": .string("SEA 42")
            ]
        )

        let situation = FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        if case .footballFieldStrip = situation?.diagram {
            XCTFail("Ambiguous football metadata should not render a field strip")
        }
    }

    func testMalformedExplicitStateFallsBackWhenGenericContextQualifies() {
        let event = footballEvent(
            sequence: 5,
            eventType: "Pass",
            sportMetadata: [
                "preSnap": .object([
                    "down": .number(5),
                    "distance": .number(7),
                    "yardLine": .string("SEA 42 to LAR 48"),
                    "possessionTeam": .string("SEA")
                ])
            ]
        )

        let situation = FootballRenderer(leagueCode: "nfl").eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected pressure board fallback")
        }
        let renderedText = board.metrics.flatMap { [$0.label, $0.value] }.joined(separator: " ")
        XCTAssertFalse(renderedText.localizedCaseInsensitiveContains("yard"))
        XCTAssertFalse(renderedText.localizedCaseInsensitiveContains("formation"))
    }

    private func footballEvent(
        sequence: Int,
        eventType: String,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        GameEvent(
            id: "football-field-\(sequence)",
            sourceEventID: "football-field-\(sequence)",
            sequence: sequence,
            periodOrdinal: 2,
            periodLabel: "Q2",
            clockLabel: "08:14",
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "Q2 08:14", eventTypeLabel: eventType),
            importanceMetadata: nil,
            headline: "Football event \(sequence)",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: nil,
            scoreAfter: ScoreState(participantScores: [
                ParticipantScore(participantID: "away", participantRole: .away, score: nil),
                ParticipantScore(participantID: "home", participantRole: .home, score: nil)
            ]),
            scoreDelta: nil,
            sportMetadata: sportMetadata
        )
    }

    private func context(for event: GameEvent) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 2100 + event.sequence, leagueCode: "nfl"),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )
    }
}
