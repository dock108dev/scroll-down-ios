import XCTest
@testable import ScrollDownSports

@MainActor
final class GameDetailViewModelTests: XCTestCase {
    func testStreamModeSelectionPersistsToLocalProgress() {
        let store = InMemoryGameStateStore()
        let viewModel = GameDetailViewModel(gameId: 501, gameStateStore: store)

        XCTAssertEqual(viewModel.selectedStreamMode, .key)

        viewModel.setSelectedStreamMode(.flow)
        XCTAssertEqual(store.progress(for: 501)?.selectedMode, .flow)
        XCTAssertEqual(viewModel.selectedStreamMode, .flow)

        viewModel.setSelectedStreamMode(.full)
        XCTAssertEqual(store.progress(for: 501)?.selectedMode, .stream)
        XCTAssertEqual(viewModel.selectedStreamMode, .full)
    }

    func testStreamModeSelectionPreservesCanonicalReadIndex() {
        let store = InMemoryGameStateStore()
        let viewModel = GameDetailViewModel(gameId: 501, gameStateStore: store)

        viewModel.recordReadEvent(eventIndex: 3, eventID: "event-4", knownEventCount: 6)
        viewModel.setSelectedStreamMode(.flow)
        viewModel.setSelectedStreamMode(.full)

        XCTAssertEqual(store.progress(for: 501)?.lastReadEventID, "event-4")
        XCTAssertEqual(store.progress(for: 501)?.lastReadEventIndex, 3)
        XCTAssertEqual(store.progress(for: 501)?.newEventCount, 2)
    }

    func testFollowLiveStateUsesSeparatePreferenceFromGamePinning() {
        let store = InMemoryGameStateStore()
        let game = makeGame(id: 502)
        let viewModel = GameDetailViewModel(gameId: game.id, gameStateStore: store)

        viewModel.toggleGamePin(game)
        viewModel.setFollowingLiveEdge(true)

        XCTAssertTrue(store.isPinned(gameId: game.id))
        XCTAssertTrue(viewModel.isGamePinned)
        XCTAssertTrue(viewModel.isFollowingLiveEdge)
        XCTAssertEqual(store.progress(for: game.id)?.followLivePreference, .followingLiveEdge)
        XCTAssertEqual(store.snapshot.pinnedGamesById[game.id]?.followLivePreference, .followingLiveEdge)

        viewModel.setFollowingLiveEdge(false)

        XCTAssertTrue(store.isPinned(gameId: game.id))
        XCTAssertFalse(viewModel.isFollowingLiveEdge)
        XCTAssertEqual(store.progress(for: game.id)?.followLivePreference, .readingAwayFromLiveEdge)
    }

    func testOpeningNewEventCountSurvivesViewedStateMutationForResumeCopy() {
        let store = InMemoryGameStateStore()
        store.recordReadEvent(gameId: 503, eventID: "event-1", eventIndex: 0, knownEventCount: 4)

        let viewModel = GameDetailViewModel(gameId: 503, gameStateStore: store)

        XCTAssertEqual(viewModel.openingNewEventCount, 3)
        XCTAssertEqual(store.progress(for: 503)?.newEventCount, 3)
    }

    func testVisibleReadProgressMovesForwardOnlyAndShrinksUnreadCount() {
        let store = InMemoryGameStateStore()
        let viewModel = GameDetailViewModel(gameId: 503, gameStateStore: store)

        viewModel.recordReadEvent(eventIndex: 0, eventID: "event-1", knownEventCount: 8)
        XCTAssertEqual(store.progress(for: 503)?.newEventCount, 7)

        viewModel.recordReadEvent(eventIndex: 4, eventID: "event-5", knownEventCount: 8)
        XCTAssertEqual(store.progress(for: 503)?.lastReadEventID, "event-5")
        XCTAssertEqual(store.progress(for: 503)?.lastReadEventIndex, 4)
        XCTAssertEqual(store.progress(for: 503)?.newEventCount, 3)

        viewModel.recordReadEvent(eventIndex: 2, eventID: "event-3", knownEventCount: 8)
        XCTAssertEqual(store.progress(for: 503)?.lastReadEventID, "event-5")
        XCTAssertEqual(store.progress(for: 503)?.lastReadEventIndex, 4)
        XCTAssertEqual(store.progress(for: 503)?.newEventCount, 3)
    }

    func testOpeningPinnedGameHydratesPersistedDetailAndClearsUnseenCount() throws {
        let store = InMemoryGameStateStore()
        let game = makeGame(id: 504)
        store.pin(game)
        let baseline = SDADomainMapper.detail(
            from: try JSONDecoder.sda.decode(
                SDAGameDetailResponseDTO.self,
                from: TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2"])
            )
        )
        let updated = SDADomainMapper.detail(
            from: try JSONDecoder.sda.decode(
                SDAGameDetailResponseDTO.self,
                from: TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2", "event-3"])
            )
        )
        store.updatePinnedGameDetail(baseline, fetchedAt: Date())
        store.updatePinnedGameDetail(updated, fetchedAt: Date())

        let viewModel = GameDetailViewModel(gameId: 504, gameStateStore: store)

        XCTAssertEqual(viewModel.detail?.events.map(\.id), ["event-1", "event-2", "event-3"])
        XCTAssertEqual(viewModel.openingNewEventCount, 1)
        XCTAssertEqual(store.snapshot.pinnedGamesById[504]?.newEventCount, 0)
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 1)
        XCTAssertTrue(store.isPinned(gameId: 504))
    }

    func testDetailRefreshTracksAppendedEventsAndClearsThemAtLatest() async throws {
        let store = InMemoryGameStateStore()
        let viewModel = GameDetailViewModel(
            gameId: 504,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2"])),
                    .ok(TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2", "event-3"]))
                ],
                protocolClass: MockGameURLProtocol.self
            ),
            gameStateStore: store
        )

        await viewModel.refresh()
        XCTAssertEqual(viewModel.eventDiff.kind, .unchanged)
        XCTAssertEqual(store.progress(for: 504)?.newEventCount, 0)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.eventDiff.kind, .appended)
        XCTAssertEqual(viewModel.eventDiff.insertedEvents.map(\.id), ["event-3"])
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 1)

        let detail = try XCTUnwrap(viewModel.detail)
        viewModel.recordLatestEventRead(events: detail.events)

        XCTAssertEqual(store.progress(for: 504)?.newEventCount, 0)
        XCTAssertEqual(store.progress(for: 504)?.lastReadEventID, "event-3")
        XCTAssertEqual(store.progress(for: 504)?.lastReadEventIndex, 2)
    }

    func testDetailRefreshFailurePreservesCurrentPayloadAndProgress() async throws {
        let store = InMemoryGameStateStore()
        let viewModel = GameDetailViewModel(
            gameId: 505,
            apiClient: TestFixtures.makeAPIClient(
                responses: [
                    .ok(TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2"])),
                    .ok(TestFixtures.sdaGameDetailJSON(playIDs: ["event-1", "event-2", "event-3"])),
                    .httpError(statusCode: 503)
                ],
                protocolClass: MockGameURLProtocol.self
            ),
            gameStateStore: store
        )

        await viewModel.refresh()
        await viewModel.refresh()
        let currentDetail = try XCTUnwrap(viewModel.detail)
        let currentToken = viewModel.updateToken
        let currentProgress = store.progress(for: 505)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.detail, currentDetail)
        XCTAssertEqual(viewModel.updateToken, currentToken)
        XCTAssertEqual(store.progress(for: 505), currentProgress)
        XCTAssertEqual(viewModel.localProgress?.newEventCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "The data service returned HTTP 503.")
        XCTAssertFalse(viewModel.loading)
    }

    func testStreamModesCountExpectedEventBands() {
        let key = makeEvent(sequence: 1, importance: .primary)
        let flow = makeEvent(sequence: 2, importance: .secondary)
        let full = makeEvent(sequence: 3, importance: .contextual)
        let events = [key, flow, full]

        XCTAssertEqual(DetailStreamMode.key.count(in: events), 1)
        XCTAssertEqual(DetailStreamMode.flow.count(in: events), 2)
        XCTAssertEqual(DetailStreamMode.full.count(in: events), 3)
    }

    func testStreamModesDoNotFallbackAcrossBackendEligibility() {
        let flow = makeEvent(sequence: 1, importance: .secondary)
        let routine = makeEvent(sequence: 2, importance: .contextual)

        XCTAssertEqual(DetailStreamMode.key.visibleEvents(in: [flow, routine]).map(\.id), [])
        XCTAssertEqual(DetailStreamMode.flow.visibleEvents(in: [flow, routine]).map(\.id), [flow.id])
        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: [flow, routine]).map(\.id), [flow.id, routine.id])

        XCTAssertEqual(DetailStreamMode.key.count(in: [routine]), 0)
        XCTAssertEqual(DetailStreamMode.flow.count(in: [routine]), 0)
        XCTAssertEqual(DetailStreamMode.full.count(in: [routine]), 1)
    }

    func testStreamModeCountsUseDedupedVisibleEvents() {
        let original = makeEvent(sequence: 1, sourceEventID: "same-play", importance: .primary, headline: "Run scores")
        let duplicate = makeEvent(sequence: 2, sourceEventID: "same-play", importance: .primary, headline: "Run scores")
        let flow = makeEvent(sequence: 3, importance: .secondary, headline: "Runner advances")

        XCTAssertEqual(DetailStreamMode.key.count(in: [original, duplicate, flow]), 1)
        XCTAssertEqual(DetailStreamMode.flow.count(in: [original, duplicate, flow]), 2)
        XCTAssertEqual(DetailStreamMode.full.count(in: [original, duplicate, flow]), 2)
    }

    func testStreamModeDedupePreservesDistinctSourceEventsWithMatchingCopy() {
        let first = makeEvent(sequence: 1, sourceEventID: "event-1", importance: .primary, headline: "Run scores")
        let second = makeEvent(sequence: 2, sourceEventID: "event-2", importance: .primary, headline: "Run scores")

        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: [first, second]).map(\.id), ["event-1", "event-2"])
    }

    func testStreamModeDedupeIncludesPresentationTimeLabel() {
        let first = makeEvent(
            sequence: 1,
            sourceEventID: nil,
            importance: .primary,
            headline: "Run scores",
            presentationTimeLabel: "Q1 10:00"
        )
        let second = makeEvent(
            sequence: 2,
            sourceEventID: nil,
            importance: .primary,
            headline: "Run scores",
            presentationTimeLabel: "Q1 09:58"
        )

        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: [second, first]).map(\.id), ["event-1", "event-2"])
    }

    func testStreamOrderingUsesSequenceBeforeRenderedClockText() {
        let laterClock = makeEvent(sequence: 2, sourceEventID: "later", importance: .primary, clockLabel: "00:05")
        let earlierClock = makeEvent(sequence: 1, sourceEventID: "earlier", importance: .primary, clockLabel: "12:00")

        XCTAssertEqual(DetailStreamMode.full.visibleEvents(in: [laterClock, earlierClock]).map(\.id), ["earlier", "later"])
    }

    func testRendererGroupsEventsByPeriodAndRemovesRepeatedRowLabel() {
        let renderer = SportRendererRegistry.renderer(for: "nba")
        let first = makeEvent(
            sequence: 1,
            sourceEventID: "event-1",
            importance: .primary,
            periodOrdinal: 1,
            periodLabel: nil,
            clockLabel: "Q1 10:00"
        )
        let second = makeEvent(
            sequence: 2,
            sourceEventID: "event-2",
            importance: .primary,
            periodOrdinal: 2,
            periodLabel: nil,
            clockLabel: "Q2 08:14"
        )
        let unknown = makeEvent(
            sequence: 3,
            sourceEventID: "event-3",
            importance: .contextual,
            periodOrdinal: nil,
            periodLabel: nil,
            clockLabel: "Final"
        )

        let groups = renderer.periodGroups(for: [second, unknown, first])

        XCTAssertEqual(groups.map(\.label), ["Q1", "Q2", "Game"])
        XCTAssertEqual(renderer.rowClockText(for: first, periodGroupLabel: groups[0].label), "10:00")
        XCTAssertEqual(renderer.rowClockText(for: unknown, periodGroupLabel: groups[2].label), "Final")
    }

    func testRestoreTargetUsesSavedEventIDBeforeFallbacks() {
        let events = [
            makeEvent(sequence: 1, sourceEventID: "event-1", importance: .primary),
            makeEvent(sequence: 2, sourceEventID: "event-2", importance: .secondary),
            makeEvent(sequence: 3, sourceEventID: "event-3", importance: .contextual)
        ]
        var progress = GameProgressRecord.empty(gameId: 601, now: Date())
        progress.lastReadEventID = "event-2"
        progress.lastReadEventIndex = 0

        let target = GameDetailRestoreTargetResolver.targetEvent(progress: progress, events: events, mode: .key)

        XCTAssertEqual(target?.id, "event-2")
    }

    func testRestoreTargetFallsBackToIndexThenScrollSequence() {
        let events = [
            makeEvent(sequence: 10, sourceEventID: "event-10", importance: .primary),
            makeEvent(sequence: 12, sourceEventID: "event-12", importance: .secondary),
            makeEvent(sequence: 14, sourceEventID: "event-14", importance: .contextual)
        ]
        var indexProgress = GameProgressRecord.empty(gameId: 602, now: Date())
        indexProgress.lastReadEventIndex = 1

        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: indexProgress, events: events, mode: .key)?.id,
            "event-12"
        )

        var sequenceProgress = GameProgressRecord.empty(gameId: 603, now: Date())
        sequenceProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 13, approximateOffset: 40)

        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: sequenceProgress, events: events, mode: .key)?.id,
            "event-14"
        )
    }

    func testRestoreSwitchesToFullWhenSavedEventIsHiddenByCurrentMode() {
        let events = [
            makeEvent(sequence: 1, sourceEventID: "event-1", importance: .primary),
            makeEvent(sequence: 2, sourceEventID: "event-2", importance: .contextual)
        ]
        let target = events[1]

        XCTAssertEqual(
            GameDetailRestoreTargetResolver.streamModeToReveal(target: target, currentMode: .key, events: events),
            .full
        )
    }

    private func makeGame(id: Int) -> Game {
        Game(
            id: id,
            sport: .mlb,
            leagueCode: "mlb",
            scheduledStart: Date(timeIntervalSince1970: 1_779_480_000),
            localDateLabel: "2026-05-22",
            status: GameStatus(rawValue: "in_progress", isLiveOverride: true, isFinalOverride: nil),
            participants: [
                GameParticipant(id: "away", role: .away, name: "New York Yankees", abbreviation: "NYY"),
                GameParticipant(id: "home", role: .home, name: "Seattle Mariners", abbreviation: "SEA")
            ],
            scoreState: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "away", participantRole: .away, score: 1),
                    ParticipantScore(participantID: "home", participantRole: .home, score: 2)
                ]
            ),
            presentation: nil,
            scoreboard: nil,
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: nil,
                periodLabel: "T4",
                clockLabel: nil,
                eventCount: 12,
                lastReadEventID: nil,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: nil,
                restoredAt: nil,
                persistence: nil
            ),
            availableFeatures: GameAvailableFeatures(hasTimeline: true, hasStats: true, hasScoreboard: true)
        )
    }

    private func makeEvent(
        sequence: Int,
        sourceEventID: String? = nil,
        importance: GameEventImportance,
        headline: String? = nil,
        periodOrdinal: Int? = 1,
        periodLabel: String? = "Q1",
        clockLabel: String? = "10:00",
        presentationTimeLabel: String? = nil
    ) -> GameEvent {
        GameEvent(
            id: sourceEventID ?? "event-\(sequence)",
            sourceEventID: sourceEventID,
            sequence: sequence,
            periodOrdinal: periodOrdinal,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: "play",
            importance: importance,
            eligibleModes: eligibleModes(for: importance),
            usesBackendModeEligibility: true,
            presentation: presentationTimeLabel.map { TestFixtures.eventPresentation(timeLabel: $0) },
            importanceMetadata: nil,
            headline: headline ?? "Game update \(sequence)",
            detail: nil,
            rawText: nil,
            rawFeedSource: nil,
            rawFeedUpdatedAt: nil,
            scoreBefore: nil,
            scoreAfter: ScoreState(participantScores: []),
            scoreDelta: nil,
            sportMetadata: [:]
        )
    }

    private func eligibleModes(for importance: GameEventImportance) -> Set<GameMode> {
        switch importance {
        case .primary:
            return [.timeline, .flow, .stream]
        case .secondary:
            return [.flow, .stream]
        case .contextual:
            return [.stream]
        }
    }

}

private final class MockGameURLProtocol: MockHTTPURLProtocol {}
