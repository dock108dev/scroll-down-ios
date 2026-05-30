import Foundation
import XCTest
@testable import ScrollDownSports

final class NavigationChromeInvariantTests: XCTestCase {
    func testHomeFiltersUseReservedOpaqueSafeAreaHeader() throws {
        let homeSource = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let headerSource = try repoFile("ScrollDownSports/Views/HomeStickyHeaderView.swift")
        let scrollContentBeforeSafeAreaHeader = homeSource
            .components(separatedBy: ".safeAreaInset(edge: .top, spacing: 0)")
            .first ?? homeSource

        XCTAssertTrue(homeSource.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        XCTAssertTrue(homeSource.contains("HomeStickyHeader(viewModel: viewModel)"))
        XCTAssertFalse(scrollContentBeforeSafeAreaHeader.contains("FilterHeader(viewModel: viewModel)"))
        XCTAssertTrue(headerSource.contains(".background(SportsTheme.Colors.paper)"))
        XCTAssertFalse(homeSource.contains(".regularMaterial"))
        XCTAssertFalse(headerSource.contains(".regularMaterial"))
    }

    func testHomeFeedAndStickyHeaderShareReadableSingleColumnPolicy() throws {
        let homeSource = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let headerSource = try repoFile("ScrollDownSports/Views/HomeStickyHeaderView.swift")
        let metricsSource = try repoFile("ScrollDownSports/DesignSystem/SportsLayoutMetrics.swift")
        let scrollContentBeforeSafeAreaHeader = homeSource
            .components(separatedBy: ".safeAreaInset(edge: .top, spacing: 0)")
            .first ?? homeSource

        XCTAssertTrue(scrollContentBeforeSafeAreaHeader.contains(".sportsReadableContent()"))
        XCTAssertTrue(headerSource.contains("FilterHeader(viewModel: viewModel)\n            .sportsReadableContent()"))
        XCTAssertFalse(homeSource.contains("LazyVGrid"))
        XCTAssertFalse(homeSource.contains("GridItem"))
        XCTAssertTrue(metricsSource.contains("contentMaxWidth = 680"))
        XCTAssertTrue(metricsSource.contains("self.cardGridColumns = 1"))
    }

    func testHomeStickyHeaderUsesCompactShelfTreatment() throws {
        let headerSource = try repoFile("ScrollDownSports/Views/HomeStickyHeaderView.swift")

        XCTAssertTrue(headerSource.contains("HomeShelfControlChrome"))
        XCTAssertTrue(headerSource.contains("static let shelfVerticalSpacing: CGFloat = 5"))
        XCTAssertTrue(headerSource.contains("SportsTheme.Colors.paperInset.opacity"))
        XCTAssertTrue(headerSource.contains("private var teamSearchStroke: Color"))
        XCTAssertFalse(headerSource.contains("SportsTheme.Colors.paperRaised"))
        XCTAssertFalse(headerSource.contains(".shadow("))
    }

    func testHomePinChromeKeepsStableHitTargetAndCardReservation() throws {
        let homeSource = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let cardSource = try repoFile("ScrollDownSports/Views/HomeGameCardView.swift")
        let summaryCardSource = try repoFile("ScrollDownSports/Views/GameSummaryCard.swift")

        XCTAssertTrue(cardSource.contains("static let pinVisibleSize: CGFloat = 34"))
        XCTAssertTrue(cardSource.contains("static let pinHitTargetSize: CGFloat = 44"))
        XCTAssertTrue(cardSource.contains("static let pinTrailingReservation"))
        XCTAssertTrue(summaryCardSource.contains(".padding(.trailing, trailingReservation)"))
        XCTAssertTrue(summaryCardSource.contains("HomeGameCardLayout.pinTrailingReservation"))
        XCTAssertTrue(
            cardSource.contains(
                ".frame(width: HomeGameCardLayout.pinHitTargetSize, height: HomeGameCardLayout.pinHitTargetSize)"
            )
        )
        XCTAssertTrue(homeSource.contains(".padding(.top, HomeGameCardLayout.pinOverlayPadding)"))
        XCTAssertTrue(homeSource.contains(".padding(.trailing, HomeGameCardLayout.pinOverlayPadding)"))
    }

    func testRootAndDetailNavigationBarsUseOpaqueToolbarBackgrounds() throws {
        let contentSource = try repoFile("ScrollDownSports/Views/ContentView.swift")
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(contentSource.contains(".toolbarBackground(.visible, for: .navigationBar)"))
        XCTAssertTrue(contentSource.contains(".toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)"))
        XCTAssertTrue(detailSource.contains(".toolbarBackground(.visible, for: .navigationBar)"))
        XCTAssertTrue(detailSource.contains(".toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)"))
    }

    func testPrimaryScreensUseNeutralPageBackgroundWithoutScorebookGridTexture() throws {
        let themeSource = try repoFile("ScrollDownSports/DesignSystem/SportsTheme.swift")
        let homeSource = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let diagramSource = try [
            "ScrollDownSports/Views/BaseballScorebookViews.swift",
            "ScrollDownSports/Views/BasketballHalfCourtPressureView.swift",
            "ScrollDownSports/Views/FootballFieldStripView.swift",
            "ScrollDownSports/Views/HockeyRinkStripView.swift",
            "ScrollDownSports/Views/SituationDiagramViews.swift",
            "ScrollDownSports/Views/SoccerPitchStripView.swift"
        ]
            .map(repoFile)
            .joined(separator: "\n")

        XCTAssertTrue(homeSource.contains(".background { SportsPageBackground() }"))
        XCTAssertTrue(detailSource.contains(".background { SportsPageBackground() }"))
        XCTAssertTrue(themeSource.contains("struct SportsPageBackground"))
        XCTAssertFalse(themeSource.contains("ScorebookGrid"))
        XCTAssertFalse(themeSource.contains("GridOpacity"))
        XCTAssertTrue(diagramSource.contains("SportsTheme.Colors.scorebookLine"))
    }

    func testDetailRefreshToolbarControlHasStableSizeAndLabel() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")

        XCTAssertTrue(source.contains("Image(systemName: \"arrow.clockwise\")"))
        XCTAssertTrue(source.contains(".frame(minWidth: 44, minHeight: 44)"))
        XCTAssertTrue(source.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Refresh game\")"))
    }

    func testHomeRefreshToolbarControlHasStableSizeAndLabel() throws {
        let source = try repoFile("ScrollDownSports/Views/HomeView.swift")

        XCTAssertTrue(source.contains("Image(systemName: \"arrow.clockwise\")"))
        XCTAssertTrue(source.contains(".frame(minWidth: 44, minHeight: 44)"))
        XCTAssertTrue(source.contains(".contentShape(Rectangle())"))
        XCTAssertTrue(source.contains(".accessibilityLabel(\"Refresh games\")"))
        XCTAssertTrue(source.contains(".accessibilityIdentifier(\"home.refresh\")"))
    }

    func testDetailFeedAndStickyChromeShareReadableColumnPolicy() throws {
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let metricsSource = try repoFile("ScrollDownSports/DesignSystem/SportsLayoutMetrics.swift")

        XCTAssertTrue(metricsSource.contains("detailMaxWidth = 640"))
        XCTAssertTrue(metricsSource.contains("let detailInset: CGFloat = usesReadableWidth ? 24 : 16"))
        XCTAssertEqual(detailSource.components(separatedBy: "maxWidth: \\.detailContentMaxWidth").count - 1, 3)
        XCTAssertEqual(detailSource.components(separatedBy: "horizontalInset: \\.detailHorizontalInset").count - 1, 3)
        XCTAssertTrue(detailSource.contains("NewPlaysAffordance(count: pendingNewPlayCount)"))
        XCTAssertTrue(detailSource.contains("Spacer(minLength: 0)\n                            NewPlaysAffordance"))
    }

    func testDetailScreenHasStickyProgressNavigationWithoutLargeDuplicateCard() throws {
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let chromeSource = try repoFile("ScrollDownSports/Views/DetailNavigationChrome.swift")

        XCTAssertTrue(detailSource.contains("DetailStickyNavigationBar("))
        XCTAssertTrue(detailSource.contains("scrollToTop(proxy)"))
        XCTAssertTrue(detailSource.contains("scrollToReturnAnchor(proxy)"))
        XCTAssertTrue(detailSource.contains("scrollToEndOrLatest(proxy)"))
        XCTAssertTrue(detailSource.contains("Back to"))
        XCTAssertTrue(chromeSource.contains("Capsule()"))
    }

    func testDetailStickyChromeUsesNeutralSurfaceWithoutFloatingShadow() throws {
        let chromeSource = try repoFile("ScrollDownSports/Views/DetailNavigationChrome.swift")

        XCTAssertTrue(chromeSource.contains("let progressLabel: String?"))
        XCTAssertTrue(chromeSource.contains(".background(SportsTheme.Colors.paperRaised, in: Capsule())"))
        XCTAssertTrue(chromeSource.contains(".buttonStyle(.sportsControl(tone: .neutral, compact: compact))"))
        XCTAssertTrue(chromeSource.contains(".frame(minWidth: 44, minHeight: 44)"))
        XCTAssertFalse(chromeSource.contains(".shadow(color: .black.opacity(0.06)"))
        XCTAssertFalse(chromeSource.contains(".background(SportsTheme.Colors.ink, in: Capsule())"))
        XCTAssertFalse(chromeSource.contains(".sportsControl(tone: .scoreboard, filled: true"))
    }

    func testReturnAnchorRemainsViewLocalAndClearsAfterBackToSpot() throws {
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let storeSource = try repoFile("ScrollDownSports/Persistence/GameStateStore.swift")

        XCTAssertTrue(detailSource.contains("@State private var returnAnchor: DetailVisibleEventState?"))
        XCTAssertTrue(detailSource.contains("private func rememberReturnAnchor()"))
        XCTAssertTrue(detailSource.contains("return \"Back to \\(returnAnchor.label)\""))
        XCTAssertTrue(detailSource.contains("private func scrollToReturnAnchor(_ proxy: ScrollViewProxy)"))
        XCTAssertTrue(detailSource.contains("returnAnchor = nil"))
        XCTAssertFalse(storeSource.contains("returnAnchor"))
    }

    func testResumeBannerKeepsResumePrimaryWithLatestAndStartOverSecondary() throws {
        let detailSource = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let streamSource = try repoFile("ScrollDownSports/Views/GameDetailChrome.swift")

        let resumeButtonRange = try XCTUnwrap(streamSource.range(of: "Text(\"Resume\")"))
        let menuRange = try XCTUnwrap(streamSource.range(of: "Menu {"))
        XCTAssertLessThan(resumeButtonRange.lowerBound, menuRange.lowerBound)
        XCTAssertTrue(streamSource.contains("Label(\"Jump latest\", systemImage: \"arrow.down.to.line\")"))
        XCTAssertTrue(streamSource.contains("Label(\"Start over\", systemImage: \"restart\")"))
        XCTAssertTrue(streamSource.contains("Button(role: .destructive)"))
        XCTAssertTrue(streamSource.contains("@State private var showStartOverConfirmation = false"))
        XCTAssertTrue(streamSource.contains(".accessibilityIdentifier(\"detail.resume.more\")"))
        XCTAssertTrue(streamSource.contains(".confirmationDialog("))
        XCTAssertTrue(streamSource.contains("Button(\"Start Over\", role: .destructive)"))
        XCTAssertTrue(streamSource.contains("Button(\"Keep Saved Position\", role: .cancel)"))
        XCTAssertFalse(detailSource.contains("showStartOverConfirmation"))
        XCTAssertFalse(detailSource.contains(".confirmationDialog("))
    }

    func testSportsNativeControlsUseSharedStyleAndFeedback() throws {
        let themeSource = try repoFile("ScrollDownSports/DesignSystem/SportsTheme.swift")
        XCTAssertTrue(themeSource.contains("struct SportsControlButtonStyle"))
        XCTAssertTrue(themeSource.contains("enum SportsFeedback"))

        for path in [
            "ScrollDownSports/Views/HomeSectionsView.swift",
            "ScrollDownSports/Views/StreamControlBar.swift",
            "ScrollDownSports/Views/CatchUpSections.swift",
            "ScrollDownSports/Views/GameDetailChrome.swift",
            "ScrollDownSports/Views/DetailNavigationChrome.swift"
        ] {
            let source = try repoFile(path)
            XCTAssertTrue(source.contains(".sportsControl("), path)
            XCTAssertFalse(source.contains(".buttonStyle(.bordered"), path)
            XCTAssertFalse(source.contains(".buttonStyle(.borderedProminent"), path)
        }
    }

    func testSportsSurfacesUseNeutralDefaultStrokesWithAccentOptIn() throws {
        let themeSource = try repoFile("ScrollDownSports/DesignSystem/SportsTheme.swift")
        let homeCardSource = try repoFile("ScrollDownSports/Views/HomeGameCardView.swift")
        let detailChromeSource = try repoFile("ScrollDownSports/Views/GameDetailChrome.swift")
        let summaryCardSource = try repoFile("ScrollDownSports/Views/GameSummaryCard.swift")
        let playRowSource = try repoFile("ScrollDownSports/Views/PlayRow.swift")

        XCTAssertTrue(themeSource.contains("usesAccentStroke: Bool = false"))
        XCTAssertTrue(themeSource.contains("if usesAccentStroke, let accent"))
        XCTAssertTrue(themeSource.contains(".sportsSurface(.compactTableRow)"))
        XCTAssertFalse(themeSource.contains(".sportsSurface(.compactTableRow, accent:"))
        XCTAssertFalse(themeSource.contains("filled ? tone.accent.opacity(0.0) : SportsTheme.Stroke.accent"))

        XCTAssertTrue(summaryCardSource.contains(".stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.9)"))
        XCTAssertFalse(homeCardSource.contains("SportsTheme.Stroke.accent(accent("))

        XCTAssertTrue(summaryCardSource.contains(".gameHeaderCard,"))
        XCTAssertTrue(summaryCardSource.contains("usesAccentStroke: state.usesStrongLiveTreatment"))
        XCTAssertFalse(detailChromeSource.contains(".background(SportsTheme.Tone.scoreboard.accent"))

        XCTAssertTrue(playRowSource.contains(".stroke(SportsTheme.Stroke.subdued(), lineWidth: 0.75)"))
        XCTAssertFalse(playRowSource.contains("SportsTheme.Stroke.accent(accentColor)"))
    }

    func testDetailStreamUsesTapeMarkersAndBottomPayoffCue() throws {
        let streamSource = try repoFile("ScrollDownSports/Views/CatchUpSections.swift")
        let polishSource = try repoFile("ScrollDownSports/Views/DetailStreamPolishViews.swift")

        XCTAssertTrue(
            streamSource.contains("PeriodGroupHeader(label: group.label, accent: renderer.theme.accentColor)")
        )
        XCTAssertTrue(streamSource.contains("StreamTerminalMarker(game: game)"))
        XCTAssertTrue(polishSource.contains("Live edge"))
        XCTAssertTrue(polishSource.contains("End of stream"))
        XCTAssertFalse(polishSource.contains("Stats and the scoreboard payoff follow."))
    }

    func testGreenIsNotARepeatedChromeAccent() throws {
        let source = try [
            "ScrollDownSports/Views/HomeView.swift",
            "ScrollDownSports/Views/HomeSectionsView.swift",
            "ScrollDownSports/Views/HomeGameCardView.swift",
            "ScrollDownSports/Views/GameDetailChrome.swift",
            "ScrollDownSports/Views/DetailNavigationChrome.swift",
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
