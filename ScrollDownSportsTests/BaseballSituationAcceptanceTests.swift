import XCTest
@testable import ScrollDownSports

@MainActor
final class BaseballSituationAcceptanceTests: XCTestCase {
    func testWalkWithRunnersUsesExplicitPreStateDiamondAndDropsDuplicateDetail() {
        let presentation = render(Self.walkEvent())

        XCTAssertNil(presentation.detail)
        XCTAssertEqual(presentation.situation?.title, "Situation")
        XCTAssertEqual(presentation.situation?.setupText, "Runners on 1st and 2nd · 1 out · 3-1 count")
        XCTAssertNil(presentation.situation?.contextLine)
        XCTAssertNil(presentation.situation?.pressureLine)
        XCTAssertEqual(presentation.situation?.layout, .baseball)
        XCTAssertEqual(presentation.situation?.sport, .baseball)
        XCTAssertEqual(presentation.situation?.dataConfidence, .explicitPreEvent)
        XCTAssertEqual(presentation.situation?.ownership?.role, .batting)
        XCTAssertEqual(presentation.situation?.ownership?.teamAbbreviation, "BAY")
        XCTAssertEqual(presentation.situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(presentation.situation?.accent.ownership, .home)
        XCTAssertEqual(presentation.situation?.accent.teamAbbreviation, "BAY")
        assertDiamond(presentation.situation, bases: [.first, .second], outs: 1, count: "3-1", batting: .home)
        XCTAssertFalse(presentation.detail?.contains("Nico Vale") == true)
    }

    func testStrikeoutThreatPreservesDetailAndShowsPrePitchThreat() {
        let presentation = render(Self.strikeoutThreatEvent())

        XCTAssertEqual(presentation.detail, "Leaves two in scoring position")
        XCTAssertEqual(presentation.situation?.setupText, "Runners on 2nd and 3rd · 2 outs · 1-2 count")
        XCTAssertEqual(presentation.situation?.pressureLine, "Runner in scoring position")
        XCTAssertEqual(presentation.situation?.layout, .baseball)
        XCTAssertEqual(presentation.situation?.dataConfidence, .explicitPreEvent)
        XCTAssertEqual(presentation.situation?.ownership?.role, .batting)
        XCTAssertEqual(presentation.situation?.ownership?.teamAbbreviation, "RIV")
        XCTAssertEqual(presentation.situation?.accent.ownership, .away)
        assertDiamond(presentation.situation, bases: [.second, .third], outs: 2, count: "1-2", batting: .away)
    }

    func testScoringHitUsesPreStateAndScorePressure() {
        let presentation = render(Self.scoringHitEvent())

        XCTAssertEqual(presentation.detail, "Grounder through the left side")
        XCTAssertEqual(presentation.situation?.setupText, "Runner on 2nd · 1 out · 2-1 count")
        XCTAssertEqual(presentation.situation?.contextLine, "Tied -> Up 1")
        XCTAssertEqual(presentation.situation?.pressureLine, "Lead change")
        XCTAssertEqual(presentation.situation?.accent.tone, .critical)
        XCTAssertEqual(presentation.situation?.dataConfidence, .explicitPreEvent)
        XCTAssertEqual(presentation.situation?.layout, .baseball)
        assertDiamond(presentation.situation, bases: [.second], outs: 1, count: "2-1", batting: .home)
        XCTAssertNotEqual(presentation.situation?.setupText, "Bases empty · 1 out · 2-1 count")
    }

    func testImportantGroundoutWithRunnersAboardCanRenderExplicitPreState() {
        let presentation = render(Self.groundoutEvent())

        XCTAssertEqual(presentation.situation?.setupText, "Runners on 1st and 3rd · 1 out · 0-2 count")
        XCTAssertEqual(presentation.situation?.layout, .baseball)
        XCTAssertEqual(presentation.situation?.dataConfidence, .explicitPreEvent)
        assertDiamond(presentation.situation, bases: [.first, .third], outs: 1, count: "0-2", batting: .home)
    }

    func testMissingBaseDataDoesNotInventBaseballDiamond() throws {
        let presentation = render(Self.missingBaseDataEvent())
        let situation = try XCTUnwrap(presentation.situation)

        XCTAssertEqual(situation.layout, .pressureBoardFallback)
        XCTAssertEqual(situation.dataConfidence, .ambiguousMetadata)
        XCTAssertNotEqual(situation.dataConfidence, .explicitPreEvent)
        if case .baseballDiamond = situation.diagram {
            XCTFail("Missing base data should not produce an occupied-base diamond")
        }
    }

    func testSituationRendersOnlyInModesWhereEventIsVisible() {
        let event = Self.walkEvent()

        XCTAssertTrue(DetailStreamMode.key.visibleEvents(in: [event]).isEmpty)
        XCTAssertNil(render(event, mode: .key).situation)
        XCTAssertEqual(render(event, mode: .flow).situation?.layout, .baseball)
        XCTAssertEqual(render(event, mode: .full).situation?.layout, .baseball)
    }

    func testDecodedFixtureEventsMatchHandBuiltRendererOutcomes() throws {
        let detail = try Self.acceptanceDetail()
        let eventsByID = Dictionary(uniqueKeysWithValues: detail.events.compactMap { event in
            event.sourceEventID.map { ($0, event) }
        })

        for handBuiltEvent in Self.handBuiltEvents {
            let decodedEvent = try XCTUnwrap(eventsByID[handBuiltEvent.sourceEventID ?? handBuiltEvent.id])
            XCTAssertEqual(
                Self.signature(for: render(decodedEvent, game: detail.game)),
                Self.signature(for: render(handBuiltEvent)),
                handBuiltEvent.id
            )
        }
    }

    private static var handBuiltEvents: [GameEvent] {
        [
            walkEvent(),
            strikeoutThreatEvent(),
            scoringHitEvent(),
            groundoutEvent(),
            missingBaseDataEvent()
        ]
    }

    private static func acceptanceDetail() throws -> GameDetail {
        let response = try JSONDecoder.sda.decode(
            SDAGameDetailResponseDTO.self,
            from: try SDAFixtures.gameDetail("mlb_situation_acceptance_events")
        )
        return SDADomainMapper.detail(from: response)
    }

    private func render(
        _ event: GameEvent,
        game: Game? = nil,
        mode: DetailStreamMode = .full
    ) -> GameEventPresentation {
        let visibleEvents = mode.visibleEvents(in: [event])
        let context = SportRendererSituationContext(
            game: game ?? Self.acceptanceGame(),
            selectedMode: mode,
            visibleEvents: visibleEvents,
            eventIndex: 0
        )
        return BaseballRenderer().eventPresentation(for: event, periodGroupLabel: event.periodLabel, context: context)
    }

    private func assertDiamond(
        _ situation: GameEventSituationPresentation?,
        bases: Set<BaseballBase>,
        outs: Int?,
        count: String?,
        batting: GameParticipantRole,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if case .baseballDiamond(let diagram) = situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, bases, file: file, line: line)
            XCTAssertEqual(diagram.outs, outs, file: file, line: line)
            XCTAssertEqual(diagram.count, count, file: file, line: line)
            XCTAssertEqual(diagram.batting?.participantRole, batting, file: file, line: line)
        } else {
            XCTFail("Expected a baseball diamond situation diagram", file: file, line: line)
        }
    }

    private static func signature(for presentation: GameEventPresentation) -> RenderedSituation {
        let situation = presentation.situation
        let diagram = situation?.diagram
        let diamond: BaseballSituationDiagram?
        if case .baseballDiamond(let value) = diagram {
            diamond = value
        } else {
            diamond = nil
        }
        return RenderedSituation(
            detail: presentation.detail,
            setupText: situation?.setupText,
            contextLine: situation?.contextLine,
            pressureLine: situation?.pressureLine,
            sport: situation?.sport,
            layout: situation?.layout,
            dataConfidence: situation?.dataConfidence,
            ownershipRole: situation?.ownership?.role,
            ownershipTeam: situation?.ownership?.teamAbbreviation,
            ownershipConfidence: situation?.ownership?.confidence,
            accentOwnership: situation?.accent.ownership,
            accentTeam: situation?.accent.teamAbbreviation,
            accentTone: situation?.accent.tone,
            bases: diamond?.occupiedBases,
            outs: diamond?.outs,
            count: diamond?.count,
            batting: diamond?.batting?.participantRole
        )
    }

    private static func acceptanceGame() -> Game {
        TestFixtures.makeGame(
            id: 1904,
            leagueCode: "mlb",
            awayName: "River City",
            awayAbbreviation: "RIV",
            homeName: "Bay Harbor",
            homeAbbreviation: "BAY",
            awayScore: 3,
            homeScore: 4,
            periodOrdinal: 8,
            periodLabel: "B8",
            clockLabel: "1 out"
        )
    }

    private static func walkEvent() -> GameEvent {
        event(
            id: "situation-1904-001",
            sequence: 1,
            periodOrdinal: 7,
            periodLabel: "B7",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "BAY",
            eventType: "Walk",
            importance: .secondary,
            eligibleModes: [.flow, .stream],
            headline: "Nico Vale walks.",
            detail: "Nico Vale",
            scoreBefore: nil,
            scoreAfter: scoreState(away: 3, home: 3),
            importanceMetadata: EventImportanceData(
                level: "secondary",
                rank: 48,
                bucket: "base_runner",
                reasons: ["runner aboard", "walk"],
                isKeyMoment: false,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: 0.05
            ),
            sportMetadata: [
                "baseStateBefore": .string("runners_on_first_and_second"),
                "outsBefore": .number(1),
                "ballsBefore": .number(3),
                "strikesBefore": .number(1),
                "battingTeamAbbreviation": .string("BAY")
            ]
        )
    }

    private static func strikeoutThreatEvent() -> GameEvent {
        event(
            id: "situation-1904-002",
            sequence: 2,
            periodOrdinal: 9,
            periodLabel: "T9",
            clockLabel: "2 outs",
            teamOwnership: .away,
            teamAbbreviation: "RIV",
            eventType: "Strikeout",
            importance: .primary,
            headline: "Oren Pike strikes out swinging.",
            detail: "Leaves two in scoring position",
            scoreBefore: scoreState(away: 3, home: 4),
            scoreAfter: scoreState(away: 3, home: 4),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 72,
                bucket: "threat_ended",
                reasons: ["runners in scoring position", "late inning", "two outs"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: 0.12
            ),
            sportMetadata: [
                "baseStateBefore": .string("runners_on_second_and_third"),
                "outsBefore": .number(2),
                "countBefore": .string("1-2"),
                "battingTeamAbbreviation": .string("RIV")
            ]
        )
    }

    private static func scoringHitEvent() -> GameEvent {
        event(
            id: "situation-1904-003",
            sequence: 3,
            periodOrdinal: 8,
            periodLabel: "B8",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "BAY",
            eventType: "Single",
            importance: .primary,
            headline: "Mara Stone singles home the go-ahead run.",
            detail: "Grounder through the left side",
            scoreBefore: scoreState(away: 3, home: 3),
            scoreAfter: scoreState(away: 3, home: 4),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 3, after: 4, change: 1),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 94,
                bucket: "scoring_play",
                reasons: ["scoring play", "lead change"],
                isKeyMoment: true,
                isScoringPlay: true,
                isLeadChange: true,
                isTyingPlay: false,
                winProbabilityDelta: 0.18
            ),
            sportMetadata: [
                "baseState": .string("bases_empty"),
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1),
                "countBefore": .string("2-1"),
                "battingTeamAbbreviation": .string("BAY")
            ]
        )
    }

    private static func groundoutEvent() -> GameEvent {
        event(
            id: "situation-1904-004",
            sequence: 4,
            periodOrdinal: 8,
            periodLabel: "B8",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "BAY",
            eventType: "Groundout",
            importance: .primary,
            headline: "Iris Chen grounds out to first.",
            detail: nil,
            scoreBefore: scoreState(away: 3, home: 4),
            scoreAfter: scoreState(away: 3, home: 4),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 61,
                bucket: "runners_stranded",
                reasons: ["runner aboard", "late inning"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: 0.08
            ),
            sportMetadata: [
                "baseStateBefore": .string("runners_on_first_and_third"),
                "outsBefore": .number(1),
                "countBefore": .string("0-2"),
                "battingTeamAbbreviation": .string("BAY")
            ]
        )
    }

    private static func missingBaseDataEvent() -> GameEvent {
        event(
            id: "situation-1904-005",
            sequence: 5,
            periodOrdinal: 6,
            periodLabel: "B6",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "BAY",
            eventType: "Strikeout",
            importance: .primary,
            headline: "Lane Moss strikes out looking.",
            detail: nil,
            scoreBefore: scoreState(away: 2, home: 2),
            scoreAfter: scoreState(away: 2, home: 2),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 58,
                bucket: "unclear_base_state",
                reasons: ["late inning"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: 0.06
            ),
            sportMetadata: [
                "outs": .number(1)
            ]
        )
    }

    private static func event(
        id: String,
        sequence: Int,
        periodOrdinal: Int,
        periodLabel: String,
        clockLabel: String,
        teamOwnership: GameParticipantRole,
        teamAbbreviation: String,
        eventType: String,
        importance: GameEventImportance,
        eligibleModes: Set<GameMode> = [.timeline, .flow, .stream],
        headline: String,
        detail: String?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        scoreDelta: ScoreDelta? = nil,
        importanceMetadata: EventImportanceData,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        GameEvent(
            id: id,
            sourceEventID: id,
            sequence: sequence,
            periodOrdinal: periodOrdinal,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            teamOwnership: teamOwnership,
            teamAbbreviation: teamAbbreviation,
            eventType: eventType,
            importance: importance,
            eligibleModes: eligibleModes,
            usesBackendModeEligibility: true,
            presentation: EventPresentationData(
                headline: nil,
                shortHeadline: nil,
                body: nil,
                primaryLabel: nil,
                secondaryLabel: nil,
                tertiaryLabel: nil,
                timeLabel: clockLabel,
                accessibilityLabel: nil,
                eventTypeLabel: eventType,
                teamLabel: nil,
                playerLabel: nil,
                scoreLabel: nil
            ),
            importanceMetadata: importanceMetadata,
            headline: headline,
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

    private static func scoreState(away: Int?, home: Int?) -> ScoreState {
        ScoreState(
            participantScores: [
                ParticipantScore(participantID: "away", participantRole: .away, score: away),
                ParticipantScore(participantID: "home", participantRole: .home, score: home)
            ]
        )
    }
}

private struct RenderedSituation: Equatable {
    let detail: String?
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: GameEventSituationSport?
    let layout: GameEventSituationLayout?
    let dataConfidence: GameEventSituationDataConfidence?
    let ownershipRole: GameEventSituationOwnershipRole?
    let ownershipTeam: String?
    let ownershipConfidence: GameEventSituationOwnershipConfidence?
    let accentOwnership: GameParticipantRole?
    let accentTeam: String?
    let accentTone: SportsTheme.Tone?
    let bases: Set<BaseballBase>?
    let outs: Int?
    let count: String?
    let batting: GameParticipantRole?
}
