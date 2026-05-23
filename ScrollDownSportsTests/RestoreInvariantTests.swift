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

    func testMissingSavedEventFallsBackThroughIndexSequenceThenFirstVisibleEvent() {
        let events = [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "event-10", importance: .primary),
            TestFixtures.makeEvent(sequence: 20, sourceEventID: "event-20", importance: .secondary),
            TestFixtures.makeEvent(sequence: 30, sourceEventID: "event-30", importance: .contextual)
        ]

        var indexProgress = GameProgressRecord.empty(gameId: 1603, now: TestFixtures.fixedDate())
        indexProgress.lastReadEventID = "missing-event"
        indexProgress.lastReadEventIndex = 2
        indexProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 20, approximateOffset: nil)
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: indexProgress, events: events, mode: .key)?.id,
            "event-30"
        )

        var exactSequenceProgress = GameProgressRecord.empty(gameId: 1604, now: TestFixtures.fixedDate())
        exactSequenceProgress.lastReadEventID = "missing-event"
        exactSequenceProgress.lastReadEventIndex = 9
        exactSequenceProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 20, approximateOffset: nil)
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: exactSequenceProgress, events: events, mode: .key)?.id,
            "event-20"
        )

        var nearestSequenceProgress = GameProgressRecord.empty(gameId: 1605, now: TestFixtures.fixedDate())
        nearestSequenceProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 25, approximateOffset: nil)
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: nearestSequenceProgress, events: events, mode: .key)?.id,
            "event-30"
        )

        let emptyProgress = GameProgressRecord.empty(gameId: 1606, now: TestFixtures.fixedDate())
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: emptyProgress, events: events, mode: .key)?.id,
            "event-10"
        )
    }

    func testResumeDescriptionUsesCleanPositionCopyWithoutDuplicatedPeriodText() {
        let event = TestFixtures.makeEvent(
            sequence: 1,
            sourceEventID: "event-1",
            importance: .primary,
            periodLabel: "3rd",
            clockLabel: "3rd"
        )

        XCTAssertEqual(
            GameDetailRestoreTargetResolver.resumeDescription(target: event, newPlayCount: 0),
            "Resume from 3rd"
        )
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.resumeDescription(target: event, newPlayCount: 2),
            "Resume from 3rd · 2 new"
        )
    }
}
