import XCTest
@testable import ScrollDownSports

@MainActor
final class ProductFlowIntegrationTests: XCTestCase {
    func testFinalCatchUpFlowKeepsScoreAtPayoffAndPersistsScoreboardReach() throws {
        let store = InMemoryGameStateStore()
        let game = finalGame(id: 3001)
        let events = catchUpEvents(count: 12)
        let detail = TestFixtures.makeDetail(game: game, events: events)
        let viewModel = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        viewModel.detail = detail
        let renderer = SportRendererRegistry.renderer(for: game)

        let header = renderer.gameHeaderPresentation(for: game)
        XCTAssertFalse(headerFields(header).containsScoreText(["7", "6", "7-6", "Yankees 7", "Mariners 6"]))
        XCTAssertEqual(DetailStreamMode.allCases.map(\.title), ["Important", "Standard", "All Plays"])
        XCTAssertEqual(DetailStreamMode.allCases.map { $0.count(in: events) }, [4, 8, 12])

        let scoringPlay = try XCTUnwrap(events.first { $0.scoreDelta != nil })
        XCTAssertEqual(renderer.eventPresentation(for: scoringPlay).scoreLabel, "3-2")

        let scoreboard = renderer.scoreboardPresentation(for: game)
        XCTAssertEqual(scoreboard.stateText, "Yankees 7, Mariners 6")
        XCTAssertEqual(scoreboard.rows.map(\.totalText), ["7", "6"])
        XCTAssertFalse(store.progress(for: game.id)?.reachedScoreboard == true)

        if hasScoreboardEnteredViewport(
            itemFrame: CGRect(x: 0, y: 650, width: 390, height: 240),
            viewportFrame: CGRect(x: 0, y: 480, width: 390, height: 300)
        ) {
            viewModel.setReachedScoreboard(true)
        }

        XCTAssertTrue(store.progress(for: game.id)?.reachedScoreboard == true)
    }

    func testResumeNewCountAndModeChangesStayAnchoredToExpectedEvents() throws {
        let store = InMemoryGameStateStore()
        let game = finalGame(id: 3002)
        let events = catchUpEvents(count: 9)
        let firstOpen = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        firstOpen.detail = TestFixtures.makeDetail(game: game, events: events)
        firstOpen.setSelectedStreamMode(.full)
        firstOpen.recordReadEvent(eventIndex: 2, eventID: events[2].id, knownEventCount: events.count)

        let reopened = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        reopened.detail = TestFixtures.makeDetail(game: game, events: events)
        let progress = try XCTUnwrap(reopened.localProgress)
        let target = try XCTUnwrap(GameDetailRestoreTargetResolver.targetEvent(
            progress: progress,
            events: events,
            mode: reopened.selectedStreamMode
        ))

        XCTAssertEqual(target.id, events[2].id)
        XCTAssertEqual(target.resumePositionText.cleanDisplayLabel, "3rd")
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.resumeDescription(target: target, newPlayCount: selectedModeUnreadCount(reopened)),
            "Resume from 3rd · 6 new"
        )

        reopened.recordReadEvent(eventIndex: 5, eventID: events[5].id, knownEventCount: events.count)
        XCTAssertEqual(reopened.localProgress?.newEventCount, 3)
        XCTAssertEqual(selectedModeUnreadCount(reopened), 3)

        reopened.recordLatestEventRead(events: events)
        XCTAssertEqual(reopened.localProgress?.newEventCount, 0)
        XCTAssertEqual(selectedModeUnreadCount(reopened), 0)

        reopened.setSelectedStreamMode(.key)
        XCTAssertEqual(reopened.localProgress?.lastReadEventID, events.last?.id)
        XCTAssertEqual(reopened.localProgress?.lastReadEventIndex, events.count - 1)
        XCTAssertEqual(GameDetailRestoreTargetResolver.targetEvent(
            progress: try XCTUnwrap(reopened.localProgress),
            events: events,
            mode: reopened.selectedStreamMode
        )?.id, events.last?.id)
    }

    func testTopEndAndReturnSpotStateDoesNotEraseDurableResumeFallback() throws {
        let store = InMemoryGameStateStore()
        let game = finalGame(id: 3003)
        let events = catchUpEvents(count: 10)
        let viewModel = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        viewModel.detail = TestFixtures.makeDetail(game: game, events: events)
        let priorSpot = events[4]

        viewModel.recordReadEvent(eventIndex: 4, eventID: priorSpot.id, knownEventCount: events.count)
        viewModel.recordScrollFallback(eventSequence: priorSpot.sequence, approximateOffset: 120)
        viewModel.setFollowingLiveEdge(false)

        XCTAssertEqual(viewModel.localProgress?.lastReadEventID, priorSpot.id)
        XCTAssertEqual(viewModel.localProgress?.lastScrollFallback?.eventSequence, priorSpot.sequence)

        viewModel.recordLatestEventRead(events: events)
        XCTAssertEqual(viewModel.localProgress?.lastReadEventID, events.last?.id)
        XCTAssertEqual(viewModel.localProgress?.lastScrollFallback?.eventSequence, priorSpot.sequence)

        viewModel.clearReadPosition()
        let fallbackTarget = try XCTUnwrap(GameDetailRestoreTargetResolver.targetEvent(
            progress: try XCTUnwrap(viewModel.localProgress),
            events: events,
            mode: .full
        ))
        XCTAssertEqual(fallbackTarget.id, events.first?.id)
    }

    func testHomeMorningAnchorFilteringAndEmptyStateUseOnlyRealVisibleGames() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let older = finalGame(id: 3011, start: "2026-05-21T23:00:00Z")
        let yesterday = finalGame(id: 3012, start: "2026-05-22T23:00:00Z")
        let live = TestFixtures.makeGame(
            id: 3013,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T16:00:00Z"),
            awayName: "Boston Red Sox",
            awayAbbreviation: "BOS",
            homeName: "Baltimore Orioles",
            homeAbbreviation: "BAL"
        )
        let upcoming = TestFixtures.makeGame(
            id: 3014,
            leagueCode: "nba",
            scheduledStart: TestFixtures.fixedDate("2026-05-23T20:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: "Boston Celtics",
            awayAbbreviation: "BOS",
            homeName: "Miami Heat",
            homeAbbreviation: "MIA",
            presentation: TestFixtures.previewPresentation()
        )
        let tbd = TestFixtures.makeGame(
            id: 3015,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T21:00:00Z"),
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: "TBD",
            awayAbbreviation: "TBD",
            homeName: "Seattle Mariners",
            homeAbbreviation: "SEA",
            presentation: TestFixtures.previewPresentation()
        )
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)

        XCTAssertEqual(viewModel.league, .all)
        XCTAssertEqual(viewModel.teamQuery, "")
        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["timeline"])
        XCTAssertEqual(viewModel.filteredVisibleGameCount, 0)
        XCTAssertNil(viewModel.initialHomeAnchorID)

        viewModel.games = [upcoming, tbd, live, older, yesterday]
        XCTAssertEqual(timelineSectionIDs(in: viewModel.filteredHomeSections), [
            "timeline-older",
            "timeline-yesterday",
            "timeline-live",
            "timeline-later-today"
        ])
        XCTAssertEqual(timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-older"), [3011])
        XCTAssertEqual(timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-yesterday"), [3012])
        XCTAssertEqual(timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-live"), [3013])
        XCTAssertEqual(timelineIDs(in: viewModel.filteredHomeSections, sectionID: "timeline-later-today"), [3014])
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-game-3013")
        XCTAssertFalse(allHomeIDs(in: viewModel.filteredHomeSections).contains(3015))

        viewModel.league = .nba
        XCTAssertEqual(timelineSectionIDs(in: viewModel.filteredHomeSections), ["timeline-later-today"])
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-game-3014")
        XCTAssertFalse(allHomeIDs(in: viewModel.filteredHomeSections).contains(3015))

        viewModel.clearFilters()
        viewModel.teamQuery = "Yankees"
        XCTAssertEqual(viewModel.initialHomeAnchorID, "timeline-game-3012")
        XCTAssertEqual(allHomeIDs(in: viewModel.filteredHomeSections), [3011, 3012])
    }

    func testRefreshFailuresKeepRenderableStateAndRetryCanRecoverWithoutLosingProgress() async throws {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        store.recordReadEvent(gameId: 3021, eventID: "event-2", eventIndex: 1, knownEventCount: 4)
        let home = HomeViewModel(
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .httpError(statusCode: 503),
                    .ok(TestFixtures.sdaGameListJSON(ids: [3021]))
                ],
                protocolClass: ProductFlowHomeURLProtocol.self
            ),
            now: { now },
            gameStateStore: store
        )
        home.games = [finalGame(id: 3021, start: "2026-05-22T23:00:00Z")]

        await home.refresh()
        XCTAssertEqual(home.games.map(\.id), [3021])
        XCTAssertEqual(home.filteredVisibleGameCount, 1)
        XCTAssertEqual(store.progress(for: 3021)?.lastReadEventID, "event-2")
        XCTAssertEqual(home.errorMessage, "The data service returned HTTP 503.")

        await home.refresh()
        XCTAssertEqual(home.games.map(\.id), [3021])
        XCTAssertNil(home.errorMessage)
        XCTAssertEqual(store.progress(for: 3021)?.lastReadEventID, "event-2")

        let detail = GameDetailViewModel(
            gameId: 3021,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 3021, playIDs: ["event-1", "event-2", "event-3"])),
                    .httpError(statusCode: 503),
                    .ok(TestFixtures.sdaGameDetailJSON(gameId: 3021, playIDs: ["event-1", "event-2", "event-3", "event-4"]))
                ],
                protocolClass: ProductFlowDetailURLProtocol.self
            ),
            gameStateStore: store
        )

        await detail.refresh()
        let loaded = try XCTUnwrap(detail.detail)
        await detail.refresh()
        XCTAssertEqual(detail.detail, loaded)
        XCTAssertEqual(detail.localProgress?.lastReadEventID, "event-2")
        XCTAssertEqual(detail.errorMessage, "The data service returned HTTP 503.")

        await detail.refresh()
        XCTAssertEqual(detail.detail?.events.map(\.id), ["event-1", "event-2", "event-3", "event-4"])
        XCTAssertNil(detail.errorMessage)
        XCTAssertEqual(detail.localProgress?.lastReadEventID, "event-2")
    }

    func testEmptyDetailAndNoPinnedStatesStayRealAndRecoverable() {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let viewModel = HomeViewModel(now: { now }, gameStateStore: store)
        let scorelessFinal = TestFixtures.makeGame(
            id: 3031,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T23:00:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: nil,
            homeScore: nil,
            eventCount: 0,
            hasTimeline: true,
            hasStats: false,
            hasScoreboard: false,
            scoreboard: nil
        )
        let detail = TestFixtures.makeDetail(game: scorelessFinal, events: [])
        let renderer = SportRendererRegistry.renderer(for: scorelessFinal)
        let scoreboard = renderer.scoreboardPresentation(for: scorelessFinal)

        XCTAssertEqual(viewModel.filteredHomeSections.map(\.id), ["timeline"])
        XCTAssertEqual(viewModel.filteredVisibleGameCount, 0)
        XCTAssertEqual(detail.events, [])
        XCTAssertEqual(detail.playerStats, [])
        XCTAssertEqual(detail.teamStats, [])
        XCTAssertEqual(DetailStreamMode.full.emptyStateMessage, "No plays are available yet.")
        XCTAssertEqual(scoreboard.rows.map(\.totalText), ["-", "-"])
        XCTAssertNil(scorelessFinal.scoreboard)
    }

    func testPinReadProgressBackgroundRefreshAndUnpinKeepStateConsistent() async throws {
        let now = TestFixtures.fixedDate("2026-05-23T13:00:00Z")
        let game = finalGame(id: 3041, start: "2026-05-22T23:00:00Z")
        let store = InMemoryGameStateStore(now: { now })
        let home = HomeViewModel(now: { now }, gameStateStore: store)
        home.games = [game]

        home.togglePin(game)
        XCTAssertTrue(store.isPinned(gameId: game.id))

        let detail = GameDetailViewModel(gameId: game.id, gameStateStore: store)
        detail.detail = TestFixtures.makeDetail(game: game, events: catchUpEvents(count: 4))
        detail.recordReadEvent(eventIndex: 1, eventID: "event-2", knownEventCount: 4)
        detail.setReachedScoreboard(true)
        XCTAssertEqual(store.snapshot.pinnedGamesById[game.id]?.lastReadEventID, "event-2")
        XCTAssertTrue(store.progress(for: game.id)?.reachedScoreboard == true)

        let service = BackgroundRefreshService(
            apiClient: ProductFlowBackgroundClient(
                games: [game],
                details: [game.id: TestFixtures.makeDetail(game: game, events: catchUpEvents(count: 6))]
            ),
            gameStateStore: store,
            now: { now }
        )
        try await service.refreshForBackground()

        XCTAssertTrue(store.isPinned(gameId: game.id))
        XCTAssertEqual(store.snapshot.pinnedGamesById[game.id]?.latestDetail?.events.count, 6)
        XCTAssertEqual(store.progress(for: game.id)?.lastReadEventID, "event-2")
        XCTAssertTrue(store.progress(for: game.id)?.reachedScoreboard == true)

        home.togglePin(game)
        XCTAssertFalse(store.isPinned(gameId: game.id))
        XCTAssertEqual(store.progress(for: game.id)?.lastReadEventID, "event-2")
        XCTAssertTrue(store.progress(for: game.id)?.reachedScoreboard == true)
    }

    private func selectedModeUnreadCount(_ viewModel: GameDetailViewModel) -> Int {
        guard let detail = viewModel.detail, let progress = viewModel.localProgress, !progress.reachedScoreboard else {
            return 0
        }
        let visibleEvents = viewModel.selectedStreamMode.visibleDedupedEvents(DetailStreamMode.dedupedEvents(from: detail.events))
        guard !visibleEvents.isEmpty else { return 0 }
        guard let readSequence = readSequence(progress: progress, events: detail.events) else {
            return min(progress.newEventCount, visibleEvents.count)
        }
        return visibleEvents.filter { $0.sequence > readSequence }.count
    }

    private func readSequence(progress: GameProgressRecord, events: [GameEvent]) -> Int? {
        let sortedEvents = DetailStreamMode.dedupedEvents(from: events)
        if let eventID = progress.lastReadEventID,
           let event = sortedEvents.first(where: { $0.normalizedSourceEventID == eventID || $0.id == eventID || $0.detailAnchorID == eventID }) {
            return event.sequence
        }
        if let eventIndex = progress.lastReadEventIndex, sortedEvents.indices.contains(eventIndex) {
            return sortedEvents[eventIndex].sequence
        }
        return progress.lastScrollFallback?.eventSequence
    }

    private func catchUpEvents(count: Int) -> [GameEvent] {
        (1...count).map { index in
            TestFixtures.makeEvent(
                sequence: index,
                sourceEventID: "event-\(index)",
                importance: index % 3 == 0 ? .primary : (index % 3 == 1 ? .secondary : .contextual),
                headline: index == 4 ? "Two-run double" : "Game update \(index)",
                periodOrdinal: index,
                periodLabel: ordinal(index),
                clockLabel: nil,
                scoreDelta: index == 4 ? ScoreDelta(participantID: "away", participantRole: .away, before: 1, after: 3, change: 2) : nil,
                homeScore: index >= 4 ? 2 : nil,
                awayScore: index >= 4 ? 3 : nil
            )
        }
    }

    private func finalGame(id: Int, start: String = "2026-05-22T23:00:00Z") -> Game {
        TestFixtures.makeGame(
            id: id,
            scheduledStart: TestFixtures.fixedDate(start),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 7,
            homeScore: 6,
            eventCount: 12,
            periodOrdinal: nil,
            periodLabel: "Final",
            clockLabel: nil,
            scoreboard: lineScore()
        )
    }

    private func lineScore() -> GameScoreboardData {
        GameScoreboardData(
            layout: "baseball",
            clockLabel: nil,
            periodLabel: "Final",
            statusLabel: "Final",
            scoreline: "Yankees 7, Mariners 6",
            competitors: [
                ScoreboardCompetitorData(
                    id: "away",
                    side: .away,
                    teamName: "New York Yankees",
                    teamAbbreviation: "NYY",
                    score: 7,
                    scoreText: "7",
                    isWinner: true,
                    recordText: nil
                ),
                ScoreboardCompetitorData(
                    id: "home",
                    side: .home,
                    teamName: "Seattle Mariners",
                    teamAbbreviation: "SEA",
                    score: 6,
                    scoreText: "6",
                    isWinner: false,
                    recordText: nil
                )
            ],
            segments: [ScoreboardSegmentData(label: "9", away: "1", home: "0")],
            totals: ScoreboardTotalsData(away: "7", home: "6")
        )
    }

    private func ordinal(_ value: Int) -> String {
        switch value {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "\(value)th"
        }
    }

    private func headerFields(_ presentation: GameHeaderPresentation) -> [String] {
        [
            presentation.leagueLabel,
            presentation.sportLabel,
            presentation.statusText,
            presentation.playCountText,
            presentation.headline,
            presentation.matchupLabel,
            presentation.secondaryText,
            presentation.accessibilityLabel
        ].compactMap(\.self)
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

    private func allHomeIDs(in sections: [HomeSection]) -> [Int] {
        sections.flatMap { section -> [Int] in
            switch section {
            case .pinned(let pinned):
                return pinned.games.map(\.id)
            case .timeline(let timeline):
                return timeline.dateSections.flatMap { $0.games.map(\.id) }
            }
        }
    }
}

private extension Array where Element == String {
    func containsScoreText(_ disallowed: [String]) -> Bool {
        contains { field in
            disallowed.contains { field.localizedCaseInsensitiveContains($0) }
        }
    }
}

private final class ProductFlowHomeURLProtocol: MockHTTPURLProtocol {}
private final class ProductFlowDetailURLProtocol: MockHTTPURLProtocol {}

@MainActor
private final class ProductFlowBackgroundClient: BackgroundRefreshAPIClient {
    let games: [Game]
    let details: [Int: GameDetail]

    init(games: [Game], details: [Int: GameDetail]) {
        self.games = games
        self.details = details
    }

    func fetchGames(window: GameWindow, limit: Int) async throws -> [Game] {
        games
    }

    func fetchGame(id: Int) async throws -> GameDetail {
        guard let detail = details[id] else {
            throw URLError(.badServerResponse)
        }
        return detail
    }
}
