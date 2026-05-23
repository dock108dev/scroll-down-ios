import XCTest
@testable import ScrollDownSports

@MainActor
final class ProductPresentationInvariantTests: XCTestCase {
    func testHomeCardHidesScoresFromTopRegionsUntilScoreboardPayoff() {
        let game = TestFixtures.makeGame(awayScore: 7, homeScore: 6)
        let item = HomeGameItem(game: game, isPinned: false, pinnedRecord: nil, progress: nil)
        let state = HomeGameCardState(item: item)
        let presentation = SportRendererRegistry.renderer(for: game).gameCardPresentation(for: game)

        XCTAssertEqual(state.scoreCueText, "score at bottom")
        XCTAssertFalse(state.showsScoreRows)
        assertNoScoreLeak(
            texts: [
                presentation.leagueLabel,
                presentation.sportLabel,
                presentation.statusText,
                presentation.headline,
                presentation.matchupLabel,
                state.metadataText,
                state.contextText,
                state.primaryActionLabel
            ],
            forbidden: ["7-6", "6-7", "7, Mariners 6", "NYY 7", "SEA 6"]
        )
    }

    func testDetailHeaderKeepsScoreOutOfHeaderAndScoreboardPresentationContainsResult() {
        let scoreboard = GameScoreboardData(
            layout: "inning_table",
            clockLabel: nil,
            periodLabel: "Final",
            statusLabel: "Final",
            scoreline: "Yankees 7, Mariners 6",
            competitors: [
                ScoreboardCompetitorData(
                    id: "away",
                    side: .away,
                    teamName: "New York Yankees",
                    teamAbbreviation: "NYY",
                    score: 7,
                    scoreText: "7",
                    isWinner: true,
                    recordText: nil
                ),
                ScoreboardCompetitorData(
                    id: "home",
                    side: .home,
                    teamName: "Seattle Mariners",
                    teamAbbreviation: "SEA",
                    score: 6,
                    scoreText: "6",
                    isWinner: false,
                    recordText: nil
                )
            ],
            segments: [ScoreboardSegmentData(label: "9", away: "1", home: "0")],
            totals: ScoreboardTotalsData(away: "7", home: "6")
        )
        let game = TestFixtures.makeGame(
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 7,
            homeScore: 6,
            scoreboard: scoreboard
        )
        let renderer = SportRendererRegistry.renderer(for: game)

        let header = renderer.gameHeaderPresentation(for: game)
        assertNoScoreLeak(
            texts: [
                header.leagueLabel,
                header.sportLabel,
                header.statusText,
                header.playCountText,
                header.headline,
                header.matchupLabel,
                header.secondaryText
            ],
            forbidden: ["7-6", "6-7", "Yankees 7", "Mariners 6", "NYY 7", "SEA 6"]
        )

        let scoreboardPresentation = renderer.scoreboardPresentation(for: game)
        XCTAssertEqual(scoreboardPresentation.title, "Line Score")
        XCTAssertEqual(scoreboardPresentation.layout, .segmentTable)
        XCTAssertEqual(scoreboardPresentation.stateText, "Yankees 7, Mariners 6")
        XCTAssertEqual(scoreboardPresentation.rows.map(\.totalText), ["7", "6"])
        XCTAssertEqual(scoreboardPresentation.revealTitle, "Score hidden")
    }

    func testScoreboardReachPersistsOnlyAfterMeaningfulViewportEntry() {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(gameId: 900, gameStateStore: store)
        let viewport = CGRect(x: 0, y: 0, width: 390, height: 800)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 784, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertFalse(store.progress(for: 900)?.reachedScoreboard == true)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 700, width: 390, height: 240),
            viewportFrame: viewport
        ) {
            viewModel.setReachedScoreboard(true)
        }
        XCTAssertTrue(store.progress(for: 900)?.reachedScoreboard == true)
    }

    func testStreamModesAndEventLabelsUseCustomerLanguage() {
        XCTAssertEqual(DetailStreamMode.allCases.map(\.title), ["Important", "Standard", "All Plays"])

        let homeRun = TestFixtures.makeEvent(sequence: 1, eventType: "HOME_RUN")
        let fieldOut = TestFixtures.makeEvent(sequence: 2, eventType: "FIELD_OUT")
        let renderer = GenericSportRenderer(leagueCode: "mlb")

        XCTAssertEqual(renderer.eventPresentation(for: homeRun).eventLabel, "Home run")
        XCTAssertEqual(renderer.eventPresentation(for: fieldOut).eventLabel, "Out")
        XCTAssertEqual(homeRun.visualImportance.title, "")

        let duplicatedClock = TestFixtures.makeEvent(
            sequence: 3,
            periodLabel: "6th",
            clockLabel: "6th"
        )
        XCTAssertEqual(duplicatedClock.clockText, "6th")
    }

    private func assertNoScoreLeak(texts: [String?], forbidden: [String], file: StaticString = #filePath, line: UInt = #line) {
        let combined = texts.compactMap { $0 }.joined(separator: " | ")
        for value in forbidden {
            XCTAssertFalse(combined.contains(value), "\(value) leaked through \(combined)", file: file, line: line)
        }
    }
}
