import SwiftUI
import XCTest
@testable import ScrollDownSports

final class NavigationShellInvariantTests: XCTestCase {
    func testRootOwnsAdaptiveStackAndSplitShells() throws {
        let source = try repoFile("ScrollDownSports/Views/ContentView.swift")

        XCTAssertTrue(source.contains("SportsLayoutMetrics("))
        XCTAssertTrue(source.contains("layout.isSplitNavigationEligible"))
        XCTAssertTrue(source.contains("@State private var compactPath: [HomeGameRoute] = []"))
        XCTAssertTrue(source.contains("@State private var selectedGameRoute: HomeGameRoute?"))
        XCTAssertTrue(source.contains("NavigationStack(path: $compactPath)"))
        XCTAssertTrue(source.contains("NavigationSplitView {"))
        XCTAssertTrue(source.contains("HomeView(viewModel: viewModel, gameActivation: gameActivation)"))
        XCTAssertTrue(source.contains("GameDetailView("))
        XCTAssertTrue(source.contains("EmptyGameDetailView()"))
        XCTAssertTrue(source.contains(".toolbarBackground(.visible, for: .navigationBar)"))
        XCTAssertTrue(source.contains(".toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)"))
    }

    func testRegularSplitUsesSeparateEmptyDetailUntilRealRouteIsSelected() throws {
        let source = try repoFile("ScrollDownSports/Views/ContentView.swift")
        let regularDetailColumn = try sourceBlock(
            in: source,
            startingAt: "var regularDetailColumn: some View",
            endingBefore: "func gameDetail(for route: HomeGameRoute)"
        )
        let emptyDetailSurface = try sourceBlockToEnd(in: source, startingAt: "struct EmptyGameDetailView: View")

        XCTAssertTrue(regularDetailColumn.contains("if let selectedGameRoute"))
        XCTAssertTrue(regularDetailColumn.contains("gameDetail(for: selectedGameRoute)"))
        XCTAssertTrue(regularDetailColumn.contains("EmptyGameDetailView()"))
        XCTAssertFalse(regularDetailColumn.contains("GameDetailView(\n"))
        XCTAssertTrue(emptyDetailSurface.contains("Choose a game from the timeline to catch up."))
        XCTAssertTrue(emptyDetailSurface.contains(".accessibilityIdentifier(\"detail.empty\")"))
        XCTAssertFalse(emptyDetailSurface.contains("GameDetailView("))
        XCTAssertFalse(emptyDetailSurface.contains("markViewed"))
        XCTAssertFalse(emptyDetailSurface.contains("fetchGame"))
        XCTAssertFalse(emptyDetailSurface.contains("gameStateStore"))
    }

    @MainActor
    func testRegularRootRendersEmptyDetailWithoutStoreMutation() {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let view = SnapshotHost(
            width: SnapshotWidth.iPad11Full.points,
            minHeight: SnapshotDevice.iPad11Portrait.size.height,
            horizontalSizeClass: .regular,
            verticalSizeClass: .regular
        ) {
            ContentView(
                gameStateStore: store,
                apiClient: TestFixtures.makeAPIClient(responses: [], protocolClass: MockNavigationShellURLProtocol.self),
                now: { TestFixtures.fixedDate() }
            )
        }

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1

        XCTAssertNotNil(renderer.uiImage)
        XCTAssertNil(store.progress(for: -1))
        XCTAssertNil(store.progress(for: 0))
        XCTAssertTrue(store.snapshot.progressByGameId.isEmpty)
    }

    @MainActor
    func testContentShellFactoriesBuildEmptyAndRealDetailSurfaces() {
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })
        let contentView = ContentView(
            gameStateStore: store,
            apiClient: TestFixtures.makeAPIClient(responses: [], protocolClass: MockNavigationShellURLProtocol.self),
            now: { TestFixtures.fixedDate() }
        )
        let route = HomeGameRoute(game: TestFixtures.makeGame(id: 6501))

        assertBuildsView(contentView.regularShell)
        assertBuildsView(contentView.regularDetailColumn)
        assertBuildsView(contentView.gameDetail(for: route))
        assertBuildsView(contentView.homeView(gameActivation: .push))
        assertBuildsView(EmptyGameDetailView().body)
        contentView.refreshSelectedSummary(from: [route.summary].compactMap(\.self))

        XCTAssertNil(store.progress(for: -1))
        XCTAssertNil(store.progress(for: 0))
        XCTAssertNil(store.progress(for: route.gameId))
    }

    @MainActor
    func testDirectDetailConstructionStillUsesRealGameIDSummaryAndSharedStore() {
        let game = TestFixtures.makeGame(id: 6401)
        let store = InMemoryGameStateStore(now: { TestFixtures.fixedDate() })

        let view = GameDetailView(gameId: game.id, summary: game, gameStateStore: store)

        XCTAssertEqual(view.gameId, game.id)
        XCTAssertEqual(view.summary?.id, game.id)
        XCTAssertNil(store.progress(for: -1))
        XCTAssertNil(store.progress(for: 0))
    }

    func testSelectedDetailRouteCarriesSummaryButPreservesIDIdentity() throws {
        let source = try repoFile("ScrollDownSports/Views/ContentView.swift")
        let detailFactory = try sourceBlock(
            in: source,
            startingAt: "func gameDetail(for route: HomeGameRoute)",
            endingBefore: "func refreshSelectedSummary"
        )
        let summaryRefresh = try sourceBlock(
            in: source,
            startingAt: "func refreshSelectedSummary",
            endingBefore: "#Preview"
        )

        XCTAssertTrue(detailFactory.contains("gameId: route.gameId"))
        XCTAssertTrue(detailFactory.contains("summary: route.summary"))
        XCTAssertTrue(detailFactory.contains("gameStateStore: viewModel.gameStateStore"))
        XCTAssertTrue(detailFactory.contains(".id(route.gameId)"))
        XCTAssertFalse(detailFactory.contains("gameId: 0"))
        XCTAssertFalse(detailFactory.contains("gameId: -1"))
        XCTAssertTrue(summaryRefresh.contains("guard let selectedGameRoute else { return }"))
        XCTAssertTrue(summaryRefresh.contains("guard let game = games.first(where: { $0.id == selectedGameRoute.gameId }) else { return }"))
        XCTAssertTrue(summaryRefresh.contains("self.selectedGameRoute = HomeGameRoute(game: game)"))
    }

    func testDetailLoadingErrorAndSummaryFallbackStatesStayOnSelectedRoute() throws {
        let source = try repoFile("ScrollDownSports/Views/GameDetailView.swift")
        let initializer = try sourceBlock(
            in: source,
            startingAt: "init(",
            endingBefore: "var body: some View"
        )
        let unavailableState = try sourceBlock(
            in: source,
            startingAt: "private func unavailableDetailState",
            endingBefore: "private var pendingNewPlayCount"
        )
        let chromeSource = try repoFile("ScrollDownSports/Views/GameDetailChrome.swift")
        let loadErrorState = try sourceBlock(
            in: chromeSource,
            startingAt: "struct DetailLoadErrorState",
            endingBefore: "struct ResumeBanner"
        )

        XCTAssertTrue(initializer.contains("gameId: Int"))
        XCTAssertTrue(initializer.contains("summary: Game? = nil"))
        XCTAssertTrue(initializer.contains("apiClient: SDAApiClient = .shared"))
        XCTAssertTrue(initializer.contains("gameStateStore: any GameStateStore"))
        XCTAssertTrue(initializer.contains("GameDetailViewModel("))
        XCTAssertTrue(initializer.contains("gameId: gameId"))
        XCTAssertTrue(unavailableState.contains("GameHeaderPlaceholder(summary: summary"))
        XCTAssertTrue(unavailableState.contains("viewModel.loading"))
        XCTAssertTrue(unavailableState.contains(".accessibilityIdentifier(\"detail.loading\")"))
        XCTAssertTrue(unavailableState.contains("DetailLoadErrorState(message: error)"))
        XCTAssertTrue(unavailableState.contains("Task { await viewModel.refresh() }"))
        XCTAssertTrue(loadErrorState.contains("retry()"))
        XCTAssertTrue(loadErrorState.contains(".buttonStyle(.sportsControl(tone: .critical"))
        XCTAssertTrue(loadErrorState.contains(".accessibilityIdentifier(\"detail.retry\")"))
    }

    func testHomeRowsUseInjectedActivationWithoutOwningDetailDestinations() throws {
        let source = try repoFile("ScrollDownSports/Views/HomeView.swift")

        XCTAssertTrue(source.contains("enum HomeGameActivationMode"))
        XCTAssertTrue(source.contains("case push"))
        XCTAssertTrue(source.contains("case select(selectedGameId: Int?, select: (HomeGameItem) -> Void)"))
        XCTAssertTrue(source.contains("NavigationLink(value: HomeGameRoute(item: item))"))
        XCTAssertTrue(source.contains("select(item)"))
        XCTAssertTrue(source.contains("accessibilityAddTraits(isSelected ? [.isSelected] : [])"))
        XCTAssertFalse(source.contains("GameDetailView("))
        XCTAssertFalse(source.contains("HomeViewForIPad"))
        XCTAssertFalse(source.contains("GameDetailViewForIPad"))
    }

    func testPinControlsDoNotMutateSelectionRoutes() throws {
        let source = try repoFile("ScrollDownSports/Views/HomeView.swift")
        let pinControl = try sourceBlock(
            in: source,
            startingAt: "HomePinButton(isPinned: item.isPinned)",
            endingBefore: ".accessibilityIdentifier(\"home.gameRow.\\(item.id).pin\")"
        )
        let contextMenu = try sourceBlock(
            in: source,
            startingAt: ".contextMenu {",
            endingBefore: ".swipeActions(edge: .trailing, allowsFullSwipe: true)"
        )
        let swipeAction = try sourceBlock(
            in: source,
            startingAt: ".swipeActions(edge: .trailing, allowsFullSwipe: true)",
            endingBefore: "@ViewBuilder"
        )

        for controlSource in [pinControl, contextMenu, swipeAction] {
            XCTAssertTrue(controlSource.contains("viewModel.togglePin(item.game)"))
            XCTAssertFalse(controlSource.contains("select(item)"))
            XCTAssertFalse(controlSource.contains("selectedGameId"))
            XCTAssertFalse(controlSource.contains("HomeGameRoute"))
        }
    }

    func testRouteIdentityIsStableByGameIDOnly() {
        let original = TestFixtures.makeGame(id: 6301, awayName: "Seattle Mariners", homeName: "New York Yankees")
        let refreshed = TestFixtures.makeGame(id: 6301, awayName: "Boston Red Sox", homeName: "Toronto Blue Jays")
        let other = TestFixtures.makeGame(id: 6302)

        let firstRoute = HomeGameRoute(game: original)
        let refreshedRoute = HomeGameRoute(game: refreshed)
        let otherRoute = HomeGameRoute(game: other)

        XCTAssertEqual(firstRoute, refreshedRoute)
        XCTAssertNotEqual(firstRoute, otherRoute)
        XCTAssertEqual(Set([firstRoute, refreshedRoute, otherRoute]).count, 2)
        XCTAssertEqual(firstRoute.summary?.awayParticipant?.name, "Seattle Mariners")
    }

    private func repoFile(_ path: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent(path)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    private func sourceBlock(
        in source: String,
        startingAt start: String,
        endingBefore end: String
    ) throws -> String {
        let startRange = try XCTUnwrap(source.range(of: start))
        let remaining = source[startRange.lowerBound...]
        let endRange = try XCTUnwrap(remaining.range(of: end))
        return String(remaining[..<endRange.lowerBound])
    }

    private func sourceBlockToEnd(in source: String, startingAt start: String) throws -> String {
        let startRange = try XCTUnwrap(source.range(of: start))
        return String(source[startRange.lowerBound...])
    }

    private func assertBuildsView<V: View>(_ view: V, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(String(describing: type(of: view)).isEmpty, file: file, line: line)
    }
}

private final class MockNavigationShellURLProtocol: MockHTTPURLProtocol {}
