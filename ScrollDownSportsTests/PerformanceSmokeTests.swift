import XCTest
@testable import ScrollDownSports

@MainActor
final class PerformanceSmokeTests: XCTestCase {
    func testLongStreamModelStateHandlesLargeDetailsAndAppends() throws {
        var timing = SmokeTiming()
        let eighty = makeDetail(gameID: 1701, eventCount: 80, isLive: false)
        let oneFifty = makeDetail(gameID: 1702, eventCount: 150, isLive: true)

        timing.measure("80-event detail state") {
            XCTAssertEqual(eighty.events.count, 80)
            XCTAssertEqual(DetailStreamMode.dedupedEvents(from: eighty.events).count, 80)
            XCTAssertFalse(eighty.playerStats.isEmpty)
            XCTAssertFalse(eighty.teamStats.isEmpty)
        }

        timing.measure("150-event mode toggles and stats state") {
            XCTAssertEqual(oneFifty.events.count, 150)
            let viewModel = GameDetailViewModel(gameId: oneFifty.game.id, gameStateStore: InMemoryGameStateStore())
            viewModel.detail = oneFifty

            for mode in [DetailStreamMode.key, .flow, .full, .key, .full] {
                viewModel.setSelectedStreamMode(mode)
                XCTAssertEqual(viewModel.selectedStreamMode, mode)
                XCTAssertFalse(mode.visibleEvents(in: oneFifty.events).isEmpty)
            }

            viewModel.setExpandedSection("player-stats", isExpanded: true)
            viewModel.setExpandedSection("team-stats", isExpanded: true)
            XCTAssertEqual(viewModel.localProgress?.expandedSectionIDs, ["player-stats", "team-stats"])
            viewModel.setExpandedSection("player-stats", isExpanded: false)
            XCTAssertEqual(viewModel.localProgress?.expandedSectionIDs, ["team-stats"])
        }

        for appendCount in [5, 15, 30] {
            try timing.measure("append \(appendCount) events") {
                let store = InMemoryGameStateStore()
                let gameID = 1800 + appendCount
                let base = makeEvents(count: 150)
                let appended = makeEvents(count: 150 + appendCount)
                store.recordEventRefresh(gameId: gameID, events: base, diff: .unchanged)
                store.recordReadEvent(gameId: gameID, eventID: "evt-perf-075", eventIndex: 74, knownEventCount: base.count)
                store.setFollowLivePreference(gameId: gameID, preference: .readingAwayFromLiveEdge)

                let diff = GameEventListDiffer.diff(
                    previous: base,
                    current: appended,
                    baseline: store.progress(for: gameID)?.eventIdentityBaseline
                )
                store.recordEventRefresh(gameId: gameID, events: appended, diff: diff)

                let progress = try XCTUnwrap(store.progress(for: gameID))
                XCTAssertEqual(diff.kind, .appended)
                XCTAssertEqual(diff.insertedEvents.count, appendCount)
                XCTAssertEqual(progress.lastReadEventID, "evt-perf-075")
                XCTAssertEqual(progress.lastKnownEventCount, 150 + appendCount)
                XCTAssertEqual(progress.newEventCount, 75 + appendCount)
            }
        }

        assertSmokeTimings(timing, maxDuration: 0.45)
    }

    func testRestoreJumpAndStatsAnchorsStayStableForLongStreams() throws {
        var timing = SmokeTiming()
        let events = makeEvents(count: 150)

        timing.measure("restore by event ID") {
            var progress = GameProgressRecord.empty(gameId: 1901, now: TestFixtures.fixedDate())
            progress.lastReadEventID = "evt-perf-074"
            progress.lastReadEventIndex = 73
            let target = GameDetailRestoreTargetResolver.targetEvent(progress: progress, events: events, mode: .full)
            XCTAssertEqual(target?.normalizedSourceEventID, "evt-perf-074")
        }

        timing.measure("restore by sequence fallback") {
            let missingEventStream = events.filter { $0.normalizedSourceEventID != "evt-perf-061" }
            var progress = GameProgressRecord.empty(gameId: 1902, now: TestFixtures.fixedDate())
            progress.lastReadEventID = "evt-perf-061"
            progress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 610, approximateOffset: 320)
            let target = GameDetailRestoreTargetResolver.targetEvent(progress: progress, events: missingEventStream, mode: .full)
            XCTAssertEqual(target?.normalizedSourceEventID, "evt-perf-062")
        }

        try timing.measure("latest and scoreboard progress") {
            let store = InMemoryGameStateStore()
            let viewModel = GameDetailViewModel(gameId: 1903, gameStateStore: store)
            viewModel.detail = makeDetail(gameID: 1903, eventCount: 150, isLive: false)
            viewModel.recordReadEvent(eventIndex: 74, eventID: "evt-perf-075", knownEventCount: 150)
            viewModel.recordScrollFallback(eventSequence: 750, approximateOffset: 180)
            viewModel.recordLatestEventRead(events: events)
            viewModel.setReachedScoreboard(true)
            viewModel.setExpandedSection("player-stats", isExpanded: true)
            viewModel.setExpandedSection("player-stats", isExpanded: false)

            let progress = try XCTUnwrap(viewModel.localProgress)
            XCTAssertEqual(progress.lastReadEventID, "evt-perf-150")
            XCTAssertEqual(progress.lastReadEventIndex, 149)
            XCTAssertEqual(progress.lastScrollFallback?.eventSequence, 750)
            XCTAssertTrue(progress.reachedScoreboard)
            XCTAssertFalse(progress.expandedSectionIDs.contains("player-stats"))
        }

        assertSmokeTimings(timing, maxDuration: 0.35)
    }

    func testRepeatedHomeFiltersOverLargeSlateStayResponsiveAndCorrect() throws {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let viewModel = HomeViewModel(now: { now }, gameStateStore: InMemoryGameStateStore(now: { now }))
        viewModel.games = makeHomeSlate(now: now, count: 200)
        var timing = SmokeTiming()

        timing.measure("large home filters") {
            for _ in 0..<20 {
                viewModel.league = .mlb
                viewModel.teamQuery = "Harbor"
                XCTAssertEqual(viewModel.filteredVisibleGameCount, 50)

                viewModel.league = .nba
                viewModel.teamQuery = "Canyon"
                XCTAssertEqual(viewModel.filteredVisibleGameCount, 50)

                viewModel.league = .all
                viewModel.teamQuery = "Club 1"
                XCTAssertEqual(viewModel.filteredVisibleGameCount, 111)

                viewModel.clearFilters()
                XCTAssertEqual(viewModel.filteredVisibleGameCount, 200)
            }
        }

        assertSmokeTimings(timing, maxDuration: 2.0)
    }

    private func assertSmokeTimings(
        _ timing: SmokeTiming,
        maxDuration: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTContext.runActivity(named: "performance smoke timings") { activity in
            activity.add(XCTAttachment(string: timing.report))
        }
        XCTAssertLessThan(timing.maxDuration, maxDuration, file: file, line: line)
    }

    private func makeDetail(gameID: Int, eventCount: Int, isLive: Bool) -> GameDetail {
        let game = TestFixtures.makeGame(
            id: gameID,
            status: isLive ? "in_progress" : "final",
            isLive: isLive,
            isFinal: !isLive,
            eventCount: eventCount
        )
        return GameDetail(
            game: game,
            teamStats: makeTeamStats(),
            playerStats: makePlayerStats(),
            events: makeEvents(count: eventCount),
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
    }

    private func makeEvents(count: Int) -> [GameEvent] {
        (1...count).map { index in
            let importance: GameEventImportance = if index.isMultiple(of: 10) {
                .primary
            } else if index.isMultiple(of: 3) {
                .secondary
            } else {
                .contextual
            }
            return TestFixtures.makeEvent(
                sequence: index * 10,
                sourceEventID: String(format: "evt-perf-%03d", index),
                importance: importance,
                headline: "Long stream play \(index)",
                detail: "Smoke detail for play \(index)",
                periodOrdinal: ((index - 1) / 30) + 1,
                periodLabel: "P\(((index - 1) / 30) + 1)",
                clockLabel: "\(index):00",
                rawFeedSource: index.isMultiple(of: 4) ? "provider" : nil,
                homeScore: index / 12,
                awayScore: index / 15
            )
        }
    }

    private func makeTeamStats() -> [TeamStat] {
        [
            TeamStat(team: "Seattle Mariners", isHome: true, stats: ["hits": .number(9)], normalizedStats: [
                NormalizedStat(key: "hits", displayLabel: "H", group: nil, value: .number(9))
            ]),
            TeamStat(team: "New York Yankees", isHome: false, stats: ["hits": .number(7)], normalizedStats: [
                NormalizedStat(key: "hits", displayLabel: "H", group: nil, value: .number(7))
            ])
        ]
    }

    private func makePlayerStats() -> [PlayerStat] {
        [
            PlayerStat(team: "Seattle Mariners", playerName: "Riley Stone", minutes: nil, points: nil, rebounds: nil, assists: nil, yards: nil, touchdowns: nil, rawStats: ["hits": .number(3)]),
            PlayerStat(team: "New York Yankees", playerName: "Jordan Vale", minutes: nil, points: nil, rebounds: nil, assists: nil, yards: nil, touchdowns: nil, rawStats: ["rbi": .number(2)])
        ]
    }

    private func makeHomeSlate(now: Date, count: Int) -> [Game] {
        let leagues = ["MLB", "NBA", "NHL", "NFL"]
        return (0..<count).map { index in
            let league = leagues[index % leagues.count]
            let pairedName = index.isMultiple(of: 2) ? "Harbor Club \(index)" : "Canyon Club \(index)"
            return TestFixtures.makeGame(
                id: 3000 + index,
                leagueCode: league,
                scheduledStart: now.addingTimeInterval(TimeInterval(index * 60)),
                status: index.isMultiple(of: 5) ? "in_progress" : "final",
                isLive: index.isMultiple(of: 5),
                isFinal: !index.isMultiple(of: 5),
                awayName: pairedName,
                awayAbbreviation: "A\(index)",
                homeName: "Metro Club \(index)",
                homeAbbreviation: "H\(index)",
                eventCount: 150
            )
        }
    }
}

private struct SmokeTiming {
    private(set) var samples: [(String, TimeInterval)] = []

    var maxDuration: TimeInterval {
        samples.map(\.1).max() ?? 0
    }

    var report: String {
        samples
            .map { "\($0.0): \(String(format: "%.4f", $0.1))s" }
            .joined(separator: "\n")
    }

    mutating func measure(_ name: String, operation: () throws -> Void) rethrows {
        let start = Date()
        try operation()
        samples.append((name, Date().timeIntervalSince(start)))
    }
}
