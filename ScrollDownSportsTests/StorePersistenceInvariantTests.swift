import XCTest
@testable import ScrollDownSports

@MainActor
final class StorePersistenceInvariantTests: XCTestCase {
    func testPinUnpinAndRepeatedPinPersistWithoutDuplicateRecords() throws {
        let suiteName = "StorePersistenceInvariantTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var currentDate = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let game = TestFixtures.makeGame(id: 1201)
        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "state",
            now: { currentDate }
        )

        store.pin(game)
        currentDate = TestFixtures.fixedDate("2026-05-22T12:05:00Z")
        store.pin(game)

        var reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "state",
            now: { currentDate }
        )
        XCTAssertEqual(reloaded.snapshot.pinnedGamesById.count, 1)
        XCTAssertEqual(reloaded.snapshot.pinnedGamesById[game.id]?.pinnedAt, TestFixtures.fixedDate("2026-05-22T12:00:00Z"))
        XCTAssertTrue(reloaded.isPinned(gameId: game.id))

        reloaded.unpin(gameId: game.id)
        reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "state",
            now: { currentDate }
        )

        XCTAssertFalse(reloaded.isPinned(gameId: game.id))
        XCTAssertTrue(reloaded.snapshot.pinnedGamesById.isEmpty)
    }

    func testProgressFieldsAndViewedTimestampsPersistAcrossReloads() throws {
        let suiteName = "StoreProgressInvariantTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var currentDate = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "state",
            now: { currentDate }
        )

        store.markViewed(gameId: 1202)
        currentDate = TestFixtures.fixedDate("2026-05-22T12:10:00Z")
        store.markViewed(gameId: 1202)
        store.recordReadEvent(gameId: 1202, eventID: "event-4", eventIndex: 4, knownEventCount: 9)
        store.setSelectedMode(gameId: 1202, mode: .flow)
        store.setExpandedSectionIDs(gameId: 1202, sectionIDs: ["player-stats", "team-stats"])
        store.setRawFeedExpanded(gameId: 1202, key: "raw:event-4", isExpanded: true)
        store.setReachedScoreboard(gameId: 1202, reached: true)

        let reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "state",
            now: { currentDate }
        )
        let progress = try XCTUnwrap(reloaded.progress(for: 1202))

        XCTAssertEqual(progress.firstViewedAt, TestFixtures.fixedDate("2026-05-22T12:00:00Z"))
        XCTAssertEqual(progress.lastViewedAt, TestFixtures.fixedDate("2026-05-22T12:10:00Z"))
        XCTAssertEqual(progress.lastReadEventID, "event-4")
        XCTAssertEqual(progress.lastReadEventIndex, 4)
        XCTAssertEqual(progress.newEventCount, 4)
        XCTAssertEqual(progress.selectedMode, .flow)
        XCTAssertEqual(progress.expandedSectionIDs, ["player-stats", "team-stats"])
        XCTAssertEqual(progress.expandedRawFeedKeys, ["raw:event-4"])
        XCTAssertTrue(progress.reachedScoreboard)
    }
}
