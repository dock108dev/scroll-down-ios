import XCTest
@testable import ScrollDownSports

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testBuildsPinnedTodayAndEarlierSectionsWithoutFuturePeers() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let pinned = TestFixtures.makeGame(id: 1, scheduledStart: TestFixtures.fixedDate("2026-05-22T15:00:00Z"))
        let today = TestFixtures.makeGame(
            id: 2,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "scheduled",
            isLive: false
        )
        let earlier = TestFixtures.makeGame(
            id: 3,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let future = TestFixtures.makeGame(
            id: 4,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T23:00:00Z"),
            status: "scheduled",
            isLive: false
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [future, earlier, today, pinned]

        let sections = viewModel.filteredHomeSections

        XCTAssertEqual(sections.map(\.id), ["pinned", "today", "earlier"])
        XCTAssertEqual(pinnedIDs(in: sections), [1])
        XCTAssertEqual(todayIDs(in: sections), [2])
        XCTAssertEqual(earlierIDsByDate(in: sections), [[3]])
    }

    func testPinnedMetadataRendersWhenFetchedWindowDoesNotContainPinnedGame() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let oldPinned = TestFixtures.makeGame(
            id: 10,
            scheduledStart: TestFixtures.fixedDate("2026-05-12T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(oldPinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)

        let sections = viewModel.filteredHomeSections

        XCTAssertEqual(sections.map(\.id), ["pinned", "today"])
        XCTAssertEqual(pinnedIDs(in: sections), [10])
    }

    func testHydratesMatchingPersistedHomeSnapshotOnInit() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let game = TestFixtures.makeGame(id: 11, scheduledStart: TestFixtures.fixedDate("2026-05-22T18:00:00Z"))
        let store = InMemoryGameStateStore(now: { now })
        store.saveHomeSnapshot(games: [game], windowKey: GameWindow.home(now: now).stableKey, fetchedAt: now)

        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)

        XCTAssertEqual(viewModel.games.map(\.id), [11])
        XCTAssertEqual(viewModel.lastUpdated, now)
    }

    func testFiltersApplyBeforePinnedTodayAndEarlierConstruction() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let mets = TestFixtures.makeGame(
            id: 20,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T17:00:00Z"),
            awayName: "New York Mets",
            awayAbbreviation: "NYM"
        )
        let yankees = TestFixtures.makeGame(
            id: 21,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T18:00:00Z"),
            awayName: "New York Yankees",
            awayAbbreviation: "NYY"
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(mets)
        store.pin(yankees)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.teamQuery = "Mets"

        let sections = viewModel.filteredHomeSections

        XCTAssertEqual(pinnedIDs(in: sections), [20])
        XCTAssertEqual(viewModel.filteredVisibleGameCount, 1)
    }

    func testStoreChangesMoveRowsIntoPinnedAndRefreshProgressState() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let game = TestFixtures.makeGame(
            id: 30,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T19:00:00Z"),
            status: "scheduled",
            isLive: false
        )
        let store = InMemoryGameStateStore(now: { now })
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [game]

        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["today"])
        XCTAssertEqual(todayIDs(in: viewModel.filteredHomeSections), [30])

        store.pin(game)
        store.setReachedScoreboard(gameId: game.id, reached: true)

        let sections = viewModel.filteredHomeSections
        XCTAssertEqual(sections.map(\.id), ["pinned", "today"])
        XCTAssertEqual(pinnedIDs(in: sections), [30])
        XCTAssertTrue(firstPinnedItem(in: sections)?.reachedScoreboard == true)
        XCTAssertTrue(todayIDs(in: sections).isEmpty)
    }

    func testScheduledCardDoesNotAdvertiseStreamResumeOrNewPlaysWithoutPriorProgress() throws {
        let game = TestFixtures.makeGame(
            id: 40,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "scheduled",
            isLive: false,
            eventCount: nil,
            hasTimeline: false
        )

        let state = HomeGameCardState(item: makeItem(game: game))

        XCTAssertEqual(state.phase, .scheduled)
        XCTAssertEqual(state.primaryActionLabel, "Preview")
        XCTAssertNil(state.newPlayText)
        XCTAssertNil(state.progressText)
    }

    func testLiveCardUsesStreamActionOnlyWhenTimelineIsAvailable() throws {
        let liveWithoutTimeline = TestFixtures.makeGame(
            id: 41,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T19:00:00Z"),
            eventCount: nil,
            hasTimeline: false
        )
        let liveWithTimeline = TestFixtures.makeGame(
            id: 42,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T19:30:00Z"),
            eventCount: 8,
            hasTimeline: true
        )

        XCTAssertEqual(HomeGameCardState(item: makeItem(game: liveWithoutTimeline)).primaryActionLabel, "Live details")
        let streamState = HomeGameCardState(item: makeItem(game: liveWithTimeline))
        XCTAssertEqual(streamState.primaryActionLabel, "Open stream")
        XCTAssertTrue(streamState.usesStrongLiveTreatment)
    }

    func testFinalCardsSeparateCatchUpResumeRecapAndBoxScoreStates() throws {
        let finalWithTimeline = TestFixtures.makeGame(
            id: 43,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            eventCount: 12,
            clockLabel: nil,
            hasTimeline: true
        )
        let unreadState = HomeGameCardState(item: makeItem(game: finalWithTimeline))
        XCTAssertEqual(unreadState.primaryActionLabel, "Catch up")
        XCTAssertEqual(unreadState.scoreCueText, "Score at bottom")
        XCTAssertFalse(unreadState.showsScoreRows)

        let partialProgress = TestFixtures.makeProgress(gameId: finalWithTimeline.id, lastReadEventIndex: 4, lastKnownEventCount: 12)
        let resumeState = HomeGameCardState(item: makeItem(game: finalWithTimeline, progress: partialProgress))
        XCTAssertEqual(resumeState.primaryActionLabel, "Resume")
        XCTAssertEqual(resumeState.progressText, "Resume T4")

        var recapProgress = partialProgress
        recapProgress.reachedScoreboard = true
        let recapState = HomeGameCardState(item: makeItem(game: finalWithTimeline, progress: recapProgress))
        XCTAssertEqual(recapState.primaryActionLabel, "Open recap")
        XCTAssertTrue(recapState.showsScoreRows)

        let boxScoreOnly = TestFixtures.makeGame(
            id: 44,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            eventCount: nil,
            hasTimeline: false
        )
        XCTAssertEqual(HomeGameCardState(item: makeItem(game: boxScoreOnly)).primaryActionLabel, "Open box score")
    }

    func testBackendActionLabelsAreGatedByLocalEligibility() throws {
        let game = TestFixtures.makeGame(
            id: 45,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            eventCount: nil,
            hasTimeline: false,
            presentation: GamePresentationData(
                headline: nil,
                shortHeadline: nil,
                subheadline: nil,
                matchupLabel: nil,
                primaryLabel: nil,
                secondaryLabel: nil,
                tertiaryLabel: nil,
                accessibilityLabel: nil,
                displayState: nil,
                visualPriority: nil,
                sortBucket: nil,
                accentRole: nil,
                statusTone: nil,
                eventCounts: nil,
                statusLabel: nil,
                primaryActionLabel: "Catch up",
                secondaryContextLabel: nil,
                scoreboardPlacement: nil
            )
        )

        let state = HomeGameCardState(item: makeItem(game: game))

        XCTAssertEqual(state.primaryActionLabel, "Open box score")
    }

    private func pinnedIDs(in sections: [HomeSection]) -> [Int] {
        guard case .pinned(let section) = sections.first(where: { $0.id == "pinned" }) else {
            return []
        }
        return section.games.map(\.id)
    }

    private func firstPinnedItem(in sections: [HomeSection]) -> HomeGameItem? {
        guard case .pinned(let section) = sections.first(where: { $0.id == "pinned" }) else {
            return nil
        }
        return section.games.first
    }

    private func todayIDs(in sections: [HomeSection]) -> [Int] {
        guard case .today(let section) = sections.first(where: { $0.id == "today" }) else {
            return []
        }
        return section.games.map(\.id)
    }

    private func earlierIDsByDate(in sections: [HomeSection]) -> [[Int]] {
        guard case .earlier(let section) = sections.first(where: { $0.id == "earlier" }) else {
            return []
        }
        return section.dateSections.map { $0.games.map(\.id) }
    }

    private func makeItem(game: Game, isPinned: Bool = false, progress: GameProgressRecord? = nil) -> HomeGameItem {
        HomeGameItem(
            game: game,
            isPinned: isPinned,
            pinnedRecord: nil,
            progress: progress
        )
    }

}
