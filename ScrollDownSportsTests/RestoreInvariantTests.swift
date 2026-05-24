import XCTest
@testable import ScrollDownSports

final class RestoreInvariantTests: XCTestCase {
    func testDetailScrollLogicResolvesReadSequenceVisibleCandidateAndScoreReadiness() {
        let events = [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "event-10", importance: .primary),
            TestFixtures.makeEvent(sequence: 20, sourceEventID: "event-20", importance: .secondary),
            TestFixtures.makeEvent(sequence: 30, sourceEventID: "event-30", importance: .contextual)
        ]

        var eventIDProgress = GameProgressRecord.empty(gameId: 1590, now: TestFixtures.fixedDate())
        eventIDProgress.lastReadEventID = events[1].detailAnchorID
        XCTAssertEqual(GameDetailScrollLogic.readSequence(progress: eventIDProgress, events: events), 20)

        var indexProgress = GameProgressRecord.empty(gameId: 1591, now: TestFixtures.fixedDate())
        indexProgress.lastReadEventIndex = 2
        XCTAssertEqual(GameDetailScrollLogic.readSequence(progress: indexProgress, events: events), 30)

        var fallbackProgress = GameProgressRecord.empty(gameId: 1592, now: TestFixtures.fixedDate())
        fallbackProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 18, approximateOffset: 120)
        XCTAssertEqual(GameDetailScrollLogic.readSequence(progress: fallbackProgress, events: events), 18)

        let visible = GameDetailScrollLogic.visibleCandidate(
            from: [
                DetailEventVisibilityFrame(
                    anchorID: "hidden",
                    readIndex: 0,
                    sequence: 1,
                    eventID: nil,
                    label: "Hidden",
                    frame: CGRect(x: 0, y: 220, width: 320, height: 80)
                ),
                DetailEventVisibilityFrame(
                    anchorID: "near-top",
                    readIndex: 1,
                    sequence: 2,
                    eventID: "event-2",
                    label: "",
                    frame: CGRect(x: 0, y: -12, width: 320, height: 80)
                ),
                DetailEventVisibilityFrame(
                    anchorID: "below",
                    readIndex: 2,
                    sequence: 3,
                    eventID: "event-3",
                    label: "Below",
                    frame: CGRect(x: 0, y: 60, width: 320, height: 80)
                )
            ],
            viewportHeight: 160
        )
        XCTAssertEqual(visible?.anchorID, "near-top")
        XCTAssertEqual(DetailVisibleEventState(frame: visible!).label, "spot")

        XCTAssertTrue(GameDetailScrollLogic.hasFinalScore(for: TestFixtures.makeGame(status: "final", isLive: false, isFinal: true)))
        XCTAssertFalse(GameDetailScrollLogic.hasFinalScore(for: TestFixtures.makeGame(awayScore: nil, homeScore: nil)))
    }

    func testDetailScrollLogicRestoresNearestVisibleAnchorAcrossModeChanges() {
        let events = [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "event-10", importance: .primary),
            TestFixtures.makeEvent(sequence: 20, sourceEventID: "event-20", importance: .secondary),
            TestFixtures.makeEvent(sequence: 30, sourceEventID: "event-30", importance: .contextual)
        ]

        XCTAssertEqual(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: events[0].detailAnchorID,
                from: .key,
                to: .full,
                events: events
            ),
            events[0].detailAnchorID
        )
        XCTAssertEqual(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: nil,
                from: .key,
                to: .flow,
                events: events
            ),
            events[0].detailAnchorID
        )
        XCTAssertEqual(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: events[2].detailAnchorID,
                from: .full,
                to: .key,
                events: events
            ),
            events[0].detailAnchorID
        )
        XCTAssertNil(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: nil,
                from: .full,
                to: .key,
                events: []
            )
        )
    }

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
