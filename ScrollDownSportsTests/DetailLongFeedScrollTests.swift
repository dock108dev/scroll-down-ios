import XCTest
@testable import ScrollDownSports

@MainActor
final class DetailLongFeedScrollTests: XCTestCase {
    func testGeneratedSportFeedsCoverProductionSizedEventCounts() {
        let configs = [
            LongFeedConfig(leagueCode: "mlb", count: 120, primaryStride: 9, secondaryStride: 3, groupSize: 45),
            LongFeedConfig(leagueCode: "nhl", count: 280, primaryStride: 8, secondaryStride: 4, groupSize: 160),
            LongFeedConfig(leagueCode: "nba", count: 500, primaryStride: 7, secondaryStride: 3, groupSize: 175),
            LongFeedConfig(leagueCode: "nfl", count: 260, primaryStride: 6, secondaryStride: 2, groupSize: 130, addsLongDescriptions: true)
        ]

        for config in configs {
            let game = makeGame(config: config)
            let events = makeEvents(config: config)
            let dedupedEvents = DetailStreamMode.dedupedEvents(from: events)
            let renderer = SportRendererRegistry.renderer(for: game)
            let groups = renderer.periodGroups(for: DetailStreamMode.full.visibleDedupedEvents(dedupedEvents))

            XCTAssertEqual(dedupedEvents.count, config.count, config.leagueCode)
            XCTAssertEqual(DetailStreamMode.full.visibleDedupedEvents(dedupedEvents).count, config.count, config.leagueCode)
            XCTAssertGreaterThan(DetailStreamMode.key.visibleDedupedEvents(dedupedEvents).count, 0, config.leagueCode)
            XCTAssertGreaterThan(
                DetailStreamMode.flow.visibleDedupedEvents(dedupedEvents).count,
                DetailStreamMode.key.visibleDedupedEvents(dedupedEvents).count,
                config.leagueCode
            )
            XCTAssertEqual(groups.flatMap(\.events).count, config.count, config.leagueCode)
            XCTAssertFalse(groups.contains { $0.events.isEmpty }, config.leagueCode)
        }
    }

    func testLongModeSwitchPreservesExactAnchorAndUsesNearestSequence() throws {
        let basketball = makeEvents(config: LongFeedConfig(leagueCode: "nba", count: 500, primaryStride: 7, secondaryStride: 3, groupSize: 175))
        let exactPrimary = basketball[349]

        XCTAssertEqual(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: exactPrimary.detailAnchorID,
                from: .full,
                to: .key,
                events: basketball
            ),
            exactPrimary.detailAnchorID
        )

        let baseball = makeEvents(config: LongFeedConfig(leagueCode: "mlb", count: 750, primaryStride: 9, secondaryStride: 3, groupSize: 45))
        let contextual = try XCTUnwrap(baseball.first { $0.sequence == 3_760 })
        let nearestKey = try XCTUnwrap(baseball.first { $0.sequence == 3_780 })

        XCTAssertEqual(
            GameDetailScrollLogic.restoredStreamAnchorID(
                currentAnchorID: contextual.detailAnchorID,
                from: .full,
                to: .key,
                events: baseball
            ),
            nearestKey.detailAnchorID
        )
    }

    func testLongResumeFallbacksAvoidEmptyTargets() throws {
        let events = makeEvents(config: LongFeedConfig(leagueCode: "mlb", count: 750, primaryStride: 9, secondaryStride: 3, groupSize: 45))

        var indexProgress = GameProgressRecord.empty(gameId: 4_201, now: TestFixtures.fixedDate())
        indexProgress.lastReadEventID = "deleted-event"
        indexProgress.lastReadEventIndex = 612
        XCTAssertEqual(
            GameDetailRestoreTargetResolver.targetEvent(progress: indexProgress, events: events, mode: .full)?.normalizedSourceEventID,
            "mlb-event-0613"
        )

        var sequenceProgress = GameProgressRecord.empty(gameId: 4_202, now: TestFixtures.fixedDate())
        sequenceProgress.lastReadEventID = "deleted-event"
        sequenceProgress.lastReadEventIndex = 5_000
        sequenceProgress.lastScrollFallback = GameScrollFallbackRecord(eventSequence: 1_005, approximateOffset: 240)

        let target = try XCTUnwrap(GameDetailRestoreTargetResolver.targetEvent(progress: sequenceProgress, events: events, mode: .full))
        XCTAssertEqual(target.sequence, 1_010)
        XCTAssertFalse(target.detailAnchorID.isEmpty)
    }

    func testLongRefreshReindexesSavedCursorForAppendedAndPrependedFeeds() throws {
        let config = LongFeedConfig(leagueCode: "nba", count: 500, primaryStride: 7, secondaryStride: 3, groupSize: 175)
        let initial = makeEvents(config: config)
        let appended = initial + makeEvents(config: config.with(count: 60, sequenceOffset: 5_000, sourceIDPrefix: "nba-extra"))
        let prepended = makeEvents(config: config.with(count: 20, sequenceOffset: -200, sourceIDPrefix: "nba-pre")) + initial

        let appendedStore = InMemoryGameStateStore()
        appendedStore.recordEventRefresh(gameId: 4_301, events: initial, diff: .unchanged)
        appendedStore.recordReadEvent(gameId: 4_301, eventID: "nba-event-0350", eventIndex: 349, knownEventCount: initial.count)
        appendedStore.setFollowLivePreference(gameId: 4_301, preference: .readingAwayFromLiveEdge)
        let appendedDiff = GameEventListDiffer.diff(
            previous: initial,
            current: appended,
            baseline: appendedStore.progress(for: 4_301)?.eventIdentityBaseline
        )
        appendedStore.recordEventRefresh(gameId: 4_301, events: appended, diff: appendedDiff)
        let appendedProgress = try XCTUnwrap(appendedStore.progress(for: 4_301))
        XCTAssertEqual(appendedProgress.lastReadEventID, "nba-event-0350")
        XCTAssertEqual(appendedProgress.lastReadEventIndex, 349)
        XCTAssertEqual(appendedProgress.newEventCount, appended.count - 350)

        let prependedStore = InMemoryGameStateStore()
        prependedStore.recordEventRefresh(gameId: 4_302, events: initial, diff: .unchanged)
        prependedStore.recordReadEvent(gameId: 4_302, eventID: "nba-event-0350", eventIndex: 349, knownEventCount: initial.count)
        prependedStore.setFollowLivePreference(gameId: 4_302, preference: .readingAwayFromLiveEdge)
        let prependedDiff = GameEventListDiffer.diff(
            previous: initial,
            current: prepended,
            baseline: prependedStore.progress(for: 4_302)?.eventIdentityBaseline
        )
        prependedStore.recordEventRefresh(gameId: 4_302, events: prepended, diff: prependedDiff)
        let prependedProgress = try XCTUnwrap(prependedStore.progress(for: 4_302))
        XCTAssertEqual(prependedProgress.lastReadEventID, "nba-event-0350")
        XCTAssertEqual(prependedProgress.lastReadEventIndex, 369)
        XCTAssertEqual(prependedProgress.newEventCount, prepended.count - 370)
    }

    func testLongNormalizedCardRefreshTreatsRegeneratedTextAsModification() throws {
        let config = LongFeedConfig(leagueCode: "nba", count: 500, primaryStride: 7, secondaryStride: 3, groupSize: 175)
        let initial = makeEvents(config: config, usesNormalizedPresentation: true)
        var refreshed = initial
        refreshed[349] = TestFixtures.makeEvent(
            sequence: initial[349].sequence,
            sourceEventID: initial[349].normalizedSourceEventID,
            importance: initial[349].importance,
            headline: "NBA regenerated normalized card",
            detail: "Updated card copy from normalized feed contract.",
            periodOrdinal: initial[349].periodOrdinal,
            periodLabel: initial[349].periodLabel,
            clockLabel: initial[349].clockLabel,
            homeScore: initial[349].scoreAfter.home,
            awayScore: initial[349].scoreAfter.away
        )

        let store = InMemoryGameStateStore()
        store.recordEventRefresh(gameId: 4_303, events: initial, diff: .unchanged)
        store.recordReadEvent(gameId: 4_303, eventID: "nba-event-0350", eventIndex: 349, knownEventCount: initial.count)
        store.setFollowLivePreference(gameId: 4_303, preference: .readingAwayFromLiveEdge)

        let diff = GameEventListDiffer.diff(
            previous: initial,
            current: refreshed,
            baseline: store.progress(for: 4_303)?.eventIdentityBaseline
        )
        store.recordEventRefresh(gameId: 4_303, events: refreshed, diff: diff)

        let progress = try XCTUnwrap(store.progress(for: 4_303))
        XCTAssertEqual(diff.kind, .modified)
        XCTAssertTrue(diff.insertedEvents.isEmpty)
        XCTAssertEqual(diff.modifiedEvents.map(\.normalizedSourceEventID), ["nba-event-0350"])
        XCTAssertEqual(progress.lastReadEventID, "nba-event-0350")
        XCTAssertEqual(progress.lastReadEventIndex, 349)
        XCTAssertEqual(progress.newEventCount, refreshed.count - 350)
    }

    func testLongFeedVisibilityIgnoresBottomAffordanceAndKeepsReadableAnchor() {
        let frames = [
            frame(anchorID: "a", readIndex: 10, sequence: 100, y: 40),
            frame(anchorID: "b", readIndex: 11, sequence: 110, y: 120),
            frame(anchorID: "c", readIndex: 12, sequence: 120, y: 670)
        ]

        XCTAssertEqual(
            GameDetailScrollLogic.visibleCandidate(
                from: frames,
                viewportHeight: 800,
                readingTopY: 80,
                obscuredBottomHeight: 120
            )?.anchorID,
            "a"
        )
        XCTAssertEqual(
            GameDetailScrollLogic.readCandidate(
                from: frames,
                viewportHeight: 800,
                readingTopY: 80,
                obscuredBottomHeight: 120
            )?.anchorID,
            "b"
        )
    }

    func testPlayFeedRenderingKeepsIndexedLookupsUnderDetailLazyStack() throws {
        let sectionSource = try repoFile("ScrollDownSports/Views/CatchUpSections.swift")
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(detailSource.contains("LazyVStack(alignment: .leading, spacing: layout.stackSpacing"))
        XCTAssertTrue(detailSource.contains("PlayByPlaySection("))
        XCTAssertTrue(sectionSource.contains("readIndexByAnchorID[event.detailAnchorID]"))
        XCTAssertTrue(sectionSource.contains("visibleEventIndexByAnchorID[event.detailAnchorID]"))
        XCTAssertFalse(sectionSource.contains("dedupedEvents.firstIndex(of: event)"))
        XCTAssertFalse(sectionSource.contains("visibleEvents.firstIndex(of: event)"))
    }

    func testDetailControlsUseSemanticScrollAnchors() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(source.contains(".onChange(of: stickyTopRequest)"))
        XCTAssertTrue(source.contains("scrollToTop(proxy)"))
        XCTAssertTrue(source.contains("proxy.scrollTo(GameDetailScrollAnchor.top, anchor: .top)"))
        XCTAssertTrue(source.contains(".onChange(of: stickyEndRequest)"))
        XCTAssertTrue(source.contains("scrollToEndOrLatest(proxy)"))
        XCTAssertTrue(source.contains("proxy.scrollTo(GameDetailScrollAnchor.scoreboard"))
        XCTAssertTrue(source.contains("scrollToLatest(proxy, preservesReturnAnchor: false)"))
        XCTAssertTrue(source.contains("proxy.scrollTo(GameDetailScrollAnchor.event(target.detailAnchorID), anchor: .bottom)"))
        XCTAssertTrue(source.contains("proxy.scrollTo(GameDetailScrollAnchor.latest, anchor: .bottom)"))
    }

    func testProgrammaticRestoreDoesNotSaveTransientScrollFramesBeforeTargetIsVisible() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(source.contains("@State private var programmaticScrollTargetAnchorID: String?"))
        XCTAssertTrue(source.contains("reachedProgrammaticTarget"))
        XCTAssertTrue(source.contains("programmaticScrollTargetAnchorID != nil"))
        XCTAssertTrue(source.contains("return"))
        XCTAssertTrue(source.contains("!programmaticScrollInFlight || reachedProgrammaticTarget != nil"))
        XCTAssertTrue(source.contains("performProgrammaticScroll(targetAnchorID: resumeState.target.detailAnchorID"))
        XCTAssertTrue(source.contains("performProgrammaticScroll(targetAnchorID: anchorID"))
    }

    func testExpansionAndScoreRevealMutationsPreserveReaderAnchorWithoutInitialJump() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(source.contains("onRawFeedExpansionChange: { key, isExpanded in"))
        XCTAssertTrue(source.contains("viewModel.setRawFeedExpanded(key: key, isExpanded: isExpanded)"))
        XCTAssertTrue(source.contains("isExpanded: sectionExpansionBinding(playerStatsSectionID, proxy: proxy)"))
        XCTAssertTrue(source.contains("isExpanded: sectionExpansionBinding(teamStatsSectionID, proxy: proxy)"))
        XCTAssertTrue(source.contains("scoreRevealed: scoreRevealBinding(proxy: proxy)"))
        XCTAssertTrue(source.contains("private func preserveReaderAnchor(proxy: ScrollViewProxy, mutate: () -> Void)"))
        XCTAssertTrue(source.contains("private func restoreAfterContentChange(_ proxy: ScrollViewProxy)"))
        XCTAssertTrue(source.contains("GameDetailScrollLogic.restoredContentChangeAnchorID"))
        XCTAssertFalse(source.contains(".onAppear {\n                    preserveReaderAnchor"))
    }

    private func makeGame(config: LongFeedConfig) -> Game {
        TestFixtures.makeGame(
            id: abs(config.leagueCode.hashValue % 10_000) + config.count,
            leagueCode: config.leagueCode,
            status: "final",
            isLive: false,
            isFinal: true,
            eventCount: config.count
        )
    }

    private func makeEvents(config: LongFeedConfig, usesNormalizedPresentation: Bool = false) -> [GameEvent] {
        (1...config.count).map { index in
            let importance: GameEventImportance = if index.isMultiple(of: config.primaryStride) {
                .primary
            } else if index.isMultiple(of: config.secondaryStride) {
                .secondary
            } else {
                .contextual
            }
            let periodOrdinal = max(1, ((index - 1) / config.groupSize) + 1)
            let detail = config.addsLongDescriptions && index.isMultiple(of: 5)
                ? "Long drive context with personnel, field position, clock pressure, and down-distance detail for event \(index)."
                : "Generated feed detail \(index)."

            return TestFixtures.makeEvent(
                sequence: config.sequenceOffset + index * 10,
                sourceEventID: String(format: "%@-%04d", config.eventIDPrefix, index),
                importance: importance,
                headline: "\(config.leagueCode.uppercased()) feed event \(index)",
                detail: detail,
                periodOrdinal: periodOrdinal,
                periodLabel: periodLabel(leagueCode: config.leagueCode, ordinal: periodOrdinal),
                clockLabel: "\(index % 20):00",
                presentation: usesNormalizedPresentation
                    ? TestFixtures.eventPresentation(timeLabel: "\(periodLabel(leagueCode: config.leagueCode, ordinal: periodOrdinal)) \(index % 20):00")
                    : nil,
                homeScore: index / 12,
                awayScore: index / 15
            )
        }
    }

    private func periodLabel(leagueCode: String, ordinal: Int) -> String {
        switch leagueCode {
        case "mlb":
            return ordinal.isMultiple(of: 2) ? "B\(max(1, ordinal / 2))" : "T\((ordinal + 1) / 2)"
        case "nhl":
            return "P\(ordinal)"
        default:
            return "Q\(ordinal)"
        }
    }

    private func frame(anchorID: String, readIndex: Int, sequence: Int, y: CGFloat) -> DetailEventVisibilityFrame {
        DetailEventVisibilityFrame(
            anchorID: anchorID,
            readIndex: readIndex,
            sequence: sequence,
            eventID: anchorID,
            label: "P1",
            frame: CGRect(x: 0, y: y, width: 320, height: 100)
        )
    }

    private func repoFile(_ path: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent(path)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}

private struct LongFeedConfig {
    let leagueCode: String
    let count: Int
    let primaryStride: Int
    let secondaryStride: Int
    let groupSize: Int
    var addsLongDescriptions = false
    var sequenceOffset = 0
    var sourceIDPrefix: String?

    var eventIDPrefix: String {
        sourceIDPrefix ?? "\(leagueCode)-event"
    }

    func with(count: Int, sequenceOffset: Int, sourceIDPrefix: String) -> LongFeedConfig {
        LongFeedConfig(
            leagueCode: leagueCode,
            count: count,
            primaryStride: primaryStride,
            secondaryStride: secondaryStride,
            groupSize: groupSize,
            addsLongDescriptions: addsLongDescriptions,
            sequenceOffset: sequenceOffset,
            sourceIDPrefix: sourceIDPrefix
        )
    }
}
