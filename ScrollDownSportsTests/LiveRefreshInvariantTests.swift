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
}

private final class MockLiveURLProtocol: MockHTTPURLProtocol {}
