import Combine
import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class AppScenePhaseHandlerTests: XCTestCase {
    func testActivePhaseCancelsPendingRefreshOnly() {
        let store = RecordingGameStateStore()
        let scheduler = RecordingBackgroundRefreshScheduler()
        let handler = AppScenePhaseHandler(gameStateStore: store, scheduler: scheduler, now: Date.init)

        handler.handle(.active)

        XCTAssertEqual(scheduler.cancelCount, 1)
        XCTAssertEqual(scheduler.scheduleCount, 0)
        XCTAssertEqual(store.pruneDates, [])
    }

    func testBackgroundPhasePrunesAndSchedulesRefresh() {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let store = RecordingGameStateStore()
        let scheduler = RecordingBackgroundRefreshScheduler()
        let handler = AppScenePhaseHandler(gameStateStore: store, scheduler: scheduler, now: { now })

        handler.handle(.background)

        XCTAssertEqual(store.pruneDates, [now])
        XCTAssertEqual(scheduler.scheduleCount, 1)
        XCTAssertEqual(scheduler.cancelCount, 0)
    }

    func testInactivePhaseDoesNothing() {
        let store = RecordingGameStateStore()
        let scheduler = RecordingBackgroundRefreshScheduler()
        let handler = AppScenePhaseHandler(gameStateStore: store, scheduler: scheduler, now: Date.init)

        handler.handle(.inactive)

        XCTAssertEqual(store.pruneDates, [])
        XCTAssertEqual(scheduler.scheduleCount, 0)
        XCTAssertEqual(scheduler.cancelCount, 0)
    }
}

@MainActor
private final class RecordingBackgroundRefreshScheduler: BackgroundRefreshScheduling {
    private(set) var scheduleCount = 0
    private(set) var cancelCount = 0

    func scheduleRefresh() {
        scheduleCount += 1
    }

    func cancelPendingRefresh() {
        cancelCount += 1
    }
}

@MainActor
private final class RecordingGameStateStore: GameStateStore {
    private let base = InMemoryGameStateStore()
    private(set) var pruneDates: [Date] = []

    var snapshot: LocalGameStateSnapshot {
        base.snapshot
    }

    var snapshots: AnyPublisher<LocalGameStateSnapshot, Never> {
        base.snapshots
    }

    func pin(_ game: Game) {
        base.pin(game)
    }

    func unpin(gameId: Int) {
        base.unpin(gameId: gameId)
    }

    func updatePinnedGame(_ game: Game) {
        base.updatePinnedGame(game)
    }

    func saveHomeSnapshot(games: [Game], windowKey: String, fetchedAt: Date) {
        base.saveHomeSnapshot(games: games, windowKey: windowKey, fetchedAt: fetchedAt)
    }

    func updatePinnedGameDetail(_ detail: GameDetail, fetchedAt: Date) {
        base.updatePinnedGameDetail(detail, fetchedAt: fetchedAt)
    }

    func recordPinnedGameRefreshFailure(gameId: Int, message: String, at: Date) {
        base.recordPinnedGameRefreshFailure(gameId: gameId, message: message, at: at)
    }

    func recordBackgroundRefresh(_ record: BackgroundRefreshRecord) {
        base.recordBackgroundRefresh(record)
    }

    func markViewed(gameId: Int) {
        base.markViewed(gameId: gameId)
    }

    func recordKnownEventCount(gameId: Int, count: Int) {
        base.recordKnownEventCount(gameId: gameId, count: count)
    }

    func recordEventRefresh(gameId: Int, events: [GameEvent], diff: GameEventListDiff) {
        base.recordEventRefresh(gameId: gameId, events: events, diff: diff)
    }

    func recordReadEvent(gameId: Int, eventID: String?, eventIndex: Int?, knownEventCount: Int?) {
        base.recordReadEvent(gameId: gameId, eventID: eventID, eventIndex: eventIndex, knownEventCount: knownEventCount)
    }

    func clearReadPosition(gameId: Int) {
        base.clearReadPosition(gameId: gameId)
    }

    func setSelectedMode(gameId: Int, mode: GameMode) {
        base.setSelectedMode(gameId: gameId, mode: mode)
    }

    func setScrollFallback(gameId: Int, fallback: GameScrollFallbackRecord?) {
        base.setScrollFallback(gameId: gameId, fallback: fallback)
    }

    func setExpandedSectionIDs(gameId: Int, sectionIDs: Set<String>) {
        base.setExpandedSectionIDs(gameId: gameId, sectionIDs: sectionIDs)
    }

    func setRawFeedExpanded(gameId: Int, key: String, isExpanded: Bool) {
        base.setRawFeedExpanded(gameId: gameId, key: key, isExpanded: isExpanded)
    }

    func setReachedScoreboard(gameId: Int, reached: Bool) {
        base.setReachedScoreboard(gameId: gameId, reached: reached)
    }

    func setFollowLivePreference(gameId: Int, preference: FollowLivePreference) {
        base.setFollowLivePreference(gameId: gameId, preference: preference)
    }

    func prune(now: Date) {
        pruneDates.append(now)
        base.prune(now: now)
    }
}
