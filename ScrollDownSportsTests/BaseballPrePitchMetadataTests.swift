import XCTest
@testable import ScrollDownSports

final class BaseballPrePitchMetadataTests: XCTestCase {
    func testExplicitContainerNamesNormalizeGenericFields() {
        for containerKey in ["prePitch", "before", "situationBefore", "stateBefore"] {
            let state = prePitchState(
                metadata: [
                    containerKey: .object([
                        "baseState": .string("bases_loaded"),
                        "outs": .number(2),
                        "count": .object([
                            "balls": .number(3),
                            "strikes": .number(2)
                        ])
                    ])
                ]
            )

            XCTAssertEqual(state.baseState?.occupiedBases, [.first, .second, .third], containerKey)
            XCTAssertEqual(state.outs, 2, containerKey)
            XCTAssertEqual(state.count?.label, "3-2", containerKey)
            XCTAssertEqual(state.sourceConfidence, .explicitPrePitch, containerKey)
            XCTAssertTrue(state.sourceConfidence.allowsSportDiagram, containerKey)
        }
    }

    func testExplicitTopLevelBeforeKeysNormalizeStateAndCount() {
        let state = prePitchState(
            metadata: [
                "basesBefore": .string("runners_on_corners"),
                "outsBefore": .string("two outs"),
                "ballsBefore": .number(1),
                "strikesBefore": .number(2)
            ]
        )
        let textCountState = prePitchState(
            metadata: [
                "baseStateBefore": .string("runner_on_second"),
                "countBefore": .string("full count")
            ]
        )

        XCTAssertEqual(state.baseState?.occupiedBases, [.first, .third])
        XCTAssertEqual(state.outs, 2)
        XCTAssertEqual(state.count?.label, "1-2")
        XCTAssertEqual(state.sourceConfidence, .explicitPrePitch)
        XCTAssertEqual(textCountState.baseState?.occupiedBases, [.second])
        XCTAssertEqual(textCountState.count?.label, "3-2")
    }

    func testGenericMetadataRequiresPreEventTiming() {
        let timedState = prePitchState(
            metadata: [
                "timing": .string("pre_pitch"),
                "baseState": .string("runner_on_first"),
                "outs": .number(1),
                "count": .string("2-1")
            ]
        )
        let ambiguousState = prePitchState(
            metadata: [
                "baseState": .string("runner_on_first"),
                "outs": .number(1),
                "count": .string("2-1")
            ]
        )

        XCTAssertEqual(timedState.baseState?.occupiedBases, [.first])
        XCTAssertEqual(timedState.outs, 1)
        XCTAssertEqual(timedState.count?.label, "2-1")
        XCTAssertEqual(timedState.sourceConfidence, .explicitGeneric)
        XCTAssertTrue(timedState.sourceConfidence.allowsSportDiagram)
        XCTAssertNil(ambiguousState.baseState)
        XCTAssertNil(ambiguousState.outs)
        XCTAssertNil(ambiguousState.count)
        XCTAssertEqual(ambiguousState.sourceConfidence, .ambiguousResultMetadata)
        XCTAssertFalse(ambiguousState.sourceConfidence.allowsSportDiagram)
    }

    func testPartialOutsOrCountOnlyMetadataDoesNotCreateDiamond() {
        let renderer = BaseballRenderer()
        let outsOnly = event(
            sequence: 41,
            metadata: ["outsBefore": .number(1)]
        )
        let countOnly = event(
            sequence: 42,
            metadata: [
                "ballsBefore": .number(2),
                "strikesBefore": .number(0)
            ]
        )

        let outsOnlyState = renderer.baseballPrePitchState(for: outsOnly)
        let countOnlyState = renderer.baseballPrePitchState(for: countOnly)
        let outsOnlySituation = renderer.eventSituationPresentation(
            for: outsOnly,
            context: situationContext(for: outsOnly)
        )
        let countOnlySituation = renderer.eventSituationPresentation(
            for: countOnly,
            context: situationContext(for: countOnly)
        )

        XCTAssertNil(outsOnlyState.baseState)
        XCTAssertEqual(outsOnlyState.outs, 1)
        XCTAssertNil(countOnlyState.baseState)
        XCTAssertEqual(countOnlyState.count?.label, "2-0")
        if case .baseballDiamond = outsOnlySituation?.diagram {
            XCTFail("Outs-only metadata must not render a baseball diamond")
        }
        if case .baseballDiamond = countOnlySituation?.diagram {
            XCTFail("Count-only metadata must not render a baseball diamond")
        }
    }

    func testEmptyBasesAreKnownOnlyWithExplicitPreEventSource() {
        let renderer = BaseballRenderer()
        let explicitEvent = event(
            sequence: 43,
            metadata: ["baseStateBefore": .string("bases_empty")]
        )
        let ambiguousEvent = event(
            sequence: 44,
            metadata: ["baseState": .string("bases_empty")]
        )

        let explicitState = renderer.baseballPrePitchState(for: explicitEvent)
        let ambiguousState = renderer.baseballPrePitchState(for: ambiguousEvent)
        let explicitSituation = renderer.eventSituationPresentation(
            for: explicitEvent,
            context: situationContext(for: explicitEvent)
        )

        XCTAssertEqual(explicitState.baseState?.occupiedBases, [])
        XCTAssertEqual(explicitState.baseState?.label, "Bases empty")
        if case .baseballDiamond(let diagram) = explicitSituation?.diagram {
            XCTAssertEqual(diagram.occupiedBases, [])
        } else {
            XCTFail("Explicit empty bases should render a known empty-base diamond")
        }
        XCTAssertNil(ambiguousState.baseState)
        XCTAssertEqual(ambiguousState.sourceConfidence, .ambiguousResultMetadata)
    }

    func testBaseValueShapesAndInvalidValuesNormalizeHonestly() {
        let arrayState = prePitchState(
            metadata: ["occupiedBasesBefore": .array([.string("1B"), .number(2), .string("third")])]
        )
        let maskState = prePitchState(
            metadata: ["baseMaskBefore": .number(5)]
        )
        let objectState = prePitchState(
            metadata: [
                "stateBefore": .object([
                    "bases": .object([
                        "first": .bool(true),
                        "second": .bool(false),
                        "third": .number(1)
                    ])
                ])
            ]
        )
        let invalidState = prePitchState(
            metadata: [
                "prePitch": .object([
                    "occupiedBases": .array([.string("first"), .string("home")]),
                    "baseMask": .number(8),
                    "outs": .number(3),
                    "balls": .number(4),
                    "strikes": .number(1)
                ])
            ]
        )

        XCTAssertEqual(arrayState.baseState?.occupiedBases, [.first, .second, .third])
        XCTAssertEqual(maskState.baseState?.occupiedBases, [.first, .third])
        XCTAssertEqual(objectState.baseState?.occupiedBases, [.first, .third])
        XCTAssertNil(invalidState.baseState)
        XCTAssertNil(invalidState.outs)
        XCTAssertNil(invalidState.count)
        XCTAssertEqual(invalidState.sourceConfidence, .derivedFromPeriod)
    }

    func testFirstClassStateRejectsInvalidOutsAndUnknownBases() {
        let unknownState = firstClassState(
            baseball: GameEventBaseballSituation(
                inning: nil,
                half: nil,
                outs: 3,
                balls: nil,
                strikes: nil,
                bases: GameEventBaseballBases(first: nil, second: nil, third: nil),
                baseState: nil,
                battingTeamAbbreviation: nil,
                fieldingTeamAbbreviation: nil,
                batterName: nil,
                pitcherName: nil
            )
        )
        let emptyBasesState = firstClassState(
            baseball: GameEventBaseballSituation(
                inning: nil,
                half: nil,
                outs: 2,
                balls: nil,
                strikes: nil,
                bases: GameEventBaseballBases(first: false, second: false, third: false),
                baseState: nil,
                battingTeamAbbreviation: nil,
                fieldingTeamAbbreviation: nil,
                batterName: nil,
                pitcherName: nil
            )
        )

        XCTAssertNil(unknownState.baseState)
        XCTAssertNil(unknownState.outs)
        XCTAssertEqual(unknownState.sourceConfidence, .missing)
        XCTAssertEqual(emptyBasesState.baseState?.occupiedBases, [])
        XCTAssertEqual(emptyBasesState.outs, 2)
        XCTAssertEqual(emptyBasesState.sourceConfidence, .explicitPrePitch)
    }

    private func prePitchState(metadata: [String: JSONValue]) -> BaseballPrePitchState {
        BaseballRenderer().baseballPrePitchState(
            for: event(sequence: 40, metadata: metadata)
        )
    }

    private func event(sequence: Int, metadata: [String: JSONValue]) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            importance: .primary,
            periodLabel: "T8",
            clockLabel: "1 out",
            eventType: "Single",
            sportMetadata: metadata
        )
    }

    private func situationContext(for event: GameEvent) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(leagueCode: "mlb"),
            selectedMode: .full,
            visibleEvents: [event],
            eventIndex: 0
        )
    }

    private func firstClassState(baseball: GameEventBaseballSituation) -> BaseballPrePitchState {
        BaseballRenderer().firstClassBaseballPrePitchState(
            from: GameEventSituationSnapshot(
                schemaVersion: 1,
                sport: "mlb",
                display: nil,
                score: nil,
                period: nil,
                clock: nil,
                possession: nil,
                sportState: GameEventSituationSportState(
                    baseball: baseball,
                    football: nil,
                    hockey: nil,
                    basketball: nil,
                    soccer: nil,
                    golf: nil,
                    tennis: nil
                ),
                pressure: nil,
                confidence: GameEventSituationConfidence(
                    level: "verified",
                    source: nil,
                    reasons: []
                )
            )
        )
    }
}
