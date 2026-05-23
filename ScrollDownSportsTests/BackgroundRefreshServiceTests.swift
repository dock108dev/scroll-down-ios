import XCTest
@testable import ScrollDownSports

@MainActor
final class BackgroundRefreshServiceTests: XCTestCase {
    func testRefreshWithoutPinnedGamesPersistsHomeSnapshot() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let service = BackgroundRefreshService(
            apiClient: TestFixtures.makeAPIClient(
                responses: [.ok(TestFixtures.sdaGameListJSON(ids: [701, 702]))],
                protocolClass: MockBackgroundURLProtocol.self
            ),
            gameStateStore: store,
            now: { now }
        )

        try await service.refreshForBackground()

        XCTAssertEqual(store.snapshot.homeSnapshot?.windowKey, GameWindow.home(now: now).stableKey)
        XCTAssertEqual(store.snapshot.homeSnapshot?.games.map(\.id), [701, 702])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.refreshedGameIds, [])
        XCTAssertTrue(store.snapshot.backgroundRefreshRecord?.success == true)
    }

    func testPinnedDetailRefreshStoresBaselineWithoutHistoricalNewCount() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(id: 703, scheduledStart: now, eventCount: 2))
        let service = BackgroundRefreshService(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameListJSON(ids: [703])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 703, playIDs: ["play-1", "play-2"]))
                ],
                protocolClass: MockBackgroundURLProtocol.self
            ),
            gameStateStore: store,
            now: { now }
        )

        try await service.refreshForBackground()

        let record = try XCTUnwrap(store.snapshot.pinnedGamesById[703])
        XCTAssertEqual(record.latestDetail?.events.map(\.id), ["play-1", "play-2"])
        XCTAssertEqual(record.latestPlayCursor?.sequence, 2)
        XCTAssertEqual(record.lastSeenPlayCursor?.sequence, 2)
        XCTAssertEqual(record.newEventCount, 0)
        XCTAssertEqual(store.progress(for: 703)?.newEventCount, 0)
    }

    func testPinnedDetailAdvancementAndStaleRegressionPreserveUnseenCount() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(id: 704, scheduledStart: now, eventCount: 2))
        var currentDate = now
        let service = BackgroundRefreshService(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameListJSON(ids: [704])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 704, playIDs: ["play-1", "play-2"])),
                    .ok(TestFixtures.sdaGameListJSON(ids: [704])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 704, playIDs: ["play-1", "play-2", "play-3", "play-4"])),
                    .ok(TestFixtures.sdaGameListJSON(ids: [704])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 704, playIDs: ["play-1"]))
                ],
                protocolClass: MockBackgroundURLProtocol.self
            ),
            gameStateStore: store,
            now: { currentDate }
        )

        try await service.refreshForBackground()
        currentDate = TestFixtures.fixedDate("2026-05-22T16:05:00Z")
        try await service.refreshForBackground()
        currentDate = TestFixtures.fixedDate("2026-05-22T16:10:00Z")
        try await service.refreshForBackground()

        let record = try XCTUnwrap(store.snapshot.pinnedGamesById[704])
        XCTAssertEqual(record.latestPlayCursor?.sequence, 4)
        XCTAssertEqual(record.lastSeenPlayCursor?.sequence, 2)
        XCTAssertEqual(record.newEventCount, 2)
        XCTAssertEqual(record.latestDetail?.events.map(\.id), ["play-1", "play-2", "play-3", "play-4"])
    }

    func testPinnedDetailFailureAndFetchCapDoNotCorruptStoredState() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        for id in 710..<715 {
            store.pin(TestFixtures.makeGame(id: id, scheduledStart: now, eventCount: 1))
        }
        let service = BackgroundRefreshService(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameListJSON(ids: Array(710..<715))),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 710, playIDs: ["play-1"])),
                    .httpError(statusCode: 503)
                ],
                protocolClass: MockBackgroundURLProtocol.self
            ),
            gameStateStore: store,
            now: { now },
            maxPinnedDetailFetches: 2
        )

        try await service.refreshForBackground()

        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.refreshedGameIds, [710])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.failedGameIds, [711])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.skippedPinnedGameIds.count, 3)
        XCTAssertNotNil(store.snapshot.pinnedGamesById[711]?.lastBackgroundError)
        XCTAssertNil(store.snapshot.pinnedGamesById[712]?.latestDetail)
    }
}

private final class MockBackgroundURLProtocol: MockHTTPURLProtocol {}
