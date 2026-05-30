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
        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["timeline"])
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

    func testNoGamesAndFilteredNoMatchEmptyStatesStayDistinct() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))

        XCTAssertTrue(viewModel.showsNoGamesEmptyState)
        XCTAssertFalse(viewModel.showsFilteredEmptyState)

        viewModel.league = .nba

        XCTAssertTrue(viewModel.showsNoGamesEmptyState)
        XCTAssertFalse(viewModel.showsFilteredEmptyState)

        viewModel.games = [
            TestFixtures.makeGame(
                id: 1405,
                leagueCode: "mlb",
                scheduledStart: TestFixtures.fixedDate("2026-05-23T18:00:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false
            )
        ]

        XCTAssertFalse(viewModel.showsNoGamesEmptyState)
        XCTAssertTrue(viewModel.showsFilteredEmptyState)
    }

    func testFutureSectionEmptyStatesRenderWhenNoFutureGamesQualify() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let final = TestFixtures.makeGame(
            id: 1406,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [final]

        let timeline = timelineFeed(in: viewModel.filteredHomeSections)

        XCTAssertEqual(timeline.dateSections.map(\.id), [
            "timeline-yesterday",
            "timeline-later-today",
            "timeline-upcoming"
        ])
        XCTAssertEqual(timeline.dateSections.first { $0.id == "timeline-later-today" }?.emptyState, .laterToday)
        XCTAssertEqual(timeline.dateSections.first { $0.id == "timeline-upcoming" }?.emptyState, .upcoming)
        XCTAssertEqual(viewModel.filteredVisibleGameCount, 1)
    }

    func testConcretePregameWithoutPreviewMetadataAppearsInFutureTimeline() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let scheduled = TestFixtures.makeGame(
            id: 1407,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T20:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: "Atlanta Braves",
            awayAbbreviation: "ATL",
            homeName: "Philadelphia Phillies",
            homeAbbreviation: "PHI",
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: false,
            presentation: nil
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [scheduled]

        XCTAssertEqual(
            HomeSectionTestHelpers.timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-later-today"),
            [scheduled.id]
        )
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

    private func timelineFeed(in sections: [HomeSection]) -> HomeTimelineFeedSection {
        guard case .timeline(let timeline) = sections.first(where: { $0.id == "timeline" }) else {
            XCTFail("Expected a timeline section")
            return HomeTimelineFeedSection(title: "Timeline", dateSections: [])
        }
        return timeline
    }
}

private final class MockHomeURLProtocol: MockHTTPURLProtocol {}
