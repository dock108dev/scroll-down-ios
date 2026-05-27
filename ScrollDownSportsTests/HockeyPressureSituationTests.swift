import XCTest
@testable import ScrollDownSports

@MainActor
final class HockeyPressureSituationTests: XCTestCase {
    func testPowerPlayGoalSetupUsesExplicitRinkStrip() {
        let event = hockeyEvent(
            sequence: 1,
            eventType: "Goal",
            importanceMetadata: scoringImportance,
            scoreBefore: scoreState(home: 2, away: 2),
            scoreAfter: scoreState(home: 3, away: 2),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 2, after: 3, change: 1),
            sportMetadata: [
                "preShot": .object([
                    "strength": .string("power_play"),
                    "zone": .string("offensive"),
                    "attackingTeamAbbreviation": .string("SEA"),
                    "attackingRole": .string("home"),
                    "puckLocation": .string("slot")
                ])
            ]
        )

        let situation = HockeyRenderer().eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .hockey)
        XCTAssertEqual(situation?.sport, .hockey)
        XCTAssertEqual(situation?.setupText, "Power play · Offensive zone · Slot")
        XCTAssertEqual(situation?.ownership?.role, .attackingSide)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(situation?.pressureLine, "Power-play finish")
        XCTAssertEqual(situation?.dataConfidence, .explicitPreEvent)
        guard case .hockeyRinkStrip(let strip) = situation?.diagram else {
            return XCTFail("Expected explicit offensive-zone hockey state to render a rink strip")
        }
        XCTAssertEqual(strip.zone, .offensive)
        XCTAssertEqual(strip.puckLocation, .slot)
        XCTAssertEqual(strip.attackingTeamAbbreviation, "SEA")
    }

    func testEvenStrengthShotSetupUsesAttackingZoneWithoutScoringClaim() {
        let event = hockeyEvent(
            sequence: 2,
            eventType: "Shot",
            sportMetadata: [
                "preEvent": .object([
                    "strength": .string("even"),
                    "zone": .string("offensive"),
                    "attackingTeam": .string("NHB"),
                    "attackingRole": .string("away")
                ])
            ]
        )

        let situation = HockeyRenderer().eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .hockey)
        XCTAssertEqual(situation?.setupText, "Even strength · Offensive zone")
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "NHB")
        XCTAssertEqual(situation?.pressureLine, "Attacking-zone pressure")
        guard case .hockeyRinkStrip(let strip) = situation?.diagram else {
            return XCTFail("Expected explicit zone state to render a rink strip")
        }
        XCTAssertEqual(strip.zone, .offensive)
        XCTAssertNil(strip.puckLocation)
    }

    func testMissingZoneKeepsHockeyCardButSuppressesRinkStrip() {
        let event = hockeyEvent(
            sequence: 3,
            eventType: "Shot",
            sportMetadata: [
                "preShot": .object([
                    "strength": .string("power_play"),
                    "attackingTeamAbbreviation": .string("SEA"),
                    "attackingRole": .string("home")
                ])
            ]
        )

        let situation = HockeyRenderer().eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .hockey)
        XCTAssertEqual(situation?.setupText, "Power play")
        XCTAssertEqual(situation?.pressureLine, "Man advantage")
        XCTAssertNil(situation?.diagram)
    }

    func testAmbiguousStrengthMetadataFallsBackWithoutRinkClaims() {
        let event = hockeyEvent(
            sequence: 4,
            eventType: "Shot",
            sportMetadata: [
                "preShot": .object([
                    "strength": .string("special teams"),
                    "zone": .string("offensive"),
                    "attackingTeamAbbreviation": .string("SEA"),
                    "puckLocation": .string("slot")
                ])
            ]
        )

        let situation = HockeyRenderer().eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.dataConfidence, .ambiguousMetadata)
        if case .hockeyRinkStrip = situation?.diagram {
            XCTFail("Ambiguous hockey metadata should not render a rink strip")
        }
    }

    func testGenericFallbackDoesNotInventHockeyStateFromEventText() {
        let event = hockeyEvent(
            sequence: 5,
            eventType: "Shot",
            headline: "Shot from the slot with traffic in front",
            detail: "Seattle keeps the puck in the attacking zone.",
            sportMetadata: [:]
        )

        let situation = HockeyRenderer().eventSituationPresentation(for: event, context: context(for: event))

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.sport, .hockey)
        XCTAssertEqual(situation?.dataConfidence, .explicitGenericEventContext)
        if case .hockeyRinkStrip = situation?.diagram {
            XCTFail("Hockey renderer should not infer rink state from prose")
        }
    }

    private var scoringImportance: EventImportanceData {
        EventImportanceData(
            level: "primary",
            rank: 90,
            bucket: "scoring",
            reasons: ["score_change"],
            isKeyMoment: true,
            isScoringPlay: true,
            isLeadChange: true,
            isTyingPlay: false,
            winProbabilityDelta: nil
        )
    }

    private func hockeyEvent(
        sequence: Int,
        eventType: String,
        headline: String? = nil,
        detail: String? = nil,
        importanceMetadata: EventImportanceData? = nil,
        scoreBefore: ScoreState? = nil,
        scoreAfter: ScoreState = scoreState(home: nil, away: nil),
        scoreDelta: ScoreDelta? = nil,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        GameEvent(
            id: "hockey-pressure-\(sequence)",
            sourceEventID: "hockey-pressure-\(sequence)",
            sequence: sequence,
            periodOrdinal: 3,
            periodLabel: "3rd",
            clockLabel: "02:11",
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: EventPresentationData(
                headline: nil,
                shortHeadline: nil,
                body: nil,
                primaryLabel: nil,
                secondaryLabel: nil,
                tertiaryLabel: nil,
                timeLabel: "3rd 02:11",
                accessibilityLabel: nil,
                eventTypeLabel: eventType,
                teamLabel: "Seattle",
                playerLabel: nil,
                scoreLabel: nil
            ),
            importanceMetadata: importanceMetadata,
            headline: headline ?? "Hockey pressure \(sequence)",
            detail: detail,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: scoreAfter,
            scoreDelta: scoreDelta,
            sportMetadata: sportMetadata
        )
    }

    private func context(for event: GameEvent) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 2200 + event.sequence, leagueCode: "nhl"),
            selectedMode: .key,
            visibleEvents: [event],
            eventIndex: 0
        )
    }
}

private func scoreState(home: Int?, away: Int?) -> ScoreState {
    ScoreState(participantScores: [
        ParticipantScore(participantID: "away", participantRole: .away, score: away),
        ParticipantScore(participantID: "home", participantRole: .home, score: home)
    ])
}
