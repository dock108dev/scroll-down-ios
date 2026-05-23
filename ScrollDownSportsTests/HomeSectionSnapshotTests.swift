import SwiftUI
@testable import ScrollDownSports

@MainActor
final class HomeSectionSnapshotTests: SnapshotTestCase {
    func testTimelineSectionsCoverAnchorBandsWithoutPlaceholders() {
        let older = ComponentSnapshotFixtures.timelineSection(
            id: "older-catch-up",
            title: "Older Catch-Up",
            subtitle: "Last 72 Hours",
            role: .olderCatchUp,
            games: [ComponentSnapshotFixtures.finalUnreadHomeItem()],
            date: TestFixtures.fixedDate("2026-05-21T16:00:00Z")
        )
        let today = ComponentSnapshotFixtures.timelineSection(
            id: "today-catch-up",
            title: "Today",
            subtitle: "May 23",
            role: .today,
            games: [ComponentSnapshotFixtures.finalReadHomeItem()],
            date: TestFixtures.fixedDate("2026-05-23T16:00:00Z")
        )
        let live = ComponentSnapshotFixtures.timelineSection(
            id: "live-now",
            title: "Live Now",
            subtitle: "May 23",
            role: .live,
            games: [ComponentSnapshotFixtures.liveHomeItem()],
            date: TestFixtures.fixedDate("2026-05-23T16:00:00Z")
        )
        let upcoming = ComponentSnapshotFixtures.timelineSection(
            id: "upcoming",
            title: "Upcoming",
            subtitle: "May 24",
            role: .upcoming,
            games: [ComponentSnapshotFixtures.scheduledHomeItem()],
            date: TestFixtures.fixedDate("2026-05-24T16:00:00Z")
        )

        assertSwiftUISnapshot(
            of: TimelineSectionView(
                section: HomeTimelineFeedSection(title: "Timeline", dateSections: [older, today, live, upcoming]),
                hasActiveFilters: false,
                clearFilters: {}
            ) { item in
                GameRowView(item: item)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "timeline-anchor-bands",
            width: .standard,
            height: 900
        )
    }

    func testPinnedSectionWithRealPinnedGames() {
        let pinnedLive = ComponentSnapshotFixtures.liveHomeItem(isPinned: true)
        let pinnedResume = ComponentSnapshotFixtures.homeItem(
            game: ComponentSnapshotFixtures.resumeHomeItem().game,
            isPinned: true,
            progress: ComponentSnapshotFixtures.resumeHomeItem().progress
        )

        assertSwiftUISnapshot(
            of: PinnedSectionView(section: HomePinnedSection(title: "Pinned", games: [pinnedLive, pinnedResume])) { item in
                GameRowView(item: item)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "pinned-real-games",
            width: .standard,
            height: 430
        )
    }

    func testPinnedSectionEmptyStateHasNoPlaceholderRows() {
        assertSwiftUISnapshot(
            of: PinnedSectionView(section: HomePinnedSection(title: "Pinned", games: [])) { item in
                GameRowView(item: item)
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "pinned-empty-no-placeholder",
            width: .standard,
            height: 100
        )
    }

    func testFilteredEmptyState() {
        assertSwiftUISnapshot(
            of: FilteredEmptyState {}
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "filtered-empty",
            width: .standard,
            height: 220
        )
    }
}
