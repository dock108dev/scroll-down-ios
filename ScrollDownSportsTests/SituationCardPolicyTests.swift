import XCTest
@testable import ScrollDownSports

@MainActor
final class SituationCardPolicyTests: XCTestCase {
    func testBaseballNamedEventFamiliesReceiveThreatCardsWhenPreStateQualifies() {
        let eventTypes = [
            "Walk",
            "Strikeout",
            "Single",
            "Double",
            "Triple",
            "Home Run",
            "Groundout",
            "Flyout"
        ]

        for (index, eventType) in eventTypes.enumerated() {
            let event = TestFixtures.makeEvent(
                sequence: index + 10,
                headline: "\(eventType) with a runner in scoring position.",
                eventType: eventType,
                sportMetadata: [
                    "baseStateBefore": .string("runner_on_second"),
                    "outsBefore": .number(1)
                ]
            )
            let situation = BaseballRenderer().eventSituationPresentation(
                for: event,
                context: situationContext(for: event, selectedMode: .full)
            )

            XCTAssertEqual(situation?.layout, .baseball, eventType)
        }
    }

    func testBaseballThreatCardsRequireNamedFamilyAndExplicitScoringPositionState() {
        let unlistedThreat = TestFixtures.makeEvent(
            sequence: 20,
            headline: "Foul ball with two aboard.",
            eventType: "Foul",
            sportMetadata: [
                "baseStateBefore": .string("runners_on_second_and_third"),
                "outsBefore": .number(1)
            ]
        )
        let ambiguousThreat = TestFixtures.makeEvent(
            sequence: 21,
            headline: "Line drive single.",
            eventType: "Single",
            sportMetadata: [
                "baseState": .string("runner_on_second")
            ]
        )
        let runnerOnFirst = TestFixtures.makeEvent(
            sequence: 22,
            headline: "Groundout moves the runner.",
            eventType: "Groundout",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_first"),
                "outsBefore": .number(0)
            ]
        )
        let runnerOnThird = TestFixtures.makeEvent(
            sequence: 23,
            headline: "Flyout with a runner ninety feet away.",
            eventType: "Flyout",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_third"),
                "outsBefore": .number(1)
            ]
        )

        XCTAssertNil(BaseballRenderer().eventSituationPresentation(
            for: unlistedThreat,
            context: situationContext(for: unlistedThreat, selectedMode: .full)
        ))
        XCTAssertNil(BaseballRenderer().eventSituationPresentation(
            for: ambiguousThreat,
            context: situationContext(for: ambiguousThreat, selectedMode: .full)
        ))
        XCTAssertNil(BaseballRenderer().eventSituationPresentation(
            for: runnerOnFirst,
            context: situationContext(for: runnerOnFirst, selectedMode: .full)
        ))
        XCTAssertEqual(BaseballRenderer().eventSituationPresentation(
            for: runnerOnThird,
            context: situationContext(for: runnerOnThird, selectedMode: .full)
        )?.layout, .baseball)
    }

    func testBaseballPriorityCardsBypassLowerPriorityThreatDensity() {
        let repeatedCases: [(String, EventImportanceData?)] = [
            ("critical", importance(level: "primary", rank: 95)),
            ("high", importance(level: nil, rank: 55)),
            ("scoring", importance(level: "tertiary", rank: 10, isScoringPlay: true)),
            ("key", importance(level: "tertiary", rank: 10, isKeyMoment: true))
        ]

        for (offset, repeatedCase) in repeatedCases.enumerated() {
            let first = TestFixtures.makeEvent(
                sequence: 30 + offset * 2,
                headline: "\(repeatedCase.0) double starts the pressure.",
                eventType: "Double",
                importanceMetadata: repeatedCase.1,
                sportMetadata: repeatedThreatMetadata
            )
            let second = TestFixtures.makeEvent(
                sequence: 31 + offset * 2,
                headline: "\(repeatedCase.0) double keeps the pressure on.",
                eventType: "Double",
                importanceMetadata: repeatedCase.1,
                sportMetadata: repeatedThreatMetadata
            )
            let visibleEvents = [first, second]

            XCTAssertNotNil(BaseballRenderer().eventSituationPresentation(
                for: first,
                context: situationContext(for: first, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 0)
            ), repeatedCase.0)
            XCTAssertNotNil(BaseballRenderer().eventSituationPresentation(
                for: second,
                context: situationContext(for: second, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 1)
            ), repeatedCase.0)
        }
    }

    func testBaseballScoreDeltaBypassesLowerPriorityThreatDensity() {
        let first = TestFixtures.makeEvent(
            sequence: 40,
            headline: "Single ties the game.",
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 1, after: 2, change: 1),
            eventType: "Single",
            importanceMetadata: importance(level: "tertiary", rank: 10),
            sportMetadata: repeatedThreatMetadata
        )
        let second = TestFixtures.makeEvent(
            sequence: 41,
            headline: "Single gives them the lead.",
            scoreDelta: ScoreDelta(participantID: "home", participantRole: .home, before: 2, after: 3, change: 1),
            eventType: "Single",
            importanceMetadata: importance(level: "tertiary", rank: 10),
            sportMetadata: repeatedThreatMetadata
        )
        let visibleEvents = [first, second]

        XCTAssertNotNil(BaseballRenderer().eventSituationPresentation(
            for: first,
            context: situationContext(for: first, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 0)
        ))
        XCTAssertNotNil(BaseballRenderer().eventSituationPresentation(
            for: second,
            context: situationContext(for: second, selectedMode: .full, visibleEvents: visibleEvents, eventIndex: 1)
        ))
    }

    func testBaseballTransitionEventsUseFallbackInsteadOfMisleadingDiamond() {
        let event = TestFixtures.makeEvent(
            sequence: 50,
            importance: .primary,
            headline: "End of inning.",
            eventType: "End of Inning",
            sportMetadata: [
                "baseStateBefore": .string("bases_loaded"),
                "outsBefore": .number(2)
            ]
        )

        let situation = BaseballRenderer().eventSituationPresentation(
            for: event,
            context: situationContext(for: event, selectedMode: .key)
        )

        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        if case .baseballDiamond = situation?.diagram {
            XCTFail("Inning transition events should not render a pre-pitch diamond")
        }
    }

    func testSituationPresentationSuppressesEventOutsideSelectedMode() {
        let event = TestFixtures.makeEvent(
            sequence: 1,
            importance: .contextual,
            headline: "Late threat begins.",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1)
            ]
        )
        let context = situationContext(for: event, selectedMode: .key, visibleEvents: [event])

        XCTAssertNil(BaseballRenderer().eventSituationPresentation(for: event, context: context))
    }

    func testSituationPresentationSuppressesMismatchedContextIndex() {
        let event = TestFixtures.makeEvent(
            sequence: 2,
            importance: .primary,
            headline: "Threatening swing.",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_second"),
                "outsBefore": .number(1)
            ]
        )
        let otherEvent = TestFixtures.makeEvent(
            sequence: 3,
            importance: .primary,
            headline: "Different visible event.",
            sportMetadata: [
                "baseStateBefore": .string("runner_on_third"),
                "outsBefore": .number(0)
            ]
        )
        let visibleEvents = [otherEvent, event]
        let mismatchedContext = situationContext(
            for: event,
            selectedMode: .key,
            visibleEvents: visibleEvents,
            eventIndex: 0
        )
        let matchingContext = situationContext(
            for: event,
            selectedMode: .key,
            visibleEvents: visibleEvents,
            eventIndex: 1
        )

        XCTAssertNil(BaseballRenderer().eventSituationPresentation(for: event, context: mismatchedContext))
        XCTAssertEqual(BaseballRenderer().eventSituationPresentation(for: event, context: matchingContext)?.layout, .baseball)
    }

    private var repeatedThreatMetadata: [String: JSONValue] {
        [
            "baseStateBefore": .string("runner_on_second"),
            "outsBefore": .number(1)
        ]
    }

    private func importance(
        level: String?,
        rank: Int?,
        isKeyMoment: Bool = false,
        isScoringPlay: Bool = false
    ) -> EventImportanceData {
        EventImportanceData(
            level: level,
            rank: rank,
            bucket: nil,
            reasons: [],
            isKeyMoment: isKeyMoment,
            isScoringPlay: isScoringPlay,
            isLeadChange: false,
            isTyingPlay: false,
            winProbabilityDelta: nil
        )
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
