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
        let detail = VisualRegressionFixtures.detail()
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

    func testDetailEmptyPlayByPlayDarkModeAccessibilityText() {
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

        assertSwiftUISnapshot(
            of: PlayByPlaySection(
                game: detail.game,
                events: detail.events,
                renderer: renderer,
                selectedMode: .full,
                expandedRawFeedKeys: [],
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "detail-empty-play-by-play",
            width: .standard,
            height: 230,
            device: .phoneCompact,
            colorScheme: .dark,
            dynamicTypeSize: .accessibility2
        )
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
