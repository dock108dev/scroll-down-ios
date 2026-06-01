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
                    .ok(TestFixtures.sdaCardFeedJSON(gameId: 703, cardIDs: ["play-1", "play-2"]))
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
                    .ok(TestFixtures.sdaCardFeedJSON(gameId: 704, cardIDs: ["play-1", "play-2"])),
                    .ok(TestFixtures.sdaGameListJSON(ids: [704])),
                    .ok(TestFixtures.sdaCardFeedJSON(gameId: 704, cardIDs: ["play-1", "play-2", "play-3", "play-4"])),
                    .ok(TestFixtures.sdaGameListJSON(ids: [704])),
                    .ok(TestFixtures.sdaCardFeedJSON(gameId: 704, cardIDs: ["play-1"]))
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

    func testPinnedPriorityOrderingSelectsHighestPriorityGamesUnderFetchCap() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(
            id: 801,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T15:30:00Z"),
            status: "in_progress",
            isLive: true,
            isFinal: false
        ))
        store.pin(TestFixtures.makeGame(
            id: 802,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T18:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false
        ))
        store.pin(TestFixtures.makeGame(
            id: 803,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T18:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        ))
        store.pin(TestFixtures.makeGame(
            id: 804,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T09:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        ))
        store.pin(TestFixtures.makeGame(
            id: 805,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T22:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false
        ))
        store.recordPinnedGameRefreshFailure(
            gameId: 804,
            message: "previous refresh failed",
            at: TestFixtures.fixedDate("2026-05-22T15:00:00Z")
        )
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .success([]),
            detailResults: [
                801: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 801), events: [])),
                802: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 802), events: [])),
                805: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 805), events: []))
            ]
        )
        let service = BackgroundRefreshService(
            apiClient: apiClient,
            gameStateStore: store,
            now: { now },
            maxPinnedDetailFetches: 3
        )

        try await service.refreshForBackground()

        XCTAssertEqual(apiClient.fetchedGameIds, [801, 802, 805])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.refreshedGameIds, [801, 802, 805])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.skippedPinnedGameIds, [804, 803])
    }

    func testZeroAndNegativeFetchCapsSkipAllPinnedDetails() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")

        try await assertAllPinnedDetailsSkipped(now: now, maxPinnedDetailFetches: 0)
        try await assertAllPinnedDetailsSkipped(now: now, maxPinnedDetailFetches: -2)
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
                    .ok(TestFixtures.sdaCardFeedJSON(gameId: 710, cardIDs: ["play-1"])),
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

    func testPinnedDetailFailureContinuesRefreshingRemainingSelectedGames() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        for id in 830...832 {
            store.pin(TestFixtures.makeGame(id: id, scheduledStart: now, eventCount: 1))
        }
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .success([]),
            detailResults: [
                830: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 830), events: [])),
                831: .failure(URLError(.badServerResponse)),
                832: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 832), events: []))
            ]
        )
        let service = BackgroundRefreshService(
            apiClient: apiClient,
            gameStateStore: store,
            now: { now },
            maxPinnedDetailFetches: 3
        )

        try await service.refreshForBackground()

        XCTAssertEqual(apiClient.fetchedGameIds, [830, 831, 832])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.refreshedGameIds, [830, 832])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.failedGameIds, [831])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.success, false)
        XCTAssertNotNil(store.snapshot.pinnedGamesById[831]?.lastBackgroundError)
        XCTAssertNotNil(store.snapshot.pinnedGamesById[832]?.latestDetail)
    }

    func testFavoriteNotificationPlannerUsesOnlySpoilerSafeMetadata() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        var snapshot = LocalGameStateSnapshot.empty(now: now)
        snapshot.setFavoriteTeam("team-favorite", isFavorite: true)
        let final = TestFixtures.makeGame(
            id: 850,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T14:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayTeamID: "team-favorite",
            awayScore: 41,
            homeScore: 38,
            eventCount: 24
        )
        let live = TestFixtures.makeGame(
            id: 851,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T16:00:00Z"),
            status: "in_progress",
            isLive: true,
            awayTeamID: "team-favorite",
            awayScore: 8,
            homeScore: 5,
            eventCount: 13
        )
        let upcoming = TestFixtures.makeGame(
            id: 852,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T20:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayTeamID: "team-favorite",
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            presentation: TestFixtures.previewPresentation()
        )

        let plans = FavoriteGameNotificationPlanner.plans(games: [final, live, upcoming], snapshot: snapshot, now: now)

        XCTAssertEqual(plans.map(\.payload.unreadState), [.finalUnread, .live, .upcoming])
        XCTAssertEqual(plans.map(\.payload.status), [.final, .live, .upcoming])
        XCTAssertEqual(plans.first?.payload.playCount, 24)
        XCTAssertEqual(plans.first?.payload.estimatedReadingMinutes, 2)
        XCTAssertEqual(plans.first?.payload.userInfo[FavoriteGameNotificationPayloadKeys.gameId] as? Int, 850)

        let visibleText = plans.flatMap { [$0.title, $0.body] }.joined(separator: " ")
        ["41", "38", "8-5", "winner", "wins", "comeback", "blowout", "score"].forEach { leakingToken in
            XCTAssertFalse(
                visibleText.localizedCaseInsensitiveContains(leakingToken),
                "Notification text leaked \(leakingToken): \(visibleText)"
            )
        }
    }

    func testFavoriteNotificationDeliveryFailureDoesNotFailBackgroundRefresh() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.setFavoriteTeam(teamId: "away-860", isFavorite: true)
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .success([
                TestFixtures.makeGame(
                    id: 860,
                    scheduledStart: TestFixtures.fixedDate("2026-05-22T14:00:00Z"),
                    status: "final",
                    isLive: false,
                    isFinal: true,
                    eventCount: 18
                )
            ]),
            detailResults: [:]
        )
        let service = BackgroundRefreshService(
            apiClient: apiClient,
            gameStateStore: store,
            notificationDeliverer: FakeFavoriteGameNotificationDeliverer(result: .failure(URLError(.cannotWriteToFile))),
            now: { now }
        )

        try await service.refreshForBackground()

        XCTAssertEqual(store.snapshot.homeSnapshot?.games.map(\.id), [860])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.success, true)
        XCTAssertTrue(store.snapshot.favoriteNotificationKeys.isEmpty)
    }

    func testDeliveredFavoriteNotificationsAreRecordedAndNotRepeated() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.setFavoriteTeam(teamId: "away-861", isFavorite: true)
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .success([
                TestFixtures.makeGame(
                    id: 861,
                    scheduledStart: TestFixtures.fixedDate("2026-05-22T14:00:00Z"),
                    status: "final",
                    isLive: false,
                    isFinal: true,
                    eventCount: 18
                )
            ]),
            detailResults: [:]
        )
        let deliverer = FakeFavoriteGameNotificationDeliverer(result: .success)
        let service = BackgroundRefreshService(
            apiClient: apiClient,
            gameStateStore: store,
            notificationDeliverer: deliverer,
            now: { now }
        )

        try await service.refreshForBackground()
        try await service.refreshForBackground()

        XCTAssertEqual(deliverer.deliveredPlans.map(\.payload.gameId), [861])
        XCTAssertEqual(store.snapshot.favoriteNotificationKeys.count, 1)
    }

    func testFatalHomeFetchFailureRecordsFailedRefreshAndSkipsPinnedDetails() async {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(id: 810, scheduledStart: now, eventCount: 1))
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .failure(URLError(.cannotLoadFromNetwork)),
            detailResults: [
                810: .success(TestFixtures.makeDetail(game: TestFixtures.makeGame(id: 810), events: []))
            ]
        )
        let service = BackgroundRefreshService(apiClient: apiClient, gameStateStore: store, now: { now })

        do {
            try await service.refreshForBackground()
            XCTFail("Expected home fetch failure to rethrow")
        } catch {
            XCTAssertTrue(error is URLError)
        }

        let record = store.snapshot.backgroundRefreshRecord
        XCTAssertNil(store.snapshot.homeSnapshot)
        XCTAssertEqual(apiClient.fetchedGameIds, [])
        XCTAssertEqual(record?.success, false)
        XCTAssertNotNil(record?.completedAt)
        XCTAssertNotNil(record?.errorMessage)
        XCTAssertEqual(record?.refreshedGameIds, [])
        XCTAssertEqual(record?.failedGameIds, [])
    }

    func testCancellationRecordsFailedRefreshWithoutMutatingPinnedDetail() async throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(id: 840, scheduledStart: now, eventCount: 1))
        let detailStarted = expectation(description: "detail fetch started")
        let apiClient = FakeBackgroundRefreshAPIClient(
            gamesResult: .success([]),
            detailResults: [840: .suspend],
            onFetchGame: { _ in detailStarted.fulfill() }
        )
        let service = BackgroundRefreshService(apiClient: apiClient, gameStateStore: store, now: { now })
        let task = Task {
            try await service.refreshForBackground()
        }

        await fulfillment(of: [detailStarted], timeout: 1)
        task.cancel()

        do {
            try await task.value
            XCTFail("Expected cancellation to rethrow")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected cancellation error, got \(error)")
        }

        let record = store.snapshot.backgroundRefreshRecord
        XCTAssertEqual(record?.success, false)
        XCTAssertNotNil(record?.completedAt)
        XCTAssertNotNil(record?.errorMessage)
        XCTAssertNil(store.snapshot.pinnedGamesById[840]?.latestDetail)
        XCTAssertNil(store.snapshot.pinnedGamesById[840]?.lastBackgroundRefreshAt)
    }

    private func assertAllPinnedDetailsSkipped(now: Date, maxPinnedDetailFetches: Int) async throws {
        let store = InMemoryGameStateStore(now: { now })
        store.pin(TestFixtures.makeGame(id: 820, scheduledStart: now, eventCount: 1))
        store.pin(TestFixtures.makeGame(id: 821, scheduledStart: now, eventCount: 1))
        let apiClient = FakeBackgroundRefreshAPIClient(gamesResult: .success([]), detailResults: [:])
        let service = BackgroundRefreshService(
            apiClient: apiClient,
            gameStateStore: store,
            now: { now },
            maxPinnedDetailFetches: maxPinnedDetailFetches
        )

        try await service.refreshForBackground()

        XCTAssertEqual(apiClient.fetchedGameIds, [])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.refreshedGameIds, [])
        XCTAssertEqual(store.snapshot.backgroundRefreshRecord?.skippedPinnedGameIds, [820, 821])
    }
}

private final class MockBackgroundURLProtocol: MockHTTPURLProtocol {}

@MainActor
private final class FakeFavoriteGameNotificationDeliverer: FavoriteGameNotificationDelivering {
    enum ResultValue {
        case success
        case failure(Error)
    }

    private let result: ResultValue
    private(set) var deliveredPlans: [FavoriteGameNotificationPlan] = []

    init(result: ResultValue) {
        self.result = result
    }

    func deliver(_ plans: [FavoriteGameNotificationPlan]) async throws -> Set<String> {
        switch result {
        case .success:
            deliveredPlans.append(contentsOf: plans)
            return Set(plans.map(\.key))
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class FakeBackgroundRefreshAPIClient: BackgroundRefreshAPIClient {
    enum DetailResult {
        case success(GameDetail)
        case failure(Error)
        case suspend
    }

    private let gamesResult: Result<[Game], Error>
    private let detailResults: [Int: DetailResult]
    private let onFetchGame: (Int) -> Void
    private(set) var fetchedGameIds: [Int] = []

    init(
        gamesResult: Result<[Game], Error>,
        detailResults: [Int: DetailResult],
        onFetchGame: @escaping (Int) -> Void = { _ in }
    ) {
        self.gamesResult = gamesResult
        self.detailResults = detailResults
        self.onFetchGame = onFetchGame
    }

    func fetchGames(window: GameWindow, limit: Int) async throws -> [Game] {
        try gamesResult.get()
    }

    func fetchGame(id: Int) async throws -> GameDetail {
        fetchedGameIds.append(id)
        onFetchGame(id)
        switch detailResults[id] {
        case .success(let detail):
            return detail
        case .failure(let error):
            throw error
        case .suspend:
            try await Task.sleep(nanoseconds: 60_000_000_000)
            throw CancellationError()
        case nil:
            throw URLError(.badServerResponse)
        }
    }
}
