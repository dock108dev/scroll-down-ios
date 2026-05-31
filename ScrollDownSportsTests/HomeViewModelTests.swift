import XCTest
@testable import ScrollDownSports

// Size note: this fixture-heavy view-model suite stays grouped by timeline/card-state behavior; see cleanup report.
@MainActor
final class HomeViewModelTests: XCTestCase {
    func testBuildsPinnedAndChronologicalTimelineWithUpcomingGames() throws {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let pinned = TestFixtures.makeGame(id: 1, scheduledStart: TestFixtures.fixedDate("2026-05-22T15:00:00Z"))
        let today = TestFixtures.makeGame(
            id: 2,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "scheduled",
            isLive: false,
            presentation: TestFixtures.previewPresentation()
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
            isLive: false,
            presentation: TestFixtures.previewPresentation()
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(pinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [future, earlier, today, pinned]

        let sections = viewModel.filteredHomeSections

        XCTAssertEqual(sections.map(\.id), ["pinned", "timeline"])
        XCTAssertEqual(pinnedIDs(in: sections), [1])
        XCTAssertEqual(timelineSectionIDs(in: sections), ["timeline-yesterday", "timeline-later-today", "timeline-upcoming"])
        XCTAssertEqual(timelineIDs(in: sections, sectionID: "timeline-yesterday"), [3])
        XCTAssertEqual(timelineIDs(in: sections, sectionID: "timeline-later-today"), [2])
        XCTAssertEqual(timelineIDs(in: sections, sectionID: "timeline-upcoming"), [4])
    }

    func testPinnedMetadataDoesNotRenderWhenFetchedWindowDoesNotContainPinnedGame() throws {
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

        XCTAssertEqual(sections.map(\.id), ["timeline"])
        XCTAssertEqual(pinnedIDs(in: sections), [])
        XCTAssertNil(viewModel.initialHomeAnchorID)
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
        viewModel.games = [mets, yankees]
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
            isLive: false,
            presentation: TestFixtures.previewPresentation()
        )
        let store = InMemoryGameStateStore(now: { now })
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [game]

        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["timeline"])
        XCTAssertEqual(timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-later-today"), [30])

        store.pin(game)
        store.setReachedScoreboard(gameId: game.id, reached: true)

        let sections = viewModel.filteredHomeSections
        XCTAssertEqual(sections.map(\.id), ["pinned", "timeline"])
        XCTAssertEqual(pinnedIDs(in: sections), [30])
        XCTAssertTrue(firstPinnedItem(in: sections)?.reachedScoreboard == true)
        XCTAssertTrue(allTimelineIDs(in: sections).isEmpty)
    }

    func testPinnedResultAccessorsExposeCurrentAndMissingPinnedRecords() {
        let now = TestFixtures.fixedDate("2026-05-22T16:00:00Z")
        let currentPinned = TestFixtures.makeGame(
            id: 301,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T18:00:00Z")
        )
        let missingPinned = TestFixtures.makeGame(
            id: 302,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T18:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let store = InMemoryGameStateStore(now: { now })
        store.pin(currentPinned)
        store.pin(missingPinned)
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        viewModel.games = [currentPinned]

        XCTAssertEqual(viewModel.pinnedGamesInCurrentResults.map(\.id), [currentPinned.id])
        XCTAssertEqual(viewModel.pinnedRecordsMissingFromCurrentResults.map(\.gameId), [missingPinned.id])
    }

    func testInitialAnchorUsesMostRecentFinalWhenYesterdayIsAbsent() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let olderFinal = TestFixtures.makeGame(
            id: 311,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T20:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let todayFinal = TestFixtures.makeGame(
            id: 312,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T12:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [olderFinal, todayFinal]

        XCTAssertEqual(timelineSectionIDs(in: viewModel.filteredHomeSections), [
            "timeline-older",
            "timeline-today",
            "timeline-later-today",
            "timeline-upcoming"
        ])
        XCTAssertEqual(viewModel.initialHomeAnchorID, viewModel.todaySectionID)
    }

    func testInitialAnchorPrefersYesterdayCatchupOverOlderAndUpcomingGames() throws {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let older = TestFixtures.makeGame(
            id: 31,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let yesterday = TestFixtures.makeGame(
            id: 32,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true
        )
        let live = TestFixtures.makeGame(
            id: 33,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T16:00:00Z"),
            status: "in_progress",
            isLive: true
        )
        let upcoming = TestFixtures.makeGame(
            id: 34,
            scheduledStart: TestFixtures.fixedDate("2026-05-24T18:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            presentation: TestFixtures.previewPresentation()
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [upcoming, live, yesterday, older]

        XCTAssertEqual(timelineSectionIDs(in: viewModel.filteredHomeSections), [
            "timeline-older",
            "timeline-yesterday",
            "timeline-live",
            "timeline-upcoming"
        ])
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-yesterday")
    }

    func testVisibleTimelineIncludesScoreOnlyLiveFinalAndOtherStatuses() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let liveScoreOnly = TestFixtures.makeGame(
            id: 321,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T14:00:00Z"),
            status: "in_progress",
            isLive: true,
            awayScore: 2,
            homeScore: 1,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: false
        )
        let finalScoreOnly = TestFixtures.makeGame(
            id: 322,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T02:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 3,
            homeScore: 4,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: false
        )
        let delayedScoreOnly = TestFixtures.makeGame(
            id: 323,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T03:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false,
            awayScore: 5,
            homeScore: 6,
            eventCount: nil,
            hasTimeline: false,
            hasScoreboard: false
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [liveScoreOnly, finalScoreOnly, delayedScoreOnly]

        XCTAssertEqual(
            allTimelineIDs(in: viewModel.filteredHomeSections),
            [finalScoreOnly.id, delayedScoreOnly.id, liveScoreOnly.id]
        )
    }

    func testAutoRefreshCanStartAndStopWithoutAffectingFilters() async {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.league = .mlb
        viewModel.teamQuery = "Mets"

        viewModel.startAutoRefresh()
        viewModel.startAutoRefresh()
        await Task.yield()
        viewModel.stopAutoRefresh()
        await Task.yield()

        XCTAssertEqual(viewModel.league, .mlb)
        XCTAssertEqual(viewModel.teamQuery, "Mets")
        XCTAssertFalse(viewModel.loading)
    }

    func testDefaultTimelineFiltersPlaceholderGames() throws {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let real = TestFixtures.makeGame(
            id: 35,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T18:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            presentation: TestFixtures.previewPresentation()
        )
        let placeholder = TestFixtures.makeGame(
            id: 36,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T19:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: "TBD",
            awayAbbreviation: "TBD",
            homeName: "Carolina Hurricanes",
            homeAbbreviation: "CAR"
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = [placeholder, real]

        XCTAssertEqual(allTimelineIDs(in: viewModel.filteredHomeSections), [35])
    }

    func testCardDisplayStatesCoverScoreGatesResumeAndPinning() throws {
        let scheduled = TestFixtures.makeGame(
            id: 37,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T18:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false,
            presentation: TestFixtures.previewPresentation()
        )
        let scheduledState = HomeGameCardState(item: makeItem(game: scheduled))
        XCTAssertEqual(scheduledState.phase, .scheduled)
        XCTAssertEqual(scheduledState.primaryActionLabel, "Preview")
        XCTAssertEqual(scheduledState.contextText, "Preview")
        XCTAssertFalse(scheduledState.showsScoreRows)

        let live = TestFixtures.makeGame(id: 38, status: "in_progress", isLive: true, awayScore: 4, homeScore: 5)
        let liveState = HomeGameCardState(item: makeItem(game: live, isPinned: true))
        XCTAssertEqual(liveState.phase, .live)
        XCTAssertEqual(liveState.primaryActionLabel, "Open stream")
        XCTAssertEqual(liveState.scoreCueText, "score at bottom")
        XCTAssertTrue(liveState.usesStrongLiveTreatment)
        XCTAssertTrue(liveState.isPinned)
        XCTAssertTrue(liveState.showsPinnedBadge)
        XCTAssertFalse(liveState.showsScoreRows)

        let final = TestFixtures.makeGame(id: 39, status: "final", isLive: false, isFinal: true, awayScore: 7, homeScore: 6)
        let unreadState = HomeGameCardState(item: makeItem(game: final))
        XCTAssertEqual(unreadState.phase, .final)
        XCTAssertEqual(unreadState.primaryActionLabel, "Catch up")
        XCTAssertEqual(unreadState.contextText, "Catch up · score at bottom")
        XCTAssertFalse(unreadState.showsScoreRows)

        let resumeProgress = TestFixtures.makeProgress(gameId: final.id, lastReadEventIndex: 3, lastKnownEventCount: 12)
        let resumeState = HomeGameCardState(item: makeItem(game: final, progress: resumeProgress))
        XCTAssertEqual(resumeState.primaryActionLabel, "Resume")
        XCTAssertEqual(resumeState.progressText, "Resume from T4 · 1 out")

        let readProgress = TestFixtures.makeProgress(gameId: final.id, lastReadEventIndex: 11, lastKnownEventCount: 12, reachedScoreboard: true)
        let readState = HomeGameCardState(item: makeItem(game: final, progress: readProgress))
        XCTAssertTrue(readState.showsScoreRows)
        XCTAssertNil(readState.scoreCueText)
        XCTAssertEqual(readState.scoreRows.map(\.scoreText), ["7", "6"])
        XCTAssertEqual(Set(readState.scoreRows.map(\.name)).count, readState.scoreRows.count)
        XCTAssertEqual(Set(readState.scoreRows.map(\.id)).count, final.participants.count)

        let displayCopy = [
            unreadState.statusText,
            unreadState.statusBadgeText,
            unreadState.primaryActionLabel,
            unreadState.contextText,
            unreadState.metadataText,
            unreadState.progressText,
            unreadState.newPlayText
        ].compactMap(\.self).joined(separator: " | ")
        XCTAssertFalse(displayCopy.contains("Score at bottom"))
        XCTAssertFalse(displayCopy.contains("Game detail available"))
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
        XCTAssertEqual(unreadState.scoreCueText, "score at bottom")
        XCTAssertFalse(unreadState.showsScoreRows)

        let partialProgress = TestFixtures.makeProgress(gameId: finalWithTimeline.id, lastReadEventIndex: 4, lastKnownEventCount: 12)
        let resumeState = HomeGameCardState(item: makeItem(game: finalWithTimeline, progress: partialProgress))
        XCTAssertEqual(resumeState.primaryActionLabel, "Resume")
        XCTAssertEqual(resumeState.progressText, "Resume from T4")

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
            presentation: TestFixtures.previewPresentation(headline: nil, primaryActionLabel: "Catch up")
        )

        let state = HomeGameCardState(item: makeItem(game: game))

        XCTAssertEqual(state.primaryActionLabel, "Open box score")
    }

    func testCardFallbacksCoverOtherPhaseBackendLabelsAndScoreboardScores() throws {
        let delayed = TestFixtures.makeGame(
            id: 46,
            scheduledStart: TestFixtures.fixedDate("2026-05-21T23:00:00Z"),
            status: "delayed",
            isLive: false,
            isFinal: false,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            periodLabel: nil,
            clockLabel: nil,
            hasTimeline: false
        )
        let delayedState = HomeGameCardState(item: makeItem(game: delayed))
        XCTAssertEqual(delayedState.phase, .other)
        XCTAssertEqual(delayedState.statusText, "Game update")
        XCTAssertEqual(delayedState.primaryActionLabel, "Game details")
        XCTAssertEqual(delayedState.contextText, "Details")

        let futureUnknown = TestFixtures.makeGame(
            id: 47,
            scheduledStart: TestFixtures.fixedDate("2030-05-23T23:00:00Z"),
            status: "weather_delay",
            isLive: false,
            isFinal: false,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false
        )
        XCTAssertEqual(HomeGameCardState(item: makeItem(game: futureUnknown)).phase, .scheduled)

        let liveWithoutTimeline = TestFixtures.makeGame(
            id: 48,
            status: "in_progress",
            isLive: true,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false,
            presentation: TestFixtures.previewPresentation(
                headline: nil,
                statusLabel: "Weather delay",
                primaryActionLabel: "Open stream"
            )
        )
        let liveState = HomeGameCardState(item: makeItem(game: liveWithoutTimeline))
        XCTAssertEqual(liveState.statusText, "Weather delay")
        XCTAssertEqual(liveState.primaryActionLabel, "Live details")

        let scoreboardOnly = TestFixtures.makeGame(
            id: 49,
            status: "final",
            isLive: false,
            isFinal: true,
            awayAbbreviation: nil,
            homeAbbreviation: nil,
            awayScore: nil,
            homeScore: nil,
            eventCount: nil,
            hasTimeline: false,
            scoreboard: GameScoreboardData(
                layout: nil,
                clockLabel: nil,
                periodLabel: nil,
                statusLabel: "Official final",
                scoreline: nil,
                competitors: [
                    ScoreboardCompetitorData(
                        id: "away-49",
                        side: .away,
                        teamName: "New York Yankees",
                        teamAbbreviation: nil,
                        score: nil,
                        scoreText: "11",
                        isWinner: true,
                        recordText: nil
                    ),
                    ScoreboardCompetitorData(
                        id: "home-49",
                        side: .home,
                        teamName: "Seattle Mariners",
                        teamAbbreviation: nil,
                        score: nil,
                        scoreText: "8",
                        isWinner: false,
                        recordText: nil
                    )
                ],
                segments: [],
                totals: nil
            )
        )
        let reachedScoreboard = TestFixtures.makeProgress(
            gameId: scoreboardOnly.id,
            lastKnownEventCount: 0,
            reachedScoreboard: true
        )
        let scoreboardState = HomeGameCardState(item: makeItem(game: scoreboardOnly, progress: reachedScoreboard))
        XCTAssertEqual(scoreboardState.statusText, "Official final")
        XCTAssertEqual(scoreboardState.primaryActionLabel, "Open recap")
        XCTAssertEqual(scoreboardState.scoreRows.map(\.scoreText), ["11", "8"])
        XCTAssertEqual(scoreboardState.scoreRows.map(\.abbreviation), ["Yank", "Mari"])
        XCTAssertEqual(scoreboardState.scoreRows.map(\.isWinner), [true, false])
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

    private func timelineSectionIDs(in sections: [HomeSection]) -> [String] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }) else {
            return []
        }
        return section.dateSections.map(\.id)
    }

    private func timelineIDs(in sections: [HomeSection], sectionID: String) -> [Int] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }),
              let dateSection = section.dateSections.first(where: { $0.id == sectionID }) else {
            return []
        }
        return dateSection.games.map(\.id)
    }

    private func allTimelineIDs(in sections: [HomeSection]) -> [Int] {
        guard case .timeline(let section) = sections.first(where: { $0.id == "timeline" }) else {
            return []
        }
        return section.dateSections.flatMap { $0.games.map(\.id) }
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
