import XCTest
@testable import ScrollDownSports

@MainActor
final class SituationPresentationInvariantTests: XCTestCase {
    func testBaseballEventsUseSituationContextWithoutRepeatingPlayerName() {
        let event = TestFixtures.makeEvent(
            sequence: 1,
            importance: .primary,
            headline: "Jeff McNeil walks.",
            detail: "Jeff McNeil",
            clockLabel: "8th",
            eventType: "Walk",
            presentation: TestFixtures.eventPresentation(timeLabel: "8th"),
            importanceMetadata: EventImportanceData(
                level: "secondary",
                rank: 40,
                bucket: "base_runner",
                reasons: ["runner aboard"],
                isKeyMoment: false,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            sportMetadata: [
                "baseStateBefore": .string("runner_on_first"),
                "outsBefore": .number(1),
                "ballsBefore": .number(3),
                "strikesBefore": .number(1)
            ]
        )
        let context = situationContext(for: event, selectedMode: .key)

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "8th", context: context)

        XCTAssertNil(presentation.detail)
        XCTAssertEqual(presentation.situation?.title, "Situation")
        XCTAssertEqual(presentation.situation?.setupText, "Runner on 1st · 1 out · 3-1 count")
        XCTAssertNil(presentation.situation?.contextLine)
        XCTAssertNil(presentation.situation?.pressureLine)
        XCTAssertEqual(presentation.situation?.sport, .baseball)
        XCTAssertEqual(presentation.situation?.layout, .baseball)
        XCTAssertEqual(presentation.situation?.accent.ownership, .home)
        XCTAssertEqual(presentation.situation?.accent.teamAbbreviation, "SEA")
        XCTAssertEqual(presentation.situation?.ownership?.role, .association)
        XCTAssertEqual(presentation.situation?.ownership?.confidence, .eventFallback)
        XCTAssertEqual(presentation.situation?.ownership?.displayLabel, "Team SEA")
        if case .baseballDiamond(let diagram) = presentation.situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.first])
            XCTAssertEqual(diagram.batting?.participantRole, .home)
        } else {
            XCTFail("Expected a baseball diamond situation diagram")
        }
        XCTAssertEqual(presentation.situation?.dataConfidence, .explicitPreEvent)
        XCTAssertFalse(presentation.detail?.contains("Jeff McNeil") == true)
    }

    func testBaseballEventsPreserveNonDuplicateDetailAndSeparateSituationContext() {
        let event = TestFixtures.makeEvent(
            sequence: 2,
            headline: "Shea Langeliers strikes out swinging.",
            detail: "Leaves two aboard",
            clockLabel: "2 outs",
            eventType: "Strikeout",
            sportMetadata: [
                "baseStateBefore": .string("runners_on_second_and_third"),
                "outsBefore": .number(2),
                "countBefore": .string("1-2")
            ]
        )
        let context = situationContext(for: event, selectedMode: .full)

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "9th", context: context)

        XCTAssertEqual(presentation.detail, "Leaves two aboard")
        XCTAssertEqual(presentation.situation?.setupText, "Runners on 2nd and 3rd · 2 outs · 1-2 count")
    }

    func testAmbiguousBaseballBaseStateUsesPressureBoardInsteadOfDiamond() {
        let event = TestFixtures.makeEvent(
            sequence: 22,
            importance: .primary,
            headline: "Julio Rodriguez doubles.",
            clockLabel: "T8 1 out",
            eventType: "Double",
            importanceMetadata: EventImportanceData(
                level: "secondary",
                rank: 55,
                bucket: "base_runner",
                reasons: ["runner aboard"],
                isKeyMoment: true,
                isScoringPlay: false,
                isLeadChange: false,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            sportMetadata: [
                "baseState": .string("runner_on_second")
            ]
        )
        let context = situationContext(for: event, selectedMode: .flow)

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "T8", context: context)

        XCTAssertEqual(presentation.situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(presentation.situation?.dataConfidence, .ambiguousMetadata)
        if case .baseballDiamond = presentation.situation?.diagram {
            XCTFail("Ambiguous baseState should not produce an occupied-base diagram")
        }
    }

    func testBaseballPrePitchNormalizerPrefersExplicitContainerOverGenericMetadata() {
        let event = TestFixtures.makeEvent(
            sequence: 23,
            periodLabel: "T4",
            sportMetadata: [
                "baseState": .string("runner_on_first"),
                "outs": .number(3),
                "count": .string("4-2"),
                "prePitch": .object([
                    "baseState": .string("bases_loaded"),
                    "outs": .number(2),
                    "count": .object([
                        "balls": .number(3),
                        "strikes": .number(2)
                    ])
                ])
            ]
        )

        let state = BaseballRenderer().baseballPrePitchState(for: event)

        XCTAssertEqual(state.baseState?.occupiedBases, [.first, .second, .third])
        XCTAssertEqual(state.baseState?.label, "Bases loaded")
        XCTAssertEqual(state.outs, 2)
        XCTAssertEqual(state.count?.label, "3-2")
        XCTAssertEqual(state.inning, 4)
        XCTAssertEqual(state.inningHalf, .top)
        XCTAssertEqual(state.sourceConfidence, .explicitPrePitch)
    }

    func testBaseballPrePitchNormalizerSupportsStructuredBaseFormsAndCompactCodes() {
        let objectEvent = TestFixtures.makeEvent(
            sequence: 24,
            sportMetadata: [
                "situationBefore": .object([
                    "bases": .object([
                        "first": .bool(true),
                        "second": .bool(false),
                        "third": .number(1)
                    ]),
                    "outs": .string("one out"),
                    "count": .string("full count"),
                    "inningLabel": .string("Bottom 9")
                ])
            ]
        )
        let arrayEvent = TestFixtures.makeEvent(
            sequence: 25,
            sportMetadata: [
                "before": .object([
                    "occupiedBases": .array([.string("1B"), .number(2)]),
                    "baseMask": .number(5)
                ])
            ]
        )

        let objectState = BaseballRenderer().baseballPrePitchState(for: objectEvent)
        let arrayState = BaseballRenderer().baseballPrePitchState(for: arrayEvent)

        XCTAssertEqual(objectState.baseState?.occupiedBases, [.first, .third])
        XCTAssertEqual(objectState.outs, 1)
        XCTAssertEqual(objectState.count?.label, "3-2")
        XCTAssertEqual(objectState.inning, 9)
        XCTAssertEqual(objectState.inningHalf, .bottom)
        XCTAssertEqual(arrayState.baseState?.occupiedBases, [.first, .second])
    }

    func testBaseballPrePitchNormalizerRejectsInvalidFieldsWithoutFabricatingCountOrBases() {
        let event = TestFixtures.makeEvent(
            sequence: 26,
            periodLabel: "B8",
            sportMetadata: [
                "prePitch": .object([
                    "baseState": .string("space_station"),
                    "outs": .number(3),
                    "balls": .number(4),
                    "strikes": .number(1)
                ])
            ]
        )

        let state = BaseballRenderer().baseballPrePitchState(for: event)

        XCTAssertNil(state.baseState)
        XCTAssertNil(state.outs)
        XCTAssertNil(state.count)
        XCTAssertEqual(state.inning, 8)
        XCTAssertEqual(state.inningHalf, .bottom)
        XCTAssertEqual(state.sourceConfidence, .derivedFromPeriod)
    }

    func testBaseballSituationIncludesPressureAndScoreContextWhenAvailable() {
        let event = GameEvent(
            id: "event-score-context",
            sourceEventID: "event-score-context",
            sequence: 3,
            periodOrdinal: 4,
            periodLabel: "T9",
            clockLabel: "1 out",
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: "Double",
            importance: .primary,
            eligibleModes: [.timeline, .flow, .stream],
            usesBackendModeEligibility: true,
            presentation: TestFixtures.eventPresentation(timeLabel: "9th"),
            importanceMetadata: EventImportanceData(
                level: "primary",
                rank: 95,
                bucket: "scoring",
                reasons: ["late_game"],
                isKeyMoment: true,
                isScoringPlay: true,
                isLeadChange: true,
                isTyingPlay: false,
                winProbabilityDelta: nil
            ),
            headline: "Julio Rodriguez doubles in the go-ahead run.",
            detail: "Line drive to right",
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 1),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 1)
                ]
            ),
            scoreAfter: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: 2),
                    ParticipantScore(participantID: "away", participantRole: .away, score: 1)
                ]
            ),
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 1, after: 2, change: 1),
            sportMetadata: [
                "baseState": .string("bases_empty"),
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1)
            ]
        )
        let context = situationContext(for: event, selectedMode: .key)

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "9th", context: context)

        XCTAssertEqual(presentation.detail, "Line drive to right")
        XCTAssertEqual(presentation.situation?.periodText, "T9 1 out")
        XCTAssertEqual(presentation.situation?.setupText, "Runner on 2nd · 1 out")
        XCTAssertEqual(presentation.situation?.contextLine, "Tied -> Up 1")
        XCTAssertEqual(presentation.situation?.pressureLine, "Lead change")
        XCTAssertEqual(presentation.situation?.accent.tone, .critical)
        if case .baseballDiamond(let diagram) = presentation.situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.second])
        } else {
            XCTFail("Expected explicit pre-state bases before the scoring result")
        }
    }

    func testBaseballSituationDerivesBattingSideFromInningHalfWithTeamLabel() {
        let game = TestFixtures.makeGame(
            id: 1801,
            leagueCode: "mlb",
            awayName: "New York Yankees",
            awayAbbreviation: "NYY",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA"
        )
        let event = TestFixtures.makeEvent(
            sequence: 5,
            periodLabel: "T8",
            clockLabel: "2 outs",
            eventType: "Single",
            sportMetadata: [
                "baseStateBefore": .string("runners_on_corners")
            ]
        )
        let context = SportRendererSituationContext(
            game: game,
            selectedMode: .full,
            visibleEvents: [event],
            eventIndex: 0
        )

        let situation = BaseballRenderer().eventSituationPresentation(for: event, context: context)

        XCTAssertEqual(situation?.ownership?.role, .batting)
        XCTAssertEqual(situation?.ownership?.participantRole, .away)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "NYY")
        XCTAssertEqual(situation?.ownership?.teamLabel, "New York Yankees")
        XCTAssertEqual(situation?.ownership?.confidence, .derivedFromPeriod)
        XCTAssertEqual(situation?.accent.ownership, .away)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "NYY")
        if case .baseballDiamond(let diagram) = situation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [.first, .third])
            XCTAssertEqual(diagram.batting?.displayLabel, "Batting NYY")
        } else {
            XCTFail("Expected a baseball diamond situation diagram")
        }
    }

    func testBaseballSituationUsesExplicitBattingMetadataBeforeInningFallback() {
        let game = TestFixtures.makeGame(
            id: 1802,
            leagueCode: "mlb",
            awayAbbreviation: "NYY",
            homeAbbreviation: "SEA"
        )
        let event = TestFixtures.makeEvent(
            sequence: 6,
            periodLabel: "T8",
            eventType: "Double",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "battingTeamAbbreviation": .string("SEA")
            ]
        )
        let context = SportRendererSituationContext(
            game: game,
            selectedMode: .full,
            visibleEvents: [event],
            eventIndex: 0
        )

        let situation = BaseballRenderer().eventSituationPresentation(for: event, context: context)

        XCTAssertEqual(situation?.ownership?.participantRole, .home)
        XCTAssertEqual(situation?.ownership?.teamAbbreviation, "SEA")
        XCTAssertEqual(situation?.ownership?.confidence, .explicit)
        XCTAssertEqual(situation?.accent.ownership, .home)
        XCTAssertEqual(situation?.accent.teamAbbreviation, "SEA")
    }

    func testFallbackAssociationDoesNotClaimPossession() {
        let association = GameEventSituationOwnership(
            role: .association,
            participantRole: .away,
            teamAbbreviation: "ARC",
            teamLabel: "Arc City",
            confidence: .eventFallback
        )
        let diagram = PressureBoardSituationDiagram(associations: [association])

        XCTAssertFalse(association.claimsPossession)
        XCTAssertEqual(association.displayLabel, "Team ARC")
        XCTAssertEqual(diagram.associations.first?.claimsPossession, false)
    }

    func testReservedSportRenderersDoNotInventSituationPresentation() {
        let event = TestFixtures.makeEvent(sequence: 4, eventType: "Touchdown")

        XCTAssertNil(FootballRenderer(leagueCode: "nfl").eventPresentation(for: event).situation)
        XCTAssertNil(BasketballRenderer(leagueCode: "nba").eventPresentation(for: event).situation)
        XCTAssertNil(SoccerRenderer(leagueCode: "mls").eventPresentation(for: event).situation)
    }

    func testSituationPresentationRequiresVisibleStreamContext() {
        let event = TestFixtures.makeEvent(
            sequence: 7,
            importance: .primary,
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second")
            ]
        )
        let hiddenContext = situationContext(for: event, selectedMode: .key, visibleEvents: [])

        XCTAssertNil(BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "T8").situation)
        XCTAssertNil(BaseballRenderer().eventSituationPresentation(for: event, context: hiddenContext))
    }

    func testKeyBaseballSituationAppearsInEveryModeWhereEventIsVisible() {
        let event = TestFixtures.makeEvent(
            sequence: 8,
            importance: .primary,
            headline: "Cal Raleigh doubles in the gap.",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1)
            ]
        )
        let renderer = BaseballRenderer()

        let key = renderer.eventPresentation(
            for: event,
            periodGroupLabel: "T8",
            context: situationContext(for: event, selectedMode: .key)
        )
        let flow = renderer.eventPresentation(
            for: event,
            periodGroupLabel: "T8",
            context: situationContext(for: event, selectedMode: .flow)
        )
        let full = renderer.eventPresentation(
            for: event,
            periodGroupLabel: "T8",
            context: situationContext(for: event, selectedMode: .full)
        )

        XCTAssertEqual(key.situation?.layout, .baseball)
        XCTAssertEqual(flow.situation?.layout, .baseball)
        XCTAssertEqual(full.situation?.layout, .baseball)
    }

    func testRoutineVisibleBaseballPlayDoesNotReceiveCardFromPartialMetadata() {
        let event = TestFixtures.makeEvent(
            sequence: 9,
            importance: .contextual,
            headline: "Routine groundout.",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_first"),
                "outsBefore": .number(0)
            ]
        )
        let context = situationContext(for: event, selectedMode: .full)

        let presentation = BaseballRenderer().eventPresentation(for: event, periodGroupLabel: "T3", context: context)

        XCTAssertNil(presentation.situation)
    }

    func testAdjacentRepeatedThreatSituationIsSuppressedForDensity() {
        let first = TestFixtures.makeEvent(
            sequence: 10,
            importance: .contextual,
            headline: "Single puts two aboard.",
            sportMetadata: [
                "baseStateBefore": .string("runners_on_second_and_third"),
                "outsBefore": .number(1)
            ]
        )
        let second = TestFixtures.makeEvent(
            sequence: 11,
            importance: .contextual,
            headline: "Foul ball.",
            sportMetadata: [
                "baseStateBefore": .string("runners_on_second_and_third"),
                "outsBefore": .number(1)
            ]
        )
        let visibleEvents = [first, second]
        let renderer = BaseballRenderer()

        let firstSituation = renderer.eventSituationPresentation(
            for: first,
            context: situationContext(for: first, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 0)
        )
        let secondSituation = renderer.eventSituationPresentation(
            for: second,
            context: situationContext(for: second, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 1)
        )

        XCTAssertEqual(firstSituation?.layout, .baseball)
        XCTAssertNil(secondSituation)
    }

    private func situationContext(
        for event: GameEvent,
        selectedMode: DetailStreamMode,
        visibleEvents: [GameEvent]? = nil,
        eventIndex: Int = 0
    ) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(leagueCode: "mlb"),
            selectedMode: selectedMode,
            visibleEvents: visibleEvents ?? [event],
            eventIndex: eventIndex
        )
    }
}
