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

    func testHomeWithoutPinnedGamesIPadPortraitUsesReadableFeed() {
        let viewModel = VisualRegressionFixtures.homeViewModel()

        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [])

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-no-pinned-readable-feed-ipad",
            width: .iPad11Full,
            height: SnapshotDevice.iPad11Portrait.size.height,
            device: .iPad11Portrait
        )
    }

    func testHomeWithPinnedGamesIPadLandscapeUsesReadableFeed() {
        let viewModel = VisualRegressionFixtures.homeViewModel(pinned: true)

        XCTAssertEqual(HomeSectionTestHelpers.pinnedIDs(in: viewModel.filteredHomeSections), [5_003, 5_004])

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-pinned-readable-feed-ipad-landscape",
            width: .iPad11LandscapeFull,
            height: SnapshotDevice.iPad11Landscape.size.height,
            device: .iPad11Landscape
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

    func testHomeSportFilterActivePhoneCompactWidth() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .mlb)

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-sport-filter-active-phone-compact",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeLeagueFilterNCAAFStandardPhoneUsesMenuWithoutTruncation() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .ncaaf)

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-league-filter-ncaaf-standard-phone",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeLeagueFilterNCAABCompactPhoneUsesMenuWithoutTruncation() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .ncaab)

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-league-filter-ncaab-compact-phone",
            width: .compact,
            height: SnapshotDevice.phoneSmall.size.height,
            device: .phoneSmall
        )
    }

    func testHomeActiveFiltersSplitNarrowKeepsHeaderCompact() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .mlb, teamQuery: "Bay")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-split-narrow",
            width: .splitNarrow,
            height: SnapshotDevice.iPadMiniPortrait.size.height,
            device: .iPadMiniPortrait
        )
    }

    func testHomeActiveFiltersPhoneCompactKeepsHeaderCompact() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .mlb, teamQuery: "Bay")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-phone-compact",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeActiveFiltersRegularWidthAccessibilityText() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .nba, teamQuery: "Canyon")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-regular-accessibility",
            width: .tabletReadable,
            height: SnapshotDevice.iPad11Portrait.size.height,
            device: .iPad11Portrait,
            dynamicTypeSize: .accessibility5
        )
    }

    func testHomeActiveFiltersPhoneAccessibilityText() {
        let viewModel = VisualRegressionFixtures.homeViewModel(league: .nba, teamQuery: "Canyon")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-phone-accessibility",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact,
            dynamicTypeSize: .accessibility5
        )
    }

    func testHomeActiveFiltersDarkModeIPad() {
        let viewModel = VisualRegressionFixtures.homeViewModel(pinned: true, league: .mlb, teamQuery: "Bay")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-dark-ipad",
            width: .tabletReadable,
            height: SnapshotDevice.iPad11Portrait.size.height,
            device: .iPad11Portrait,
            colorScheme: .dark
        )
    }

    func testHomeActiveFiltersDarkModeCompactPhone() {
        let viewModel = VisualRegressionFixtures.homeViewModel(pinned: true, league: .mlb, teamQuery: "Bay")

        assertSwiftUISnapshot(
            of: HomeView(viewModel: viewModel),
            named: "home-active-filters-dark-phone-compact",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact,
            colorScheme: .dark
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

    func testHomeKeyboardVisibleFilteringCompactKeepsHeaderAndFirstRowReachable() {
        let viewModel = VisualRegressionFixtures.homeViewModel(teamQuery: "Bay")

        XCTAssertTrue(allVisibleHomeText(in: viewModel.filteredHomeSections).contains("Bay Harbor"))
        XCTAssertFalse(allVisibleHomeText(in: viewModel.filteredHomeSections).contains("Hillcrest Union"))

        assertSwiftUISnapshot(
            of: KeyboardConstrainedHomeSnapshot(viewModel: viewModel, keyboardHeight: 320),
            named: "home-keyboard-filtering-compact",
            width: .standard,
            height: SnapshotDevice.phoneCompact.size.height,
            device: .phoneCompact
        )
    }

    func testHomeKeyboardVisibleFilteringSplitNarrowKeepsHeaderAndFirstRowReachable() {
        let viewModel = VisualRegressionFixtures.homeViewModel(teamQuery: "Bay")

        XCTAssertTrue(allVisibleHomeText(in: viewModel.filteredHomeSections).contains("Bay Harbor"))
        XCTAssertFalse(allVisibleHomeText(in: viewModel.filteredHomeSections).contains("Hillcrest Union"))

        assertSwiftUISnapshot(
            of: KeyboardConstrainedHomeSnapshot(viewModel: viewModel, keyboardHeight: 360),
            named: "home-keyboard-filtering-split-narrow",
            width: .splitNarrow,
            height: SnapshotDevice.iPadMiniPortrait.size.height,
            device: .iPadMiniPortrait
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

private struct KeyboardConstrainedHomeSnapshot: View {
    @ObservedObject var viewModel: HomeViewModel
    let keyboardHeight: CGFloat

    var body: some View {
        HomeView(viewModel: viewModel)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SyntheticKeyboardInset(height: keyboardHeight)
            }
    }
}

private struct SyntheticKeyboardInset: View {
    let height: CGFloat

    var body: some View {
        VStack(spacing: 10) {
            Capsule()
                .fill(SportsTheme.Colors.hairline)
                .frame(width: 48, height: 4)
                .padding(.top, 12)
            HStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(SportsTheme.Colors.paperRaised)
                        .frame(height: 34)
                }
            }
            .padding(.horizontal, 14)
            Spacer(minLength: 0)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(SportsTheme.Colors.paper)
        .overlay(alignment: .top) {
            Divider()
                .overlay(SportsTheme.Colors.hairline)
        }
        .accessibilityHidden(true)
    }
}
