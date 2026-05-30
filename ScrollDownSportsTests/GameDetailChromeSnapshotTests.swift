import SwiftUI
@testable import ScrollDownSports

@MainActor
final class GameDetailChromeSnapshotTests: SnapshotTestCase {
    func testScorelessScheduledHeader() {
        let game = ComponentSnapshotFixtures.game(
            id: 4_101,
            status: "scheduled",
            isLive: false,
            isFinal: false,
            hasTimeline: false,
            hasScoreboard: false,
            presentation: ComponentSnapshotFixtures.previewPresentation()
        )

        assertSwiftUISnapshot(
            of: GameHeaderView(
                game: game,
                renderer: SportRendererRegistry.renderer(for: game),
                isPinned: false,
                newPlayCount: 0
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "header-scoreless-preview",
            width: .standard,
            height: 170
        )
    }

    func testHeaderLiveNewAndFinalCatchUpStates() {
        let live = ComponentSnapshotFixtures.game(
            id: 4_102,
            scheduledStart: TestFixtures.fixedDate("2026-05-23T15:10:00Z"),
            status: "in_progress",
            isLive: true,
            awayScore: 2,
            homeScore: 3,
            eventCount: 26,
            periodLabel: "Q3",
            clockLabel: "04:22"
        )
        let final = ComponentSnapshotFixtures.game(
            id: 4_103,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T20:10:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 2,
            homeScore: 3,
            eventCount: 32
        )
        var finalReadProgress = ComponentSnapshotFixtures.progressRecord(
            gameId: final.id,
            lastReadIndex: 31,
            knownEventCount: 32
        )
        finalReadProgress.reachedScoreboard = true
        let resume = ComponentSnapshotFixtures.game(
            id: 4_110,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T19:10:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 5,
            homeScore: 4,
            eventCount: 29,
            periodOrdinal: 6,
            periodLabel: "T6",
            clockLabel: "1 out"
        )
        let resumeProgress = ComponentSnapshotFixtures.progressRecord(
            gameId: resume.id,
            lastReadIndex: 12,
            knownEventCount: 29,
            newCount: 6
        )

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                GameHeaderView(game: live, renderer: SportRendererRegistry.renderer(for: live), isPinned: true, newPlayCount: 7)
                GameHeaderView(game: final, renderer: SportRendererRegistry.renderer(for: final), isPinned: false, newPlayCount: 0)
                GameHeaderView(game: final, renderer: SportRendererRegistry.renderer(for: final), isPinned: false, newPlayCount: 0, progress: finalReadProgress)
                GameHeaderView(game: resume, renderer: SportRendererRegistry.renderer(for: resume), isPinned: false, newPlayCount: 6, progress: resumeProgress)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "header-live-new-final-catch-up",
            width: .standard,
            height: 620
        )
    }

    func testPlaceholderErrorAndFallbackChromeStates() {
        let fallbackGame = ComponentSnapshotFixtures.game(
            id: 4_109,
            status: "scheduled",
            isLive: false,
            isFinal: false,
            awayName: "Lakeside United",
            awayAbbreviation: nil,
            homeName: "Harbor City",
            homeAbbreviation: nil,
            hasTimeline: false,
            hasScoreboard: false,
            presentation: ComponentSnapshotFixtures.previewPresentation()
        )

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                GameHeaderView(
                    game: fallbackGame,
                    renderer: SportRendererRegistry.renderer(for: fallbackGame),
                    isPinned: false,
                    newPlayCount: 0
                )
                GameHeaderPlaceholder(
                    summary: fallbackGame,
                    renderer: SportRendererRegistry.renderer(for: fallbackGame)
                )
                DetailRefreshErrorBanner(message: "Could not reach the data service.") {}
                DetailLoadErrorState(message: "Could not reach the data service.") {}
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "placeholder-error-fallback-chrome",
            width: .standard,
            height: 620
        )
    }

    func testResumeBannerCopyAndCompactLayout() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                ResumeBanner(description: "Resume from Q3 · 08:42", onResume: {}, onJumpLatest: {}, onStartOver: {})
                ResumeBanner(
                    description: "Resume from Period 4 · 01:12 · Bay Harbor scoring drive",
                    onResume: {},
                    onJumpLatest: {},
                    onStartOver: {}
                )
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "resume-copy-compact",
            width: .compact,
            height: 170
        )
    }

    func testStickyNavigationTopEndAndReturnModes() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                DetailStickyNavigationBar(title: "North Arc at Bay Harbor", progressLabel: "18/31 read", endLabel: "Latest", returnLabel: nil, onTop: {}, onEnd: {}, onReturn: {})
                DetailStickyNavigationBar(title: "North Arc at Bay Harbor", progressLabel: "3 new", endLabel: "End", returnLabel: "Back to 3 new", onTop: {}, onEnd: {}, onReturn: {})
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "sticky-top-end-return",
            width: .standard,
            height: 160
        )
    }

    func testStickyNavigationProgressIsSecondary() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                DetailStickyNavigationBar(title: "B7 2 outs", progressLabel: "18/31 read", endLabel: "Latest", returnLabel: nil, onTop: {}, onEnd: {}, onReturn: {})
                DetailStickyNavigationBar(title: "B7 2 outs", progressLabel: "18/31 read", endLabel: "End", returnLabel: "Back to 3 new", onTop: {}, onEnd: {}, onReturn: {})
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "sticky-progress-secondary",
            width: .standard,
            height: 160
        )
    }

    func testStickyNavigationDarkMode() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                DetailStickyNavigationBar(title: "Final", progressLabel: "31/31 read", endLabel: "End", returnLabel: "Back to Q3", onTop: {}, onEnd: {}, onReturn: {})
                DetailStickyNavigationBar(title: "Q4 01:18", progressLabel: "3 new", endLabel: "Latest", returnLabel: nil, onTop: {}, onEnd: {}, onReturn: {})
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "sticky-dark-mode",
            width: .standard,
            height: 160,
            colorScheme: .dark
        )
    }

    func testStreamControlBarModesAndAffordances() {
        let live = ComponentSnapshotFixtures.game(
            id: 4_104,
            status: "in_progress",
            isLive: true,
            awayScore: 4,
            homeScore: 5,
            eventCount: 6
        )
        let final = ComponentSnapshotFixtures.game(
            id: 4_105,
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 4,
            homeScore: 5,
            eventCount: 6
        )
        let events = [
            ComponentSnapshotFixtures.event(sequence: 1, importance: .primary),
            ComponentSnapshotFixtures.event(sequence: 2, importance: .secondary),
            ComponentSnapshotFixtures.event(sequence: 3, importance: .contextual)
        ]

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                StreamControlBar(
                    game: live,
                    renderer: SportRendererRegistry.renderer(for: live),
                    events: [],
                    isGamePinned: true,
                    isFollowingLiveEdge: true,
                    newPlayCount: 0,
                    canResume: false,
                    selectedMode: .constant(.key),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
                StreamControlBar(
                    game: live,
                    renderer: SportRendererRegistry.renderer(for: live),
                    events: events,
                    isGamePinned: false,
                    isFollowingLiveEdge: true,
                    newPlayCount: 4,
                    canResume: false,
                    selectedMode: .constant(.flow),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
                StreamControlBar(
                    game: final,
                    renderer: SportRendererRegistry.renderer(for: final),
                    events: events,
                    isGamePinned: false,
                    isFollowingLiveEdge: false,
                    newPlayCount: 4,
                    canResume: true,
                    selectedMode: .constant(.full),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "stream-control-affordances",
            width: .standard,
            height: 310
        )
    }

    func testChromeTreatmentComparison() {
        let game = ComponentSnapshotFixtures.liveHomeItem().game

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                GameRowView(item: ComponentSnapshotFixtures.liveHomeItem())
                GameHeaderView(game: game, renderer: SportRendererRegistry.renderer(for: game), isPinned: false, newPlayCount: 2)
                ResumeBanner(description: "Resume from Q3 · 08:42", onResume: {}, onJumpLatest: {}, onStartOver: {})
                DetailStickyNavigationBar(
                    title: "North Arc at Bay Harbor",
                    progressLabel: "18/31 read",
                    endLabel: "Latest",
                    returnLabel: nil,
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                StreamControlBar(
                    game: game,
                    renderer: SportRendererRegistry.renderer(for: game),
                    events: [],
                    isGamePinned: false,
                    isFollowingLiveEdge: true,
                    newPlayCount: 2,
                    canResume: false,
                    selectedMode: .constant(.key),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "shared-chrome-treatment",
            width: .standard,
            height: 620
        )
    }

    func testReadableDetailTopChromeOnIPadPortrait() {
        let game = ComponentSnapshotFixtures.game(
            id: 4_106,
            status: "in_progress",
            isLive: true,
            awayScore: 4,
            homeScore: 5,
            eventCount: 31,
            periodOrdinal: 7,
            periodLabel: "B7",
            clockLabel: "2 outs"
        )
        let events = [
            ComponentSnapshotFixtures.event(sequence: 1, importance: .primary),
            ComponentSnapshotFixtures.event(sequence: 2, importance: .secondary),
            ComponentSnapshotFixtures.event(sequence: 3, importance: .contextual)
        ]

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                DetailStickyNavigationBar(
                    title: "B7 2 outs",
                    progressLabel: "18/31 read",
                    endLabel: "Latest",
                    returnLabel: nil,
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                ResumeBanner(description: "Resume from B6 · 7 new", onResume: {}, onJumpLatest: {}, onStartOver: {})
                StreamControlBar(
                    game: game,
                    renderer: SportRendererRegistry.renderer(for: game),
                    events: events,
                    isGamePinned: true,
                    isFollowingLiveEdge: false,
                    newPlayCount: 7,
                    canResume: true,
                    selectedMode: .constant(.key),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
            }
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
            .padding(.vertical, 14)
            .background(SportsTheme.Colors.paper),
            named: "readable-detail-top-chrome",
            width: .iPad11Full,
            height: 330,
            device: .iPad11Portrait
        )
    }

    func testDetailTopControlsAccessibilityDynamicTypeCompactWidth() {
        let game = ComponentSnapshotFixtures.game(
            id: 4_107,
            status: "in_progress",
            isLive: true,
            awayScore: 4,
            homeScore: 5,
            eventCount: 31,
            periodOrdinal: 7,
            periodLabel: "B7",
            clockLabel: "2 outs"
        )
        let events = [
            ComponentSnapshotFixtures.event(sequence: 1, importance: .primary),
            ComponentSnapshotFixtures.event(sequence: 2, importance: .secondary),
            ComponentSnapshotFixtures.event(sequence: 3, importance: .contextual)
        ]

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                ResumeBanner(
                    description: "Resume from Period 4 · 01:12 · Bay Harbor scoring drive",
                    onResume: {},
                    onJumpLatest: {},
                    onStartOver: {}
                )
                DetailStickyNavigationBar(
                    title: "B7 2 outs",
                    progressLabel: "18/31 read",
                    endLabel: "Latest",
                    returnLabel: "Back to 31 new",
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                StreamControlBar(
                    game: game,
                    renderer: SportRendererRegistry.renderer(for: game),
                    events: events,
                    isGamePinned: true,
                    isFollowingLiveEdge: true,
                    newPlayCount: 31,
                    canResume: true,
                    selectedMode: .constant(.full),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
                NewPlaysAffordance(count: 31, onJumpLatest: {})
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-top-controls-accessibility-compact",
            width: .standard,
            height: 640,
            device: .phoneCompact,
            dynamicTypeSize: .accessibility3
        )
    }

    func testDetailTopControlsWideAccessibilityPressure() {
        let game = ComponentSnapshotFixtures.game(
            id: 4_108,
            status: "in_progress",
            isLive: true,
            awayScore: 4,
            homeScore: 5,
            eventCount: 31,
            periodOrdinal: 7,
            periodLabel: "B7",
            clockLabel: "2 outs"
        )
        let events = [
            ComponentSnapshotFixtures.event(sequence: 1, importance: .primary),
            ComponentSnapshotFixtures.event(sequence: 2, importance: .secondary),
            ComponentSnapshotFixtures.event(sequence: 3, importance: .contextual)
        ]

        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                DetailStickyNavigationBar(
                    title: "B7 2 outs",
                    progressLabel: "18/31 read",
                    endLabel: "Latest",
                    returnLabel: nil,
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                ResumeBanner(
                    description: "Resume from Period 4 · 01:12 · Bay Harbor scoring drive",
                    onResume: {},
                    onJumpLatest: {},
                    onStartOver: {}
                )
                StreamControlBar(
                    game: game,
                    renderer: SportRendererRegistry.renderer(for: game),
                    events: events,
                    isGamePinned: true,
                    isFollowingLiveEdge: true,
                    newPlayCount: 12,
                    canResume: false,
                    selectedMode: .constant(.full),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
            }
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
            .padding(.vertical, 14)
            .background(SportsTheme.Colors.paper),
            named: "detail-top-controls-wide-accessibility",
            width: .tabletReadable,
            height: 700,
            device: .iPad11Portrait,
            dynamicTypeSize: .accessibility4
        )
    }
}
