import XCTest
@testable import ScrollDownSports

@MainActor
final class FixtureDataBoundaryTests: XCTestCase {
    func testPersistedHomeSnapshotDropsSyntheticTeamsAndKeepsRealGames() throws {
        let defaults = try makeDefaults()
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        var snapshot = LocalGameStateSnapshot.empty(now: now)
        let realGame = realHomeGame(id: 301, now: now)
        snapshot.saveHomeSnapshot(
            games: [syntheticGame(id: 302, awayName: "Dallas Wolves", homeName: "Seattle Sound", now: now), realGame],
            windowKey: GameWindow.home(now: now).stableKey,
            fetchedAt: now
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        defaults.set(try encoder.encode(snapshot), forKey: "fixture-boundary-test")

        let store = UserDefaultsGameStateStore(defaults: defaults, key: "fixture-boundary-test", now: { now })
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)

        XCTAssertEqual(store.snapshot.homeSnapshot?.games.map(\.id), [realGame.id])
        XCTAssertEqual(HomeSectionTestHelpers.allTimelineIDs(in: viewModel.filteredHomeSections), [realGame.id])
    }

    func testRuntimeHomeSnapshotSaveFiltersSyntheticTeamsBeforePublishing() throws {
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let realGame = realHomeGame(id: 311, now: now)

        store.saveHomeSnapshot(
            games: [
                syntheticGame(id: 312, awayName: "New York Knights", homeName: "Bay City Bridges", now: now),
                realGame
            ],
            windowKey: GameWindow.home(now: now).stableKey,
            fetchedAt: now
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)

        XCTAssertEqual(store.snapshot.homeSnapshot?.games.map(\.id), [realGame.id])
        XCTAssertEqual(HomeSectionTestHelpers.allTimelineIDs(in: viewModel.filteredHomeSections), [realGame.id])
    }

    func testRuntimePinnedMutationsDoNotPublishSyntheticPinnedState() throws {
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let realGame = realHomeGame(id: 321, now: now)

        store.pin(syntheticGame(id: 320, awayName: "Dallas Wolves", homeName: "Seattle Sound", now: now))
        XCTAssertTrue(store.snapshot.pinnedGamesById.isEmpty)

        store.pin(realGame)
        store.updatePinnedGame(syntheticGame(id: realGame.id, awayName: "New York Knights", homeName: "Bay City Bridges", now: now))

        XCTAssertFalse(store.isPinned(gameId: realGame.id))
        XCTAssertNil(store.progress(for: realGame.id))
    }

    func testDetailEventMarkersRemovePinnedStateWithRealTeamNames() throws {
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let rawFeedStore = InMemoryGameStateStore(now: { now })
        let sourceIDStore = InMemoryGameStateStore(now: { now })
        let rawFeedGame = realHomeGame(id: 331, now: now)
        let sourceIDGame = realHomeGame(id: 332, now: now)

        rawFeedStore.pin(rawFeedGame)
        rawFeedStore.updatePinnedGameDetail(
            TestFixtures.makeDetail(
                game: rawFeedGame,
                events: [TestFixtures.makeEvent(sequence: 1, sourceEventID: "provider-1", rawFeedSource: " Fixture ")]
            ),
            fetchedAt: now
        )
        sourceIDStore.pin(sourceIDGame)
        sourceIDStore.updatePinnedGameDetail(
            TestFixtures.makeDetail(
                game: sourceIDGame,
                events: [TestFixtures.makeEvent(sequence: 1, sourceEventID: " fixture-provider-1 ")]
            ),
            fetchedAt: now
        )

        XCTAssertFalse(rawFeedStore.isPinned(gameId: rawFeedGame.id))
        XCTAssertNil(rawFeedStore.progress(for: rawFeedGame.id))
        XCTAssertFalse(sourceIDStore.isPinned(gameId: sourceIDGame.id))
        XCTAssertNil(sourceIDStore.progress(for: sourceIDGame.id))
    }

    func testSyntheticNameDetectionNormalizesCaseWhitespaceAndMixedState() throws {
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let realGame = realHomeGame(id: 341, now: now)

        store.saveHomeSnapshot(
            games: [
                syntheticGame(id: 342, awayName: "  dALLas WOLVES  ", homeName: "Seattle Mariners", now: now),
                syntheticGame(id: 343, awayName: "New York Yankees", homeName: "\nBAY CITY BRIDGES\t", now: now),
                realGame
            ],
            windowKey: GameWindow.home(now: now).stableKey,
            fetchedAt: now
        )

        XCTAssertEqual(store.snapshot.homeSnapshot?.games.map(\.id), [realGame.id])
    }

    private func syntheticGame(id: Int, awayName: String, homeName: String, now: Date) -> Game {
        TestFixtures.makeGame(
            id: id,
            leagueCode: "mlb",
            scheduledStart: now,
            awayName: awayName,
            awayAbbreviation: "AWY",
            homeName: homeName,
            homeAbbreviation: "HME"
        )
    }

    private func realHomeGame(id: Int, now: Date) -> Game {
        TestFixtures.makeGame(
            id: id,
            leagueCode: "mlb",
            scheduledStart: now,
            awayName: "New York Yankees",
            awayAbbreviation: "NYY",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA"
        )
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "com.dock108.scrolldownsports.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
