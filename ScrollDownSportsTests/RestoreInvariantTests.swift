import XCTest
@testable import ScrollDownSports

final class RestoreInvariantTests: XCTestCase {
    func testMissingSavedEventFallsBackToNearestPersistedPosition() {
        let events = [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "event-10", importance: .primary),
            TestFixtures.makeEvent(sequence: 20, sourceEventID: "event-20", importance: .secondary),
            TestFixtures.makeEvent(sequence: 30, sourceEventID: "event-30", importance: .contextual)
        ]
        var progress = GameProgressRecord.empty(gameId: 1601, now: TestFixtures.fixedDate())
        progress.lastReadEventID = "missing-event"
        progress.lastReadEventIndex = 1
        progress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 25, approximateOffset: 120)

        let target = GameDetailRestoreTargetResolver.targetEvent(
            progress: progress,
            events: events,
            mode: .key
        )

        XCTAssertEqual(target?.id, "event-20")
    }

    func testSavedEventHiddenBySelectedModeRequestsFullStreamReveal() {
        let hidden = TestFixtures.makeEvent(sequence: 2, sourceEventID: "event-2", importance: .contextual)
        let events = [
            TestFixtures.makeEvent(sequence: 1, sourceEventID: "event-1", importance: .primary),
            hidden
        ]

        XCTAssertEqual(
            GameDetailRestoreTargetResolver.streamModeToReveal(target: hidden, currentMode: .key, events: events),
            .full
        )
    }
}
