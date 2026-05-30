import XCTest
@testable import ScrollDownSports

@MainActor
final class HomeAnchorBehaviorTests: XCTestCase {
    func testInitialAnchorPrefersPinnedUnreadOverYesterday() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let pinned = TestFixtures.makeGame(id: 2101, scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"))
        let yesterday = TestFixtures.makeGame(
            id: 2102,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T01:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        store.recordKnownEventCount(gameId: pinned.id, count: 3)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [yesterday, pinned]

        XCTAssertEqual(viewModel.initialHomeAnchorID, "pinned")
    }

    func testInitialAnchorPrefersYesterdayOverLiveAndUpcoming() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let yesterday = TestFixtures.makeGame(
            id: 2111,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let live = TestFixtures.makeGame(id: 2112, scheduledStart: TestFixtures.fixedDate("2026-05-23T16:00:00Z"))
        let upcoming = scheduledGame(id: 2113, start: "2026-05-24T18:00:00Z")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [live, upcoming, yesterday]

        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-yesterday")
    }

    func testInitialAnchorPrefersRecentFinalOverReadPinned() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let pinned = scheduledGame(id: 2121, start: "2026-05-23T20:00:00Z")
        let recentFinal = TestFixtures.makeGame(
            id: 2122,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T15:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [pinned, recentFinal]

        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-today")
    }

    func testInitialAnchorPrefersReadPinnedOverTimelineFallbacks() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let pinned = scheduledGame(id: 2131, start: "2026-05-23T20:00:00Z")
        let live = TestFixtures.makeGame(id: 2132, scheduledStart: TestFixtures.fixedDate("2026-05-23T16:00:00Z"))
        let today = TestFixtures.makeGame(
            id: 2133,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T11:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false
        )
        let later = scheduledGame(id: 2134, start: "2026-05-23T21:00:00Z")
        let upcoming = scheduledGame(id: 2135, start: "2026-05-24T18:00:00Z")
        let older = TestFixtures.makeGame(
            id: 2136,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [live, today, later, upcoming, older, pinned]

        XCTAssertEqual(viewModel.initialHomeAnchorID, "pinned")
    }

    func testInitialAnchorFallbackOrder() {
        XCTAssertEqual(anchor(for: [liveGame(id: 2141)]), "timeline-live")
        XCTAssertEqual(anchor(for: [todayUnknownGame(id: 2142)]), "timeline-today")
        XCTAssertEqual(anchor(for: [scheduledGame(id: 2143, start: "2026-05-23T20:00:00Z")]), "timeline-later-today")
        XCTAssertEqual(anchor(for: [scheduledGame(id: 2144, start: "2026-05-24T18:00:00Z")]), "timeline-upcoming")
        XCTAssertEqual(anchor(for: [olderUnknownGame(id: 2145)]), "timeline-older")
        XCTAssertNil(anchor(for: []))
    }

    func testRenderableAnchorsExcludeTimelineFeedWithoutRows() {
        let sections: [HomeSection] = [
            .timeline(HomeTimelineFeedSection(title: "Timeline", dateSections: []))
        ]

        XCTAssertNil(sections.firstRenderedAnchorID)
        XCTAssertFalse(sections.renderedAnchorIDs.contains("timeline"))
    }

    func testFilterAnchorsUseFirstVisibleRenderedSection() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let older = olderUnknownGame(id: 2151)
        let yesterday = TestFixtures.makeGame(
            id: 2152,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let nba = scheduledGame(id: 2153, start: "2026-05-23T20:00:00Z", leagueCode: "nba")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [older, yesterday, nba]

        viewModel.league = .nba

        XCTAssertEqual(viewModel.firstVisibleHomeAnchorID, "timeline-later-today")
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-later-today")

        viewModel.clearFilters()

        XCTAssertEqual(viewModel.firstVisibleHomeAnchorID, "timeline-older")
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-yesterday")
    }

    private func anchor(for games: [Game]) -> String? {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = games
        return viewModel.initialHomeAnchorID
    }

    private func scheduledGame(id: Int, start: String, leagueCode: String = "mlb") -> Game {
        TestFixtures.makeGame(
            id: id,
            leagueCode: leagueCode,
            scheduledStart: TestFixtures.fixedDate(start),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            presentation: TestFixtures.previewPresentation()
        )
    }

    private func liveGame(id: Int) -> Game {
        TestFixtures.makeGame(id: id, scheduledStart: TestFixtures.fixedDate("2026-05-23T16:00:00Z"))
    }

    private func todayUnknownGame(id: Int) -> Game {
        TestFixtures.makeGame(
            id: id,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T11:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false
        )
    }

    private func olderUnknownGame(id: Int) -> Game {
        TestFixtures.makeGame(
            id: id,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false
        )
    }

}
