import XCTest
@testable import ScrollDownSports

@MainActor
final class LiveRefreshInvariantTests: XCTestCase {
    func testAppendedEventsWhileReadingAwayCreatePendingCountWithoutMovingReadCursor() async throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(
            gameId: 1301,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1301, playIDs: ["event-1", "event-2"])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1301, playIDs: ["event-1", "event-2", "event-3", "event-4"]))
                ],
                protocolClass: MockLiveURLProtocol.self
            ),
            gameStateStore: store
        )

        await viewModel.refresh()
        viewModel.setFollowingLiveEdge(false)
        viewModel.recordReadEvent(eventIndex: 0, eventID: "event-1", knownEventCount: 2)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.eventDiff.kind, .appended)
        XCTAssertEqual(viewModel.eventDiff.insertedEvents.map(\.id), ["event-3", "event-4"])
        XCTAssertEqual(store.progress(for: 1301)?.lastReadEventID, "event-1")
        XCTAssertEqual(store.progress(for: 1301)?.lastReadEventIndex, 0)
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 3)
        XCTAssertFalse(viewModel.isFollowingLiveEdge)
    }

    func testFollowingLiveEdgeCanClearPendingCountAtLatestEvent() async throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(
            gameId: 1302,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1302, playIDs: ["event-1", "event-2"])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1302, playIDs: ["event-1", "event-2", "event-3"]))
                ],
                protocolClass: MockLiveURLProtocol.self
            ),
            gameStateStore: store
        )

        await viewModel.refresh()
        viewModel.recordReadEvent(eventIndex: 0, eventID: "event-1", knownEventCount: 2)
        await viewModel.refresh()
        viewModel.setFollowingLiveEdge(true)
        viewModel.recordLatestEventRead(events: try XCTUnwrap(viewModel.detail).events)

        XCTAssertTrue(viewModel.isFollowingLiveEdge)
        XCTAssertEqual(store.progress(for: 1302)?.lastReadEventID, "event-3")
        XCTAssertEqual(store.progress(for: 1302)?.lastReadEventIndex, 2)
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 0)
    }

    func testResetClassificationPreservesSavedReadPositionInsteadOfStartingOver() async throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let viewModel = GameDetailViewModel(
            gameId: 1303,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1303, playIDs: ["event-1", "event-2", "event-3"])),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 1303, playIDs: ["replacement-1"]))
                ],
                protocolClass: MockLiveURLProtocol.self
            ),
            gameStateStore: store
        )

        await viewModel.refresh()
        viewModel.recordReadEvent(eventIndex: 1, eventID: "event-2", knownEventCount: 3)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.eventDiff.kind, .reset)
        XCTAssertEqual(store.progress(for: 1303)?.lastReadEventID, "event-2")
        XCTAssertEqual(store.progress(for: 1303)?.lastReadEventIndex, 1)
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 0)
    }

    func testReadingAwayRefreshRecomputesUnreadFromSavedCursorAcrossDiffKinds() throws {
        try assertReadingAwayRefresh(
            gameId: 1311,
            current: [
                event(1),
                event(2),
                event(3),
                event(4),
                event(5)
            ],
            expectedKind: .appended,
            expectedUnreadCount: 3,
            expectedReadIndex: 1
        )

        try assertReadingAwayRefresh(
            gameId: 1312,
            current: [
                event(0),
                event(1),
                event(2),
                event(3)
            ],
            expectedKind: .prepended,
            expectedUnreadCount: 1,
            expectedReadIndex: 2
        )

        try assertReadingAwayRefresh(
            gameId: 1313,
            current: [
                event(1),
                event(2),
                event(25),
                event(3)
            ],
            expectedKind: .inserted,
            expectedUnreadCount: 2,
            expectedReadIndex: 1
        )

        try assertReadingAwayRefresh(
            gameId: 1314,
            current: [
                event(1),
                event(2, headline: "Updated saved play"),
                event(3)
            ],
            expectedKind: .modified,
            expectedUnreadCount: 1,
            expectedReadIndex: 1
        )

        try assertReadingAwayRefresh(
            gameId: 1315,
            current: [
                event(99, sourceEventID: "replacement-99")
            ],
            expectedKind: .reset,
            expectedUnreadCount: 0,
            expectedReadIndex: 1
        )
    }

    func testRefreshAloneDoesNotAdvanceFollowerUntilViewConfirmsLiveEdge() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let gameId = 1321
        let initial = [event(1), event(2)]
        store.recordEventRefresh(gameId: gameId, events: initial, diff: .unchanged)
        store.recordReadEvent(gameId: gameId, eventID: "event-2", eventIndex: 1, knownEventCount: initial.count)
        store.setFollowLivePreference(gameId: gameId, preference: .followingLiveEdge)

        let current = [event(1), event(2), event(3)]
        let diff = GameEventListDiffer.diff(
            previous: initial,
            current: current,
            baseline: store.progress(for: gameId)?.eventIdentityBaseline
        )

        store.recordEventRefresh(gameId: gameId, events: current, diff: diff)

        let progress = try XCTUnwrap(store.progress(for: gameId))
        XCTAssertEqual(diff.kind, .appended)
        XCTAssertEqual(progress.lastReadEventID, "event-2")
        XCTAssertEqual(progress.lastReadEventIndex, 1)
        XCTAssertEqual(progress.newEventCount, 1)
    }

    func testFollowingLiveRefreshAdvancesAfterViewConfirmsLiveEdge() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let gameId = 1322
        let initial = [event(1), event(2)]
        let current = [event(1), event(2), event(3)]
        let viewModel = GameDetailViewModel(gameId: gameId, gameStateStore: store)
        store.recordEventRefresh(gameId: gameId, events: initial, diff: .unchanged)
        store.recordReadEvent(gameId: gameId, eventID: "event-2", eventIndex: 1, knownEventCount: initial.count)
        store.setFollowLivePreference(gameId: gameId, preference: .followingLiveEdge)

        let diff = GameEventListDiffer.diff(
            previous: initial,
            current: current,
            baseline: store.progress(for: gameId)?.eventIdentityBaseline
        )
        store.recordEventRefresh(gameId: gameId, events: current, diff: diff)
        viewModel.recordLatestEventRead(events: current)

        let progress = try XCTUnwrap(store.progress(for: gameId))
        XCTAssertEqual(progress.lastReadEventID, "event-3")
        XCTAssertEqual(progress.lastReadEventIndex, 2)
        XCTAssertEqual(progress.newEventCount, 0)
    }

    func testLiveRefreshFollowDecisionRequiresNearLiveEdgeAndPreference() {
        XCTAssertTrue(GameDetailScrollLogic.shouldFollowLiveRefresh(
            isLive: true,
            isFollowingLiveEdge: true,
            isNearLiveEdge: true
        ))
        XCTAssertFalse(GameDetailScrollLogic.shouldFollowLiveRefresh(
            isLive: true,
            isFollowingLiveEdge: true,
            isNearLiveEdge: false
        ))
        XCTAssertFalse(GameDetailScrollLogic.shouldFollowLiveRefresh(
            isLive: true,
            isFollowingLiveEdge: false,
            isNearLiveEdge: true
        ))
        XCTAssertFalse(GameDetailScrollLogic.shouldFollowLiveRefresh(
            isLive: false,
            isFollowingLiveEdge: true,
            isNearLiveEdge: true
        ))
    }

    func testRefreshRestoreDecisionIncludesModifiedAndStructuralDiffs() {
        XCTAssertTrue(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.inserted))
        XCTAssertTrue(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.prepended))
        XCTAssertTrue(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.modified))
        XCTAssertTrue(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.reset))
        XCTAssertFalse(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.appended))
        XCTAssertFalse(GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(.unchanged))
    }

    private func assertReadingAwayRefresh(
        gameId: Int,
        current: [GameEvent],
        expectedKind: GameEventListChangeKind,
        expectedUnreadCount: Int,
        expectedReadIndex: Int
    ) throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let initial = [event(1), event(2), event(3)]
        store.recordEventRefresh(gameId: gameId, events: initial, diff: .unchanged)
        store.recordReadEvent(gameId: gameId, eventID: "event-2", eventIndex: 1, knownEventCount: initial.count)
        store.setFollowLivePreference(gameId: gameId, preference: .readingAwayFromLiveEdge)

        let diff = GameEventListDiffer.diff(
            previous: initial,
            current: current,
            baseline: store.progress(for: gameId)?.eventIdentityBaseline
        )
        store.recordEventRefresh(gameId: gameId, events: current, diff: diff)

        let progress = try XCTUnwrap(store.progress(for: gameId))
        XCTAssertEqual(diff.kind, expectedKind)
        XCTAssertEqual(progress.lastReadEventID, "event-2")
        XCTAssertEqual(progress.lastReadEventIndex, expectedReadIndex)
        XCTAssertEqual(progress.newEventCount, expectedUnreadCount)
        XCTAssertGreaterThanOrEqual(progress.newEventCount, 0)
    }

    private func event(
        _ sequence: Int,
        sourceEventID: String? = nil,
        headline: String? = nil
    ) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            sourceEventID: sourceEventID ?? "event-\(sequence)",
            headline: headline
        )
    }
}

private final class MockLiveURLProtocol: MockHTTPURLProtocol {}
