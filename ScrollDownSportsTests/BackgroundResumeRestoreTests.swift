import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class BackgroundResumeRestoreTests: XCTestCase {
    func testBackgroundAndReopenResumeToPersistedEventCard() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T16:00:00Z") })
        let scheduler = BackgroundResumeRestoreScheduler()
        let game = TestFixtures.makeGame(id: 3006, status: "final", isLive: false, isFinal: true, eventCount: 9)
        let events = makeEvents(count: 9)
        let readEvent = events[4]
        let firstOpen = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        firstOpen.detail = TestFixtures.makeDetail(game: game, events: events)
        firstOpen.setSelectedStreamMode(.full)
        firstOpen.recordReadEvent(eventIndex: 4, eventID: readEvent.id, knownEventCount: events.count)
        firstOpen.recordScrollFallback(eventSequence: readEvent.sequence, approximateOffset: 320)

        let handler = AppScenePhaseHandler(
            gameStateStore: store,
            scheduler: scheduler,
            now: { TestFixtures.fixedDate("2026-05-22T16:05:00Z") }
        )
        handler.handle(.background)

        let reopened = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        reopened.detail = TestFixtures.makeDetail(game: game, events: events)
        let target = try XCTUnwrap(GameDetailRestoreTargetResolver.targetEvent(
            progress: try XCTUnwrap(reopened.localProgress),
            events: events,
            mode: reopened.selectedStreamMode
        ))

        XCTAssertEqual(scheduler.scheduleCount, 1)
        XCTAssertEqual(target.detailAnchorID, readEvent.detailAnchorID)
    }

    private func makeEvents(count: Int) -> [GameEvent] {
        (1...count).map { sequence in
            TestFixtures.makeEvent(
                sequence: sequence,
                sourceEventID: "event-\(sequence)",
                importance: sequence.isMultiple(of: 3) ? .primary : .secondary,
                periodLabel: "Q\(max(1, (sequence + 2) / 3))",
                clockLabel: "\(12 - sequence):00"
            )
        }
    }
}

@MainActor
private final class BackgroundResumeRestoreScheduler: BackgroundRefreshScheduling {
    private(set) var scheduleCount = 0

    func scheduleRefresh() {
        scheduleCount += 1
    }

    func cancelPendingRefresh() {}
}
