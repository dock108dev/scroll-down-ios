import XCTest
@testable import ScrollDownSports

@MainActor
final class HomePinnedVisibilityTests: XCTestCase {
    func testPinnedGameOutsideHomeWindowRendersOnlyAfterSeparateFetch() async throws {
        let now = TestFixtures.fixedDate("2026-05-30T16:00:00Z")
        let pinned = TestFixtures.makeGame(
            id: 2201,
            scheduledStart: TestFixtures.fixedDate("2026-05-12T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(try SDAFixturePayloadFactory.gameList(ids: [])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: pinned.id, playIDs: ["pinned-1"]))
                ],
                protocolClass: MockPinnedSuccessURLProtocol.self
            ),
            now: { now },
            gameStateStore: store
        )

        await viewModel.refresh()

        let sections = viewModel.filteredHomeSections
        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: sections), [pinned.id])
        XCTAssertTrue(HomeSectionTestHelpers.allTimelineIDs(in: sections).isEmpty)
        XCTAssertEqual(viewModel.separatelyFetchedPinnedGames.map(\.id), [pinned.id])
        XCTAssertTrue(MockHTTPURLProtocol.requestURLs(for: MockPinnedSuccessURLProtocol.self).contains {
            $0.path == "/api/v1/games/\(pinned.id)"
        })
    }

    func testPinnedGameOutsideHomeWindowStaysHiddenWhenSeparateFetchFails() async throws {
        let now = TestFixtures.fixedDate("2026-05-30T16:00:00Z")
        let pinned = TestFixtures.makeGame(
            id: 2211,
            scheduledStart: TestFixtures.fixedDate("2026-05-12T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(try SDAFixturePayloadFactory.gameList(ids: [])),
                    .httpError(statusCode: 404)
                ],
                protocolClass: MockPinnedFailureURLProtocol.self
            ),
            now: { now },
            gameStateStore: store
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["timeline"])
        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [])
        XCTAssertTrue(viewModel.separatelyFetchedPinnedGames.isEmpty)
        XCTAssertEqual(store.snapshot.pinnedGamesById[pinned.id]?.lastBackgroundError, "Game Data Not Found")
    }

    func testLeagueAndTeamFiltersApplyToPinnedAndTimelineWithoutPlaceholderBypass() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let mets = scheduledGame(id: 2221, leagueCode: "mlb", awayName: "New York Mets", awayAbbreviation: "NYM")
        let bruins = scheduledGame(id: 2222, leagueCode: "nhl", awayName: "Boston Bruins", awayAbbreviation: "BOS")
        let placeholder = scheduledGame(id: 2223, leagueCode: "mlb", awayName: "T.B.A.", awayAbbreviation: "TBA")
        let store = InMemoryGameStateStore(now: { now })
        [mets, bruins, placeholder].forEach { store.pin($0) }
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [mets, bruins, placeholder]
        viewModel.league = .mlb
        viewModel.teamQuery = "nym"

        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [mets.id])
        XCTAssertTrue(HomeSectionTestHelpers.allTimelineIDs(in: viewModel.filteredHomeSections).isEmpty)
    }

    func testCachedAndFreshHomeSourcesProduceEquivalentVisibleSections() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let pinned = scheduledGame(id: 2231, leagueCode: "mlb", awayName: "New York Mets", awayAbbreviation: "NYM")
        let visible = scheduledGame(id: 2232, leagueCode: "mlb", awayName: "Atlanta Braves", awayAbbreviation: "ATL")
        let placeholder = scheduledGame(id: 2233, leagueCode: "mlb", awayName: "To Be Determined", awayAbbreviation: "TBD")

        let cachedStore = InMemoryGameStateStore(now: { now })
        cachedStore.pin(pinned)
        cachedStore.saveHomeSnapshot(
            games: [placeholder, visible, pinned],
            windowKey: GameWindow.home(now: now).stableKey,
            fetchedAt: now
        )
        let cachedViewModel = HomeViewModel(now: { now }, gameStateStore: cachedStore)

        let freshStore = InMemoryGameStateStore(now: { now })
        freshStore.pin(pinned)
        let freshViewModel = HomeViewModel(now: { now }, gameStateStore: freshStore)
        freshViewModel.games = [placeholder, visible, pinned]

        XCTAssertEqual(cachedViewModel.filteredHomeSections, freshViewModel.filteredHomeSections)
    }

    private func scheduledGame(
        id: Int,
        leagueCode: String = "mlb",
        awayName: String,
        awayAbbreviation: String
    ) -> Game {
        TestFixtures.makeGame(
            id: id,
            leagueCode: leagueCode,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T20:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: awayName,
            awayAbbreviation: awayAbbreviation,
            presentation: TestFixtures.previewPresentation()
        )
    }
}

private final class MockPinnedSuccessURLProtocol: MockHTTPURLProtocol {}
private final class MockPinnedFailureURLProtocol: MockHTTPURLProtocol {}
