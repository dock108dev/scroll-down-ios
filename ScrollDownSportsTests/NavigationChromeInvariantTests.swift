import Foundation
import XCTest
@testable import ScrollDownSports

final class NavigationChromeInvariantTests: XCTestCase {
    func testHomeFiltersUseReservedOpaqueSafeAreaHeader() throws {
        let source = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let scrollContentBeforeSafeAreaHeader = source.components(separatedBy: ".safeAreaInset(edge: .top, spacing: 0)").first ?? source

        XCTAssertTrue(source.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        XCTAssertTrue(source.contains("HomeStickyHeader(viewModel: viewModel)"))
        XCTAssertFalse(scrollContentBeforeSafeAreaHeader.contains("FilterHeader(viewModel: viewModel)"))
        XCTAssertTrue(source.contains(".background(SportsTheme.Colors.paper)"))
        XCTAssertFalse(source.contains(".regularMaterial"))
    }

    func testRootAndDetailNavigationBarsUseOpaqueToolbarBackgrounds() throws {
        let contentSource = try repoFile("ScrollDownSports/Views/ContentView.swift")
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(contentSource.contains(".toolbarBackground(.visible, for: .navigationBar)"))
        XCTAssertTrue(contentSource.contains(".toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)"))
        XCTAssertTrue(detailSource.contains(".toolbarBackground(.visible, for: .navigationBar)"))
        XCTAssertTrue(detailSource.contains(".toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)"))
    }

    func testDetailRefreshToolbarControlHasStableSizeAndLabel() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(source.contains(".frame(width: 32, height: 32)"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Refresh game\")"))
    }

    func testDetailScreenHasStickyProgressNavigationWithoutLargeDuplicateCard() throws {
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let streamSource = try repoFile("ScrollDownSports/Views/CatchUpSections.swift")

        XCTAssertTrue(detailSource.contains("DetailStickyNavigationBar("))
        XCTAssertTrue(detailSource.contains("scrollToTop(proxy)"))
        XCTAssertTrue(detailSource.contains("scrollToReturnAnchor(proxy)"))
        XCTAssertTrue(detailSource.contains("scrollToEndOrLatest(proxy)"))
        XCTAssertTrue(detailSource.contains("Back to"))
        XCTAssertTrue(streamSource.contains("Capsule()"))
    }

    func testSportsNativeControlsUseSharedStyleAndFeedback() throws {
        let themeSource = try repoFile("ScrollDownSports/DesignSystem/SportsTheme.swift")
        XCTAssertTrue(themeSource.contains("struct SportsControlButtonStyle"))
        XCTAssertTrue(themeSource.contains("enum SportsFeedback"))

        for path in [
            "ScrollDownSports/Views/HomeView.swift",
            "ScrollDownSports/Views/StreamControlBar.swift",
            "ScrollDownSports/Views/CatchUpSections.swift",
            "ScrollDownSports/Views/GameDetailChrome.swift"
        ] {
            let source = try repoFile(path)
            XCTAssertTrue(source.contains(".sportsControl("), path)
            XCTAssertFalse(source.contains(".buttonStyle(.bordered"), path)
            XCTAssertFalse(source.contains(".buttonStyle(.borderedProminent"), path)
        }
    }

    func testDetailStreamUsesTapeMarkersAndBottomPayoffCue() throws {
        let streamSource = try repoFile("ScrollDownSports/Views/CatchUpSections.swift")
        let polishSource = try repoFile("ScrollDownSports/Views/DetailStreamPolishViews.swift")

        XCTAssertTrue(streamSource.contains("PeriodGroupHeader(label: group.label, accent: renderer.theme.accentColor)"))
        XCTAssertTrue(streamSource.contains("StreamTerminalMarker(game: game)"))
        XCTAssertTrue(polishSource.contains("Live edge"))
        XCTAssertTrue(polishSource.contains("End of stream"))
        XCTAssertFalse(polishSource.contains("Stats and the scoreboard payoff follow."))
    }

    func testGreenIsNotARepeatedChromeAccent() throws {
        let source = try [
            "ScrollDownSports/Views/HomeView.swift",
            "ScrollDownSports/Views/HomeGameCardView.swift",
            "ScrollDownSports/Views/GameDetailChrome.swift",
            "ScrollDownSports/Views/CatchUpSections.swift",
            "ScrollDownSports/Views/StreamControlBar.swift",
            "ScrollDownSports/DesignSystem/SportsTheme.swift"
        ]
            .map(repoFile)
            .joined(separator: "\n")

        XCTAssertFalse(source.contains("systemGreen"))
        XCTAssertFalse(source.contains(".green"))
        XCTAssertFalse(source.contains("systemTeal"))
        XCTAssertFalse(source.contains("Color.accentColor"))
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
