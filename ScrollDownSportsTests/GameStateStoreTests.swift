import XCTest
@testable import ScrollDownSports

@MainActor
final class GameStateStoreTests: XCTestCase {
    func testPinsPersistWithRenderableMetadataAndFollowPreference() throws {
        let defaults = try makeDefaults()
        let baseDate = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        var currentDate = baseDate
        let game = TestFixtures.makeGame(
            id: 42,
            leagueCode: "mlb",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:10:00Z")
        )

        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { currentDate }
        )

        store.pin(game)
        currentDate = TestFixtures.fixedDate("2026-05-22T12:05:00Z")
        store.recordKnownEventCount(gameId: game.id, count: 12)
        store.recordReadEvent(gameId: game.id, eventID: "play-8", eventIndex: 8, knownEventCount: 12)
        store.setFollowLivePreference(gameId: game.id, preference: .pinnedToLiveEdge)

        let reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { currentDate }
        )
        let record = try XCTUnwrap(reloaded.snapshot.pinnedGamesById[game.id])

        XCTAssertTrue(record.isPinned)
        XCTAssertEqual(record.pinnedAt, baseDate)
        XCTAssertEqual(record.sportCode, "mlb")
        XCTAssertEqual(record.leagueCode, "mlb")
        XCTAssertEqual(record.homeTeam, "Seattle Mariners")
        XCTAssertEqual(record.awayTeam, "New York Yankees")
        XCTAssertEqual(record.lastReadEventID, "play-8")
        XCTAssertEqual(record.lastReadEventIndex, 8)
        XCTAssertEqual(record.newEventCount, 3)
        XCTAssertEqual(record.followLivePreference, .pinnedToLiveEdge)
    }

    func testBackgroundDetailStatePersistsThroughUserDefaultsReload() throws {
        let defaults = try makeDefaults()
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let game = TestFixtures.makeGame(
            id: 43,
            leagueCode: "mlb",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:10:00Z")
        )
        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { now }
        )
        store.pin(game)
        store.updatePinnedGameDetail(
            GameDetail(
                game: game,
                teamStats: [],
                playerStats: [],
                events: [TestFixtures.makeEvent(sequence: 1, sourceEventID: "play-1")],
                mlbBatters: nil,
                mlbPitchers: nil,
                nhlSkaters: nil,
                nhlGoalies: nil
            ),
            fetchedAt: now
        )

        let reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { now }
        )
        let record = try XCTUnwrap(reloaded.snapshot.pinnedGamesById[game.id])

        XCTAssertEqual(record.latestDetail?.events.map(\.id), ["play-1"])
        XCTAssertEqual(record.latestPlayCursor?.sequence, 1)
        XCTAssertEqual(record.lastSeenPlayCursor?.sequence, 1)
        XCTAssertEqual(record.newEventCount, 0)
    }

    func testProgressPersistsReaderStateIndependentlyFromPinnedState() throws {
        let defaults = try makeDefaults()
        let openedAt = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        var currentDate = openedAt
        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { currentDate }
        )

        store.markViewed(gameId: 77)
        currentDate = TestFixtures.fixedDate("2026-05-22T12:03:00Z")
        store.setSelectedMode(gameId: 77, mode: .scoreboard)
        store.setScrollFallback(
            gameId: 77,
            fallback: GameScrollFallbackRecord(eventSequence: 14, approximateOffset: 128.5)
        )
        store.setExpandedSectionIDs(gameId: 77, sectionIDs: ["team-stats", "box-score"])
        store.setRawFeedExpanded(gameId: 77, key: "raw-feed:v1:nba:77:event-14:123", isExpanded: true)
        store.setReachedScoreboard(gameId: 77, reached: true)
        store.setFollowLivePreference(gameId: 77, preference: .readingAwayFromLiveEdge)
        store.recordReadEvent(gameId: 77, eventID: "event-14", eventIndex: 14, knownEventCount: 20)

        let reloaded = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { currentDate }
        )
        let progress = try XCTUnwrap(reloaded.progress(for: 77))

        XCTAssertNil(reloaded.snapshot.pinnedGamesById[77])
        XCTAssertEqual(progress.selectedMode, .scoreboard)
        XCTAssertEqual(progress.firstViewedAt, openedAt)
        XCTAssertEqual(progress.lastViewedAt, openedAt)
        XCTAssertEqual(progress.lastReadEventID, "event-14")
        XCTAssertEqual(progress.lastReadEventIndex, 14)
        XCTAssertEqual(progress.lastScrollFallback?.eventSequence, 14)
        XCTAssertEqual(progress.lastScrollFallback?.approximateOffset, 128.5)
        XCTAssertEqual(progress.expandedSectionIDs, ["team-stats", "box-score"])
        XCTAssertEqual(progress.expandedRawFeedKeys, ["raw-feed:v1:nba:77:event-14:123"])
        XCTAssertTrue(progress.reachedScoreboard)
        XCTAssertEqual(progress.followLivePreference, .readingAwayFromLiveEdge)
        XCTAssertEqual(progress.newEventCount, 5)
    }

    func testCorruptPersistedDataFallsBackToEmptySnapshot() throws {
        let defaults = try makeDefaults()
        defaults.set(Data("not-json".utf8), forKey: "game-state-test")

        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") }
        )

        XCTAssertTrue(store.snapshot.pinnedGamesById.isEmpty)
        XCTAssertTrue(store.snapshot.progressByGameId.isEmpty)
        XCTAssertNil(defaults.data(forKey: "game-state-test"))
    }

    func testFixturePinnedDataIsPurgedFromPersistedState() throws {
        let defaults = try makeDefaults()
        let now = TestFixtures.fixedDate("2026-05-22T12:00:00Z")
        let fakeGame = TestFixtures.makeGame(
            id: 101,
            leagueCode: "nfl",
            scheduledStart: now,
            awayName: "Dallas Wolves",
            awayAbbreviation: "DAL",
            homeName: "Seattle Sound",
            homeAbbreviation: "SEA"
        )
        var snapshot = LocalGameStateSnapshot.empty(now: now)
        snapshot.pin(fakeGame, now: { now }, preserveMirroredProgressFields: true)
        snapshot.recordReadEvent(gameId: fakeGame.id, eventID: "fixture-1", eventIndex: 0, knownEventCount: 4, now: { now })

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        defaults.set(try encoder.encode(snapshot), forKey: "game-state-test")

        let store = UserDefaultsGameStateStore(
            defaults: defaults,
            key: "game-state-test",
            now: { now }
        )

        XCTAssertTrue(store.snapshot.pinnedGamesById.isEmpty)
        XCTAssertTrue(store.snapshot.progressByGameId.isEmpty)
    }

    func testRawFeedExpansionCanCollapseAndUsesProgressDefaults() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let key = "raw-feed:v1:mlb:301:event-1:456"

        store.setRawFeedExpanded(gameId: 301, key: key, isExpanded: true)
        XCTAssertEqual(store.progress(for: 301)?.expandedRawFeedKeys, [key])

        store.setRawFeedExpanded(gameId: 301, key: key, isExpanded: false)
        XCTAssertEqual(store.progress(for: 301)?.expandedRawFeedKeys, [])
    }

    func testInMemoryStoreMirrorsPinnedProgressFields() throws {
        let game = TestFixtures.makeGame(
            id: 101,
            leagueCode: "nba",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:30:00Z")
        )
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.pin(game)
        store.recordReadEvent(gameId: game.id, eventID: "made-shot", eventIndex: 2, knownEventCount: 4)

        let record = try XCTUnwrap(store.snapshot.pinnedGamesById[game.id])
        XCTAssertEqual(record.lastReadEventID, "made-shot")
        XCTAssertEqual(record.lastReadEventIndex, 2)
        XCTAssertEqual(record.newEventCount, 1)
    }

    func testStartOverClearsReadPositionWithoutRemovingPinOrScoreboardState() throws {
        let game = TestFixtures.makeGame(
            id: 102,
            leagueCode: "nba",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:30:00Z")
        )
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.pin(game)
        store.recordReadEvent(gameId: game.id, eventID: "made-shot", eventIndex: 2, knownEventCount: 4)
        store.setScrollFallback(
            gameId: game.id,
            fallback: GameScrollFallbackRecord(eventSequence: 12, approximateOffset: 44)
        )
        store.setReachedScoreboard(gameId: game.id, reached: true)

        store.clearReadPosition(gameId: game.id)

        let progress = try XCTUnwrap(store.progress(for: game.id))
        XCTAssertTrue(store.isPinned(gameId: game.id))
        XCTAssertNil(progress.lastReadEventID)
        XCTAssertNil(progress.lastReadEventIndex)
        XCTAssertNil(progress.lastScrollFallback)
        XCTAssertTrue(progress.reachedScoreboard)
        XCTAssertNil(store.snapshot.pinnedGamesById[game.id]?.lastReadEventID)
        XCTAssertNil(store.snapshot.pinnedGamesById[game.id]?.lastReadEventIndex)
    }

    func testStartOverKeepsModeAndUnrelatedPreferences() throws {
        let game = TestFixtures.makeGame(
            id: 103,
            leagueCode: "nba",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:30:00Z")
        )
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.pin(game)
        store.setSelectedMode(gameId: game.id, mode: .flow)
        store.setFollowLivePreference(gameId: game.id, preference: .readingAwayFromLiveEdge)
        store.setExpandedSectionIDs(gameId: game.id, sectionIDs: ["player-stats"])
        store.setRawFeedExpanded(gameId: game.id, key: "raw-feed:v1:nba:103:event-2:1", isExpanded: true)
        store.recordReadEvent(gameId: game.id, eventID: "made-shot", eventIndex: 2, knownEventCount: 4)

        store.clearReadPosition(gameId: game.id)

        let progress = try XCTUnwrap(store.progress(for: game.id))
        XCTAssertEqual(progress.selectedMode, .flow)
        XCTAssertEqual(progress.followLivePreference, .readingAwayFromLiveEdge)
        XCTAssertEqual(progress.expandedSectionIDs, ["player-stats"])
        XCTAssertEqual(progress.expandedRawFeedKeys, ["raw-feed:v1:nba:103:event-2:1"])
        XCTAssertTrue(store.isPinned(gameId: game.id))
        XCTAssertNil(progress.lastReadEventID)
        XCTAssertNil(progress.lastReadEventIndex)
        XCTAssertNil(progress.lastScrollFallback)
    }

    func testReachedScoreboardIsMonotonicOncePersisted() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.setReachedScoreboard(gameId: 104, reached: true)
        store.setReachedScoreboard(gameId: 104, reached: false)

        XCTAssertTrue(store.progress(for: 104)?.reachedScoreboard == true)
    }

    func testScoreboardViewportEntryRequiresMeaningfulVisibility() {
        let viewport = CGRect(x: 0, y: 0, width: 390, height: 800)

        XCTAssertFalse(hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 780, width: 390, height: 200),
            viewportFrame: viewport
        ))
        XCTAssertTrue(hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 740, width: 390, height: 200),
            viewportFrame: viewport
        ))
        XCTAssertFalse(hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 700, width: 390, height: 0),
            viewportFrame: viewport
        ))
    }

    func testStableEventIdentityUsesSourceEventIDBeforeDisplayText() {
        let previous = [
            TestFixtures.makeEvent(sequence: 1, sourceEventID: " event-1 ", headline: "Made jumper", clockLabel: "11:42", homeScore: 2)
        ]
        let current = [
            TestFixtures.makeEvent(sequence: 1, sourceEventID: "event-1", headline: "Made three", clockLabel: "11:39", homeScore: 3)
        ]

        let diff = GameEventListDiffer.diff(previous: previous, current: current)

        XCTAssertEqual(previous[0].diffKey.kind, .sourceEventID)
        XCTAssertEqual(previous[0].diffKey.value, "event-1")
        XCTAssertEqual(diff.kind, .modified)
        XCTAssertTrue(diff.insertedEvents.isEmpty)
        XCTAssertEqual(diff.modifiedEvents.map(\.sequence), [1])
    }

    func testPlayIndexFallbackBridgesLateSourceEventID() {
        let previous = [TestFixtures.makeEvent(sequence: 21, sourceEventID: nil)]
        let current = [TestFixtures.makeEvent(sequence: 21, sourceEventID: "provider-21")]
        let baseline = GameEventIdentityBaseline(events: previous)

        let diff = GameEventListDiffer.diff(previous: previous, current: current, baseline: baseline)

        XCTAssertEqual(previous[0].diffKey.kind, .sequence)
        XCTAssertEqual(diff.kind, .modified)
        XCTAssertTrue(diff.insertedEvents.isEmpty)
    }

    func testPinnedSummaryCountsOnlyPositiveEligibleDeltas() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let game = TestFixtures.makeGame(
            id: 202,
            leagueCode: "mlb",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:10:00Z"),
            eventCount: 10
        )

        store.pin(game)
        store.updatePinnedGame(TestFixtures.makeGame(id: 202, leagueCode: "mlb", scheduledStart: game.scheduledStart, eventCount: 13))
        store.updatePinnedGame(TestFixtures.makeGame(id: 202, leagueCode: "mlb", scheduledStart: game.scheduledStart, eventCount: 13))

        let record = try XCTUnwrap(store.snapshot.pinnedGamesById[202])
        XCTAssertEqual(record.newEventCount, 3)
        XCTAssertEqual(record.summaryPlayCountBaseline, 13)
    }

    func testPinnedSummaryDecreaseMissingAndPregameDoNotEmitCounts() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let liveGame = TestFixtures.makeGame(
            id: 203,
            leagueCode: "nba",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:30:00Z"),
            eventCount: 12
        )

        store.pin(liveGame)
        store.updatePinnedGame(TestFixtures.makeGame(id: 203, leagueCode: "nba", scheduledStart: liveGame.scheduledStart, eventCount: 15))
        store.updatePinnedGame(TestFixtures.makeGame(id: 203, leagueCode: "nba", scheduledStart: liveGame.scheduledStart, eventCount: 11))
        XCTAssertEqual(store.snapshot.pinnedGamesById[203]?.newEventCount, 0)
        XCTAssertEqual(store.snapshot.pinnedGamesById[203]?.summaryPlayCountBaseline, 11)

        store.updatePinnedGame(TestFixtures.makeGame(id: 203, leagueCode: "nba", scheduledStart: liveGame.scheduledStart, eventCount: nil))
        XCTAssertEqual(store.snapshot.pinnedGamesById[203]?.newEventCount, 0)
        XCTAssertNil(store.snapshot.pinnedGamesById[203]?.summaryPlayCountBaseline)

        let pregame = TestFixtures.makeGame(
            id: 204,
            leagueCode: "nhl",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:30:00Z"),
            status: "scheduled",
            isLive: false,
            eventCount: 2
        )
        store.pin(pregame)
        store.updatePinnedGame(TestFixtures.makeGame(
            id: 204,
            leagueCode: "nhl",
            scheduledStart: pregame.scheduledStart,
            status: "scheduled",
            isLive: false,
            eventCount: 5
        ))
        XCTAssertEqual(store.snapshot.pinnedGamesById[204]?.newEventCount, 0)
    }

    func testDetailDiffClassifiesInsertedPrependedAppendedAndReset() {
        let previous = [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "e10"),
            TestFixtures.makeEvent(sequence: 12, sourceEventID: "e12")
        ]

        let appended = GameEventListDiffer.diff(previous: previous, current: previous + [
            TestFixtures.makeEvent(sequence: 13, sourceEventID: "e13")
        ])
        XCTAssertEqual(appended.kind, .appended)
        XCTAssertEqual(appended.insertedEvents.map(\.sequence), [13])

        let prepended = GameEventListDiffer.diff(previous: previous, current: [
            TestFixtures.makeEvent(sequence: 9, sourceEventID: "e9")
        ] + previous)
        XCTAssertEqual(prepended.kind, .prepended)
        XCTAssertEqual(prepended.insertedEvents.map(\.sequence), [9])

        let inserted = GameEventListDiffer.diff(previous: previous, current: [
            TestFixtures.makeEvent(sequence: 10, sourceEventID: "e10"),
            TestFixtures.makeEvent(sequence: 11, sourceEventID: "e11"),
            TestFixtures.makeEvent(sequence: 12, sourceEventID: "e12")
        ])
        XCTAssertEqual(inserted.kind, .inserted)
        XCTAssertEqual(inserted.insertedEvents.map(\.sequence), [11])

        let reset = GameEventListDiffer.diff(previous: previous, current: [
            TestFixtures.makeEvent(sequence: 99, sourceEventID: "replacement")
        ])
        XCTAssertEqual(reset.kind, .reset)
        XCTAssertTrue(reset.insertedEvents.isEmpty)
    }

    func testEventRefreshBaselineRepairsResetAndModeChangesLeaveBaselineAlone() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let initial = [TestFixtures.makeEvent(sequence: 1, sourceEventID: "e1")]
        store.recordEventRefresh(gameId: 205, events: initial, diff: .unchanged)
        let baseline = try XCTUnwrap(store.progress(for: 205)?.eventIdentityBaseline)

        store.setSelectedMode(gameId: 205, mode: .scoreboard)
        XCTAssertEqual(store.progress(for: 205)?.eventIdentityBaseline, baseline)

        let replacement = [TestFixtures.makeEvent(sequence: 10, sourceEventID: "new")]
        store.recordEventRefresh(
            gameId: 205,
            events: replacement,
            diff: GameEventListDiff(kind: .reset, insertedEvents: [], modifiedEvents: [], countDelta: 0)
        )

        let repaired = try XCTUnwrap(store.progress(for: 205)?.eventIdentityBaseline)
        XCTAssertEqual(repaired.sourceEventIDs, ["new"])
        XCTAssertEqual(store.progress(for: 205)?.newEventCount, 0)
    }

    func testOpeningGameClearsUnseenCountsWithoutLosingPin() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })
        let game = TestFixtures.makeGame(
            id: 206,
            leagueCode: "mlb",
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:10:00Z"),
            eventCount: 4
        )
        store.pin(game)
        store.updatePinnedGame(TestFixtures.makeGame(id: 206, leagueCode: "mlb", scheduledStart: game.scheduledStart, eventCount: 7))

        store.markViewed(gameId: 206)

        XCTAssertNotNil(store.snapshot.pinnedGamesById[206])
        XCTAssertEqual(store.snapshot.pinnedGamesById[206]?.newEventCount, 0)
        XCTAssertNil(store.progress(for: 206)?.eventIdentityBaseline)
    }

    func testReadProgressIsMonotonicWhenUserScrollsBackUp() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.recordReadEvent(gameId: 207, eventID: "event-5", eventIndex: 5, knownEventCount: 9)
        store.recordReadEvent(gameId: 207, eventID: "event-2", eventIndex: 2, knownEventCount: 9)

        let progress = try XCTUnwrap(store.progress(for: 207))
        XCTAssertEqual(progress.lastReadEventID, "event-5")
        XCTAssertEqual(progress.lastReadEventIndex, 5)
        XCTAssertEqual(progress.newEventCount, 3)
    }

    func testVisibleScrollFallbackDoesNotRegressDurableReadProgress() throws {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate("2026-05-22T12:00:00Z") })

        store.recordReadEvent(gameId: 208, eventID: "event-6", eventIndex: 6, knownEventCount: 10)
        store.setScrollFallback(
            gameId: 208,
            fallback: GameScrollFallbackRecord(eventSequence: 2, approximateOffset: 40)
        )

        let progress = try XCTUnwrap(store.progress(for: 208))
        XCTAssertEqual(progress.lastReadEventID, "event-6")
        XCTAssertEqual(progress.lastReadEventIndex, 6)
        XCTAssertEqual(progress.lastScrollFallback?.eventSequence, 2)
        XCTAssertEqual(progress.newEventCount, 3)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "com.dock108.scrolldownsports.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

}
