import XCTest
@testable import ScrollDownSports

@MainActor
final class GolfTennisPressureBoardTests: XCTestCase {
    func testGolfLeaderboardMovementRendersAnalogPressureBoard() {
        let event = pressureEvent(
            sequence: 1,
            periodLabel: "Round 4",
            clockLabel: nil,
            eventType: "birdie",
            sportMetadata: [
                "hole": .number(17),
                "scoreToPar": .string("-11"),
                "rank": .string("T2"),
                "strokesBack": .string("1"),
                "leaderboardMovement": .string("Up 2")
            ]
        )

        let situation = GolfRenderer(leagueCode: "pga").eventSituationPresentation(for: event, context: context(for: event, leagueCode: "pga"))

        XCTAssertEqual(situation?.title, "Birdie pressure")
        XCTAssertEqual(situation?.sport, .golf)
        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.setupText, "Round 4 · Hole 17")
        XCTAssertEqual(situation?.contextLine, "Rank T2 · To par -11 · 1 back · Up 2")
        XCTAssertFalse(situation?.ownership?.claimsPossession == true)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected golf to render a non-field pressure board")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Hole", "Rank", "To par", "Back", "Move", "Play"])
        XCTAssertFalse(boardText(situation: situation, board: board).localizedCaseInsensitiveContains("course"))
    }

    func testGolfMissingLeaderboardStateUsesGenericFallback() {
        let event = pressureEvent(
            sequence: 2,
            periodLabel: "Round 2",
            clockLabel: "Hole 9",
            eventType: "approach",
            sportMetadata: [
                "lie": .string("fairway"),
                "coursePosition": .string("front bunker")
            ]
        )

        let situation = GolfRenderer(leagueCode: "pga").eventSituationPresentation(for: event, context: context(for: event, leagueCode: "pga"))

        XCTAssertEqual(situation?.title, "Leaderboard pressure")
        XCTAssertEqual(situation?.sport, .golf)
        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected golf to fall back to the generic pressure board")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Time", "Team", "Play", "Pressure"])
        let text = boardText(situation: situation, board: board)
        XCTAssertFalse(text.localizedCaseInsensitiveContains("fairway"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("bunker"))
    }

    func testTennisBreakPointRendersPointPressureBoard() {
        let event = pressureEvent(
            sequence: 3,
            periodLabel: "Set 2",
            clockLabel: "4-4",
            eventType: "break_point",
            sportMetadata: [
                "point": .string("30-40"),
                "server": .string("SEA")
            ]
        )

        let situation = TennisRenderer(leagueCode: "tennis").eventSituationPresentation(
            for: event,
            context: context(for: event, leagueCode: "tennis")
        )

        XCTAssertEqual(situation?.title, "Break point")
        XCTAssertEqual(situation?.sport, .tennis)
        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        XCTAssertEqual(situation?.setupText, "Set 2 · 4-4")
        XCTAssertEqual(situation?.pressureLine, "Break chance")
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected tennis break point to render a pressure board")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Set", "Game", "Point", "Server"])
    }

    func testTennisMatchPointRendersBigPointPressureBoard() {
        let event = pressureEvent(
            sequence: 4,
            periodLabel: "Final set",
            clockLabel: "6-5",
            eventType: "match_point",
            sportMetadata: [
                "point": .string("40-30"),
                "server": .string("SEA")
            ]
        )

        let situation = TennisRenderer(leagueCode: "tennis").eventSituationPresentation(
            for: event,
            context: context(for: event, leagueCode: "tennis")
        )

        XCTAssertEqual(situation?.title, "Match point")
        XCTAssertEqual(situation?.sport, .tennis)
        XCTAssertEqual(situation?.pressureLine, "Match point")
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected tennis match point to render a pressure board")
        }
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Point" })?.value, "40-30")
    }

    func testTennisDeuceRendersWhenScoreStateIsExplicit() {
        let event = pressureEvent(
            sequence: 5,
            importance: .secondary,
            periodLabel: "Set 1",
            clockLabel: "5-5",
            eventType: "deuce",
            sportMetadata: ["point": .string("Deuce")]
        )

        let situation = TennisRenderer(leagueCode: "tennis").eventSituationPresentation(
            for: event,
            context: context(for: event, leagueCode: "tennis", selectedMode: .full)
        )

        XCTAssertEqual(situation?.title, "Deuce pressure")
        XCTAssertEqual(situation?.sport, .tennis)
        XCTAssertEqual(situation?.pressureLine, "Deuce")
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected tennis deuce to render a pressure board")
        }
        XCTAssertEqual(board.metrics.first(where: { $0.label == "Point" })?.value, "Deuce")
    }

    func testTennisMissingPointStateUsesGenericFallback() {
        let event = pressureEvent(
            sequence: 6,
            periodLabel: "Set 1",
            clockLabel: "2-2",
            eventType: "rally",
            sportMetadata: ["courtLocation": .string("ad court")]
        )

        let situation = TennisRenderer(leagueCode: "tennis").eventSituationPresentation(
            for: event,
            context: context(for: event, leagueCode: "tennis")
        )

        XCTAssertEqual(situation?.title, "Score pressure")
        XCTAssertEqual(situation?.sport, .tennis)
        XCTAssertEqual(situation?.layout, .pressureBoardFallback)
        guard case .pressureBoardFallback(let board) = situation?.diagram else {
            return XCTFail("Expected tennis to fall back to the generic pressure board")
        }
        XCTAssertEqual(board.metrics.map(\.label), ["Time", "Team", "Play", "Pressure"])
        XCTAssertFalse(boardText(situation: situation, board: board).localizedCaseInsensitiveContains("court"))
    }

    func testTennisScoreboardUsesMatchScoreCopyAndSetTotals() {
        let game = TestFixtures.makeGame(id: 2100, leagueCode: "tennis")

        let presentation = SportRendererRegistry.renderer(for: game).scoreboardPresentation(for: game)

        XCTAssertEqual(presentation.title, "Match Score")
        XCTAssertEqual(presentation.revealTitle, "Match score hidden")
        XCTAssertEqual(presentation.revealButtonTitle, "Reveal match score")
        XCTAssertEqual(presentation.totalHeader, "Sets")
    }

    private func pressureEvent(
        sequence: Int,
        importance: GameEventImportance = .primary,
        periodLabel: String,
        clockLabel: String?,
        eventType: String,
        sportMetadata: [String: JSONValue]
    ) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            importance: importance,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            eventType: eventType,
            presentation: TestFixtures.eventPresentation(timeLabel: [periodLabel, clockLabel].compactMap(\.self).joined(separator: " ")),
            sportMetadata: sportMetadata
        )
    }

    private func context(
        for event: GameEvent,
        leagueCode: String,
        selectedMode: DetailStreamMode = .key
    ) -> SportRendererSituationContext {
        SportRendererSituationContext(
            game: TestFixtures.makeGame(id: 2200 + event.sequence, leagueCode: leagueCode),
            selectedMode: selectedMode,
            visibleEvents: [event],
            eventIndex: 0
        )
    }

    private func boardText(
        situation: GameEventSituationPresentation?,
        board: PressureBoardSituationDiagram
    ) -> String {
        let fragments = [
            situation?.title,
            situation?.periodText,
            situation?.setupText,
            situation?.contextLine,
            situation?.pressureLine,
            situation?.ownership?.displayLabel
        ].compactMap { $0?.nilIfBlank }
        return (fragments + board.metrics.flatMap { [$0.label, $0.value] }).joined(separator: " ")
    }
}
