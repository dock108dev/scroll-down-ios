import XCTest
@testable import ScrollDownSports

@MainActor
final class SituationOwnershipAccentTests: XCTestCase {
    func testExplicitBattingRoleOverridesConflictingAbbreviation() {
        let game = TestFixtures.makeGame(
            id: 2100,
            leagueCode: "mlb",
            awayName: "New York Yankees",
            awayAbbreviation: "NYY",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA"
        )
        let event = TestFixtures.makeEvent(
            sequence: 1,
            periodLabel: "T8",
            eventType: "Double",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "battingTeamRole": .string("home"),
                "battingTeamAbbreviation": .string("NYY")
            ]
        )

        let situation = BaseballRenderer().eventSituationPresentation(
            for: event,
            context: context(for: game, event: event)
        )

        XCTAssertEqual(situation?.ownership?.role, .batting)
        XCTAssertEqual(situation?.ownership?.participantRole, .home)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.teamLabel, "Seattle Mariners")
        XCTAssertEqual(situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(situation?.ownership?.displayLabel, "Batting SEA")
        XCTAssertEqual(situation?.accent.ownership, .home)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "SEA")
        if case .baseballDiamond(let diagram) = situation?.diagram {
            XCTAssertEqual(diagram.batting?.displayLabel, "Batting SEA")
        } else {
            XCTFail("Expected a baseball diamond situation diagram")
        }
    }

    func testBottomInningDerivesHomeBattingOwnership() {
        let game = TestFixtures.makeGame(
            id: 2101,
            leagueCode: "mlb",
            awayAbbreviation: "NYY",
            homeAbbreviation: "SEA"
        )
        let event = TestFixtures.makeEvent(
            sequence: 2,
            periodLabel: "B8",
            eventType: "Double",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second")
            ]
        )

        let situation = BaseballRenderer().eventSituationPresentation(
            for: event,
            context: context(for: game, event: event)
        )

        XCTAssertEqual(situation?.ownership?.role, .batting)
        XCTAssertEqual(situation?.ownership?.participantRole, .home)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .derivedFromPeriod)
        XCTAssertEqual(situation?.accent.ownership, .home)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "SEA")
    }

    func testEventFallbackUsesTeamAssociationWithoutBattingClaim() {
        let game = TestFixtures.makeGame(id: 2102, leagueCode: "mlb")
        let event = TestFixtures.makeEvent(
            sequence: 3,
            periodLabel: nil,
            clockLabel: nil,
            eventType: "Double",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second")
            ]
        )

        let situation = BaseballRenderer().eventSituationPresentation(
            for: event,
            context: context(for: game, event: event)
        )

        XCTAssertEqual(situation?.ownership?.role, .association)
        XCTAssertEqual(situation?.ownership?.participantRole, .home)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .eventFallback)
        XCTAssertEqual(situation?.ownership?.displayLabel, "Team SEA")
        XCTAssertEqual(situation?.accent.ownership, .home)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "SEA")
        if case .baseballDiamond(let diagram) = situation?.diagram {
            XCTAssertEqual(diagram.batting?.role, .association)
            XCTAssertEqual(diagram.batting?.confidence, .eventFallback)
        } else {
            XCTFail("Expected event-associated baseball situation diagram")
        }
    }

    func testGenericFallbackKeepsAssociationOwnershipAndEventAccent() {
        let event = eventWithTeam(sequence: 4, teamOwnership: .away, teamAbbreviation: "NYY")
        let game = TestFixtures.makeGame(id: 2103, leagueCode: "nba")

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(
            for: event,
            context: context(for: game, event: event)
        )

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.ownership?.role, .association)
        XCTAssertEqual(situation?.ownership?.participantRole, .away)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "NYY")
        XCTAssertEqual(situation?.ownership?.confidence, .eventFallback)
        XCTAssertEqual(situation?.ownership?.displayLabel, "Team NYY")
        XCTAssertEqual(situation?.accent.ownership, .away)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "NYY")
    }

    func testAccentFallsBackToSemanticToneWithoutTeamCue() {
        let event = eventWithTeam(
            sequence: 5,
            teamOwnership: nil,
            teamAbbreviation: nil,
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 95,
                bucket: "score",
                reasons: [],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: true,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            scoreBefore: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 72),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 73)
                ]
            ),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 72, after: 75, change: 3)
        )
        let game = TestFixtures.makeGame(id: 2104, leagueCode: "nba")

        let situation = BasketballRenderer(leagueCode: "nba").eventSituationPresentation(
            for: event,
            context: context(for: game, event: event)
        )

        XCTAssertNil(situation?.ownership)
        XCTAssertNil(situation?.accent.ownership)
        XCTAssertNil(situation?.accent.teamAbbreviation)
        XCTAssertEqual(situation?.accent.tone, .critical)
    }

    private func context(
        for game: Game,
        event: GameEvent,
        selectedMode: DetailStreamMode = .full
    ) -> SportRendererSituationContext {
        SportRendererSituationContext(game: game, selectedMode: selectedMode, visibleEvents: [event], eventIndex: 0)
    }

    private func eventWithTeam(
        sequence: Int,
        teamOwnership: GameParticipantRole?,
        teamAbbreviation: String?,
        importanceMetadata: EventImportanceData? = nil,
        scoreBefore: ScoreState? = nil,
        scoreDelta: ScoreDelta? = nil
    ) -> GameEvent {
        GameEvent(
            id: "ownership-accent-\(sequence)",
            sourceEventID: "ownership-accent-\(sequence)",
            sequence: sequence,
            periodOrdinal: nil,
            periodLabel: "Q4",
            clockLabel: "00:42",
            teamOwnership: teamOwnership,
            teamAbbreviation: teamAbbreviation,
            eventType: "Three pointer",
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "Q4 00:42"),
            importanceMetadata: importanceMetadata,
            headline: "Late scoring play",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: scoreBefore,
            scoreAfter: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: nil),
                    ParticipantScore(participantID: "away", participantRole: .away, score: nil)
                ]
            ),
            scoreDelta: scoreDelta,
            sportMetadata: [:]
        )
    }
}
