import SwiftUI
import XCTest
@testable import ScrollDownSports

@MainActor
final class HomeVisualRegressionTests: SnapshotTestCase {
    func testHomeWithoutPinnedGamesCoversTimelineStatesAndPlaceholderFiltering() {
        let viewModel = VisualRegressionFixtures.homeViewModel()

        XCTAssertFalse(allVisibleHomeText(in: viewModel.filteredHomeSections).contains("TBD"))
        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [])
        XCTAssertEqual(
            HomeSectionTestHelpers.timelineSectionIDs(in: viewModel.filteredHomeSections),
            ["timeline-older", "timeline-yesterday", "timeline-live", "timeline-later-today", "timeline-upcoming"]
        )

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-no-pinned-anchor-live-upcoming",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeWithRealPinnedGames() {
        let viewModel = VisualRegressionFixtures.homeViewModel(pinned: true)

        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [5_003, 5_004])

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-real-pinned-games",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeSportFilterActiveSmallWidth() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .mlb)

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-sport-filter-active",
            width: .compact,
            height: SnapshotDevice.phoneSmall.size.height,
            device: .phoneSmall
        )
    }

    func testHomeTeamSearchActiveAccessibilityText() {
        let viewModel = VisualRegressionFixtures.homeViewModel(teamQuery: "Bay")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-team-search-active",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact,
            dynamicTypeSize: .accessibility2
        )
    }

    func testHomeDarkModeLargePhone() {
        let viewModel = VisualRegressionFixtures.homeViewModel(pinned: true)

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-dark-large-phone",
            width: .large,
            height: SnapshotDevice.phoneLarge.size.height,
            device: .phoneLarge,
            colorScheme: .dark
        )
    }

    private func allVisibleHomeText(in sections: [HomeSection]) -> String {
        sections.flatMap { section -> [String] in
            switch section {
            case .pinned(let pinned):
                return pinned.games.flatMap(gameText)
            case .timeline(let timeline):
                return timeline.dateSections.flatMap { dateSection in
                    [dateSection.title, dateSection.subtitle] + dateSection.games.flatMap(gameText)
                }
            }
        }
        .joined(separator: " ")
    }

    private func gameText(_ item: HomeGameItem) -> [String] {
        [
            item.game.awayParticipant?.name,
            item.game.awayParticipant?.abbreviation,
            item.game.homeParticipant?.name,
            item.game.homeParticipant?.abbreviation
        ]
        .compactMap(\.self)
    }
}
