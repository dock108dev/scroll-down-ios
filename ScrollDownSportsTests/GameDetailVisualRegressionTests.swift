import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class GameDetailVisualRegressionTests: SnapshotTestCase {
    func testDetailTopResumeStickyAndProgressControls() {
        let detail = VisualRegressionFixtures.detail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: DetailTopVisualRegressionView(detail: detail, renderer: renderer),
            named: "detail-top-resume-sticky-progress",
            width: .standard,
            height: 690,
            device: .phoneCompact
        )
    }

    func testDetailImportantStandardAndAllPlayModes() {
        let detail = VisualRegressionFixtures.detail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(alignment: .leading, spacing: 18) {
                ForEach(DetailStreamMode.allCases) { mode in
                    PlayByPlaySection(
                        game: detail.game,
                        events: detail.events,
                        renderer: renderer,
                        selectedMode: mode,
                        expandedRawFeedKeys: [],
                        onRawFeedExpansionChange: { _, _ in }
                    )
                }
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-stream-modes",
            width: .compact,
            height: 1_240,
            device: .phoneSmall
        )
    }

    func testDetailScoringPlayProgressionAndEndOfStream() {
        let detail = VisualRegressionFixtures.detail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: PlayByPlaySection(
                game: detail.game,
                events: Array(detail.events.suffix(2)),
                renderer: renderer,
                selectedMode: .full,
                expandedRawFeedKeys: [],
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-scoring-progression-end",
            width: .standard,
            height: 430,
            device: .phoneCompact
        )
    }

    func testDetailFinalScoreAndExpandedStats() {
        let detail = VisualRegressionFixtures.detail(leagueCode: "nba")
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(alignment: .leading, spacing: 18) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                BoxScoreSection(game: detail.game, renderer: renderer)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-final-score-expanded-stats",
            width: .large,
            height: 1_040,
            device: .phoneLarge
        )
    }

    func testDetailFinalScoreAndExpandedStatsCompactPhone() {
        let detail = VisualRegressionFixtures.detail(leagueCode: "nba")
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(alignment: .leading, spacing: 18) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                BoxScoreSection(game: detail.game, renderer: renderer)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-final-score-expanded-stats-phone-compact",
            width: .standard,
            height: 1_180,
            device: .phoneCompact
        )
    }

    func testDetailFinalScoreAndExpandedStatsIPadLandscape() {
        let detail = VisualRegressionFixtures.detail(leagueCode: "nba")
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(alignment: .leading, spacing: 18) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                BoxScoreSection(game: detail.game, renderer: renderer)
            }
            .padding(.vertical, 14)
            .background(SportsTheme.Colors.paper)
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset),
            named: "detail-final-score-expanded-stats-ipad-landscape",
            width: .iPad11LandscapeFull,
            height: 1_040,
            device: .iPad11Landscape
        )
    }

    func testDetailEmptyPlayByPlayDarkModeAccessibilityText() {
        assertSwiftUISnapshot(
            of: emptyPlayByPlaySnapshotView(),
            named: "detail-empty-play-by-play",
            width: .standard,
            height: 230,
            device: .phoneCompact,
            colorScheme: .dark,
            dynamicTypeSize: .accessibility2
        )
    }

    func testDetailEmptyPlayByPlaySplitNarrowIPad() {
        assertSwiftUISnapshot(
            of: emptyPlayByPlaySnapshotView(),
            named: "detail-empty-play-by-play-split-narrow",
            width: .splitNarrow,
            height: 260,
            device: .iPadMiniPortrait,
            dynamicTypeSize: .accessibility2
        )
    }

    func testDetailDarkModeIPadShowsChromeControlsAndStats() {
        let detail = VisualRegressionFixtures.detail(leagueCode: "nba")
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: DetailDarkModeIPadSnapshotView(detail: detail, renderer: renderer),
            named: "detail-dark-mode-ipad",
            width: .iPad11Full,
            height: SnapshotDevice.iPad11Portrait.size.height,
            device: .iPad11Portrait,
            colorScheme: .dark
        )
    }

    func testDetailDarkModePhoneShowsChromeControlsAndStats() {
        let detail = VisualRegressionFixtures.detail(leagueCode: "nba")
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: DetailDarkModePhoneSnapshotView(detail: detail, renderer: renderer),
            named: "detail-dark-mode-phone",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact,
            colorScheme: .dark
        )
    }

    private func emptyPlayByPlaySnapshotView() -> some View {
        let detail = TestFixtures.makeDetail(
            game: ComponentSnapshotFixtures.game(
                id: 5_700,
                status: "scheduled",
                isLive: false,
                isFinal: false,
                eventCount: 0,
                hasTimeline: true,
                hasScoreboard: false,
                presentation: ComponentSnapshotFixtures.previewPresentation()
            ),
            events: []
        )
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        return PlayByPlaySection(
            game: detail.game,
            events: detail.events,
            renderer: renderer,
            selectedMode: .full,
            expandedRawFeedKeys: [],
            onRawFeedExpansionChange: { _, _ in }
        )
        .padding(12)
        .background(SportsTheme.Colors.paper)
    }
}

private struct DetailTopVisualRegressionView: View {
    let detail: GameDetail
    let renderer: any SportRenderer

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameHeaderView(game: detail.game, renderer: renderer, isPinned: true, newPlayCount: 3)
            ResumeBanner(
                description: "Resume from Q3 03:18 · 3 new",
                onResume: {},
                onJumpLatest: {},
                onStartOver: {}
            )
            DetailStickyNavigationBar(
                title: "Q4 01:18 · 4/4 read",
                endLabel: "End",
                returnLabel: "Back to Q3",
                onTop: {},
                onEnd: {},
                onReturn: {}
            )
            StreamControlBar(
                game: detail.game,
                renderer: renderer,
                events: detail.events,
                isGamePinned: true,
                isFollowingLiveEdge: false,
                newPlayCount: 3,
                canResume: true,
                selectedMode: .constant(.key),
                onToggleGamePin: {},
                onToggleFollowLive: {},
                onResume: {},
                onJumpLatest: {}
            )
            NewPlaysAffordance(count: 3) {}
            PlayByPlaySection(
                game: detail.game,
                events: Array(detail.events.prefix(2)),
                renderer: renderer,
                selectedMode: .key,
                expandedRawFeedKeys: [],
                onRawFeedExpansionChange: { _, _ in }
            )
        }
        .padding(12)
        .background(SportsTheme.Colors.paper)
    }
}

private struct DetailDarkModeIPadSnapshotView: View {
    let detail: GameDetail
    let renderer: any SportRenderer

    var body: some View {
        ZStack(alignment: .top) {
            SportsPageBackground()
            VStack(alignment: .leading, spacing: 12) {
                GameHeaderView(game: detail.game, renderer: renderer, isPinned: true, newPlayCount: 3)
                DetailStickyNavigationBar(
                    title: "Final · 4/4 read",
                    endLabel: "End",
                    returnLabel: "Back to Q3",
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                StreamControlBar(
                    game: detail.game,
                    renderer: renderer,
                    events: detail.events,
                    isGamePinned: true,
                    isFollowingLiveEdge: false,
                    newPlayCount: 3,
                    canResume: true,
                    selectedMode: .constant(.full),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                BoxScoreSection(game: detail.game, renderer: renderer)
            }
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
            .padding(.vertical, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct DetailDarkModePhoneSnapshotView: View {
    let detail: GameDetail
    let renderer: any SportRenderer

    var body: some View {
        ZStack(alignment: .top) {
            SportsPageBackground()
            VStack(alignment: .leading, spacing: 12) {
                GameHeaderView(game: detail.game, renderer: renderer, isPinned: true, newPlayCount: 3)
                DetailStickyNavigationBar(
                    title: "Final · 4/4 read",
                    endLabel: "End",
                    returnLabel: "Back to Q3",
                    onTop: {},
                    onEnd: {},
                    onReturn: {}
                )
                StreamControlBar(
                    game: detail.game,
                    renderer: renderer,
                    events: detail.events,
                    isGamePinned: true,
                    isFollowingLiveEdge: false,
                    newPlayCount: 3,
                    canResume: true,
                    selectedMode: .constant(.full),
                    onToggleGamePin: {},
                    onToggleFollowLive: {},
                    onResume: {},
                    onJumpLatest: {}
                )
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                BoxScoreSection(game: detail.game, renderer: renderer)
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
