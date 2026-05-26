import SwiftUI
@testable import ScrollDownSports

@MainActor
final class EventAndScoreboardSnapshotTests: SnapshotTestCase {
    func testPlayRowsCoverImportanceScoringAndRawFeedStates() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                PlayRow(
                    presentation: ComponentSnapshotFixtures.scoringPlayPresentation(),
                    importance: .critical,
                    rawFeedKey: "critical-score",
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: ComponentSnapshotFixtures.scoringPlayPresentation(),
                    importance: .critical,
                    rawFeedKey: "critical-score",
                    isRawFeedExpanded: true,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: ComponentSnapshotFixtures.eventPresentation(
                        headline: "North Arc forces a long field attempt",
                        eventLabel: "Stop"
                    ),
                    importance: .high,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: ComponentSnapshotFixtures.eventPresentation(
                        headline: "Bay Harbor resets after pressure",
                        eventLabel: "Possession",
                        scoreLabel: "NAR 24, BAY 20"
                    ),
                    importance: .medium,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                PlayRow(
                    presentation: ComponentSnapshotFixtures.eventPresentation(
                        clockText: "",
                        headline: "Line change settles the possession",
                        detail: "Fresh legs enter and the tempo slows.",
                        eventLabel: nil,
                        teamAbbreviation: nil,
                        teamLabel: "Bay Harbor Lights"
                    ),
                    importance: .low,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-importance-states",
            width: .standard,
            height: 660
        )
    }

    func testPlayRowGeneratedHeadlineAndCompactWidth() {
        assertSwiftUISnapshot(
            of: PlayRow(
                presentation: ComponentSnapshotFixtures.eventPresentation(
                    clockText: "P2 00:38",
                    headline: "Generated headline prefers a readable scoring-chance summary instead of raw provider enum text",
                    detail: "The detail remains secondary and wraps without crowding the event label or score progression.",
                    eventLabel: "Chance",
                    teamAbbreviation: "BAY"
                ),
                importance: .medium,
                rawFeedKey: nil,
                isRawFeedExpanded: false,
                onRawFeedExpansionChange: { _, _ in }
            )
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "play-row-long-headline-compact",
            width: .compact,
            height: 190
        )
    }

    func testScoreboardContentLayouts() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 8))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.simpleTotalScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.soccerScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.leaderboardScoreboard())
            }
            .padding(12)
            .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "scoreboard-layouts",
            width: .standard,
            height: 760
        )
    }

    func testScoreboardContentWideWidthKeepsRowsDense() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 8))
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.simpleTotalScoreboard())
                Divider()
                ScoreboardContent(presentation: ComponentSnapshotFixtures.leaderboardScoreboard())
            }
            .padding(12)
            .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "scoreboard-layouts-wide",
            width: .tabletReadable,
            height: 560,
            device: .iPad11Portrait
        )
    }

    func testScoreboardAndEventHierarchyTogether() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 12) {
                PlayRow(
                    presentation: ComponentSnapshotFixtures.scoringPlayPresentation(),
                    importance: .critical,
                    rawFeedKey: nil,
                    isRawFeedExpanded: false,
                    onRawFeedExpansionChange: { _, _ in }
                )
                ScoreboardContent(presentation: ComponentSnapshotFixtures.segmentScoreboard(periodCount: 4))
                    .padding(12)
                    .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card))
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "event-scoreboard-hierarchy",
            width: .standard,
            height: 310
        )
    }

    func testReadableDetailPlayStreamOnIPadLandscape() {
        let detail = VisualRegressionFixtures.detail()

        assertSwiftUISnapshot(
            of: PlayByPlaySection(
                game: detail.game,
                events: detail.events,
                renderer: SportRendererRegistry.renderer(for: detail.game),
                selectedMode: .full,
                expandedRawFeedKeys: [],
                onRawFeedExpansionChange: { _, _ in }
            )
            .sportsReadableContent(maxWidth: \.detailContentMaxWidth, horizontalInset: \.detailHorizontalInset)
            .padding(.vertical, 14)
            .background(SportsTheme.Colors.paper),
            named: "readable-detail-play-stream",
            width: .iPad11LandscapeFull,
            height: 720,
            device: .iPad11Landscape
        )
    }
}
