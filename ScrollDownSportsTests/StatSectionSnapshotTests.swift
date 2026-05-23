import SwiftUI
@testable import ScrollDownSports

@MainActor
final class StatSectionSnapshotTests: SnapshotTestCase {
    func testStatSectionEmptyAndMixedStates() {
        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                StatSectionList(sections: [ComponentSnapshotFixtures.emptyStatSection()])
                StatSectionList(sections: [ComponentSnapshotFixtures.mixedStatSection()])
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "stats-empty-mixed",
            width: .standard,
            height: 620
        )
    }

    func testStatSectionWideTableCompactWidth() {
        assertSwiftUISnapshot(
            of: StatSectionList(sections: [ComponentSnapshotFixtures.wideStatSection()])
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "stats-wide-compact",
            width: .compact,
            height: 330
        )
    }

    func testPlayerAndTeamSectionsExpandedAndCollapsed() {
        let detail = ComponentSnapshotFixtures.statDetail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(false))
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "player-team-expanded-collapsed",
            width: .standard,
            height: 720
        )
    }
}
