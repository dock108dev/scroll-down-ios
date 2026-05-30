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

    func testStatSectionWideTableRegularWidthUsesCappedExpansion() {
        assertSwiftUISnapshot(
            of: StatSectionList(sections: [ComponentSnapshotFixtures.wideStatSection()])
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "stats-wide-regular",
            width: .standard,
            height: 330
        )
    }

    func testStatSectionWideTableTabletWidthKeepsNumericColumnsDense() {
        assertSwiftUISnapshot(
            of: StatSectionList(sections: [ComponentSnapshotFixtures.wideStatSection()])
                .padding(12)
                .background(SportsTheme.Colors.paper),
            named: "stats-wide-tablet",
            width: .tabletReadable,
            height: 330,
            device: .iPad11Portrait
        )
    }

    func testPlayerAndTeamSectionsCollapsedStates() {
        let detail = ComponentSnapshotFixtures.statDetail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(false))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(false))
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "player-team-collapsed",
            width: .standard,
            height: 260
        )
    }

    func testPlayerAndTeamSectionsExpandedStates() {
        let detail = ComponentSnapshotFixtures.statDetail()
        let renderer = SportRendererRegistry.renderer(for: detail.game)

        assertSwiftUISnapshot(
            of: VStack(spacing: 14) {
                PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
                TeamStatsSection(detail: detail, renderer: renderer, isExpanded: .constant(true))
            }
            .padding(12)
            .background(SportsTheme.Colors.paper),
            named: "player-team-expanded",
            width: .standard,
            height: 760
        )
    }
}
