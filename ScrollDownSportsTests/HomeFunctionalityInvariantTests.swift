import XCTest
@testable import ScrollDownSports

@MainActor
final class HomeFunctionalityInvariantTests: XCTestCase {
    func testRefreshFailureKeepsPersistedHomeSnapshotRenderable() async throws {
        let now = TestFixtures.fixedDate()
        let snapshotGame = TestFixtures.makeGame(id: 1401)
        let store = InMemoryGameStateStore(now: { now })
        store.saveHomeSnapshot(games: [snapshotGame], windowKey: GameWindow.home(now: now).stableKey, fetchedAt: now)
        let viewModel = HomeViewModel(
            apiClient: TestFixtures.makeAPIClient(
                responses: [.httpError(statusCode: 503)],
                protocolClass: MockHomeURLProtocol.self
            ),
            now: { now },
            gameStateStore: store
        )

        XCTAssertEqual(viewModel.games.map(\.id), [1401])

        await viewModel.refresh()

        XCTAssertEqual(viewModel.games.map(\.id), [1401])
        XCTAssertEqual(viewModel.lastUpdated, now)
        XCTAssertEqual(viewModel.errorMessage, "The data service returned HTTP 503.")
        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["today"])
    }

    func testFinalGameWithoutPlayByPlayOpensBoxScoreWithoutNewPlayBadge() {
        let game = TestFixtures.makeGame(
            id: 1402,
            status: "final",
            isLive: false,
            isFinal: true,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: true
        )

        let state = HomeGameCardState(
            item: HomeGameItem(game: game, isPinned: false, pinnedRecord: nil, progress: nil)
        )

        XCTAssertEqual(state.phase, .final)
        XCTAssertEqual(state.primaryActionLabel, "Open box score")
        XCTAssertNil(state.newPlayText)
        XCTAssertNil(state.progressText)
    }

    func testScheduledGameWithoutPriorProgressDoesNotShowNewPlayBadge() {
        let game = TestFixtures.makeGame(
            id: 1403,
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false
        )

        let state = HomeGameCardState(
            item: HomeGameItem(game: game, isPinned: false, pinnedRecord: nil, progress: nil)
        )

        XCTAssertEqual(state.phase, .scheduled)
        XCTAssertNil(state.newPlayText)
        XCTAssertNil(state.scoreCueText)
        XCTAssertFalse(state.showsScoreRows)
    }

    func testHomeReflectsPinAndScoreboardProgressRecordedFromDetailSide() {
        let now = TestFixtures.fixedDate()
        let game = TestFixtures.makeGame(id: 1404)
        let store = InMemoryGameStateStore(now: { now })
        let homeViewModel = HomeViewModel(now: { now }, gameStateStore: store)
        let detailViewModel = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        homeViewModel.games = [game]

        detailViewModel.toggleGamePin(game)
        detailViewModel.setReachedScoreboard(true)

        let sections = homeViewModel.filteredHomeSections
        guard case .pinned(let pinnedSection) = sections.first else {
            return XCTFail("Expected a pinned section")
        }
        XCTAssertEqual(pinnedSection.games.map(\.id), [game.id])
        XCTAssertTrue(pinnedSection.games.first?.reachedScoreboard == true)
        XCTAssertTrue(homeViewModel.isPinned(game))
    }
}

private final class MockHomeURLProtocol: MockHTTPURLProtocol {}
