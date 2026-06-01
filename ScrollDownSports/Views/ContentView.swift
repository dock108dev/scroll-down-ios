import SwiftUI

struct HomeGameRoute: Identifiable, Hashable {
    let gameId: Int
    let summary: Game?

    var id: Int { gameId }

    init(gameId: Int, summary: Game?) {
        self.gameId = gameId
        self.summary = summary
    }

    init(item: HomeGameItem) {
        self.init(gameId: item.id, summary: item.game)
    }

    init(game: Game) {
        self.init(gameId: game.id, summary: game)
    }

    init?(notificationUserInfo: [AnyHashable: Any]?, games: [Game]) {
        guard let gameId = FavoriteGameNotificationTapBridge.gameId(from: notificationUserInfo) else {
            return nil
        }
        self.init(gameId: gameId, summary: games.first { $0.id == gameId })
    }

    static func == (lhs: HomeGameRoute, rhs: HomeGameRoute) -> Bool {
        lhs.gameId == rhs.gameId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gameId)
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @StateObject private var viewModel: HomeViewModel
    @State private var compactPath: [HomeGameRoute] = []
    @State private var selectedGameRoute: HomeGameRoute?

    init(
        gameStateStore: any GameStateStore,
        apiClient: SDAApiClient = .shared,
        now: @escaping () -> Date = Date.init
    ) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                apiClient: apiClient,
                now: now,
                gameStateStore: gameStateStore
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = SportsLayoutMetrics(
                availableWidth: geometry.size.width,
                availableHeight: geometry.size.height,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass,
                dynamicTypeSize: dynamicTypeSize
            )

            Group {
                if layout.isSplitNavigationEligible {
                    regularShell
                } else {
                    compactShell
                }
            }
            .environment(\.sportsLayoutMetrics, layout)
            .onChange(of: compactPath) { _, path in
                if let route = path.last {
                    selectedGameRoute = route
                }
            }
            .onChange(of: viewModel.games) { _, games in
                refreshSelectedSummary(from: games)
            }
            .onReceive(NotificationCenter.default.publisher(for: FavoriteGameNotificationTapBridge.notificationName)) { notification in
                openNotificationRoute(userInfo: notification.userInfo)
            }
        }
    }

    var compactShell: some View {
        NavigationStack(path: $compactPath) {
            homeView(gameActivation: .push)
                .navigationDestination(for: HomeGameRoute.self) { route in
                    gameDetail(for: route)
                }
        }
    }

    var regularShell: some View {
        NavigationSplitView {
            homeView(
                gameActivation: .select(
                    selectedGameId: selectedGameRoute?.gameId,
                    select: { item in
                        selectedGameRoute = HomeGameRoute(item: item)
                    }
                )
            )
        } detail: {
            regularDetailColumn
        }
        .navigationSplitViewStyle(.balanced)
    }

    func homeView(gameActivation: HomeGameActivationMode) -> some View {
        HomeView(viewModel: viewModel, gameActivation: gameActivation)
            .navigationTitle("Scroll Down")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
    }

    @ViewBuilder
    var regularDetailColumn: some View {
        if let selectedGameRoute {
            gameDetail(for: selectedGameRoute)
        } else {
            EmptyGameDetailView()
        }
    }

    func gameDetail(for route: HomeGameRoute) -> some View {
        GameDetailView(
            gameId: route.gameId,
            summary: route.summary,
            gameStateStore: viewModel.gameStateStore
        )
        .id(route.gameId)
    }

    func refreshSelectedSummary(from games: [Game]) {
        guard let selectedGameRoute else { return }
        guard let game = games.first(where: { $0.id == selectedGameRoute.gameId }) else { return }
        self.selectedGameRoute = HomeGameRoute(game: game)
    }

    func openNotificationRoute(userInfo: [AnyHashable: Any]?) {
        guard let route = HomeGameRoute(notificationUserInfo: userInfo, games: viewModel.games) else { return }
        selectedGameRoute = route
        compactPath = [route]
    }
}

#Preview {
    ContentView(gameStateStore: InMemoryGameStateStore())
}

struct EmptyGameDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a game",
            systemImage: "sportscourt",
            description: Text("Choose a game from the timeline to catch up.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SportsPageBackground() }
        .navigationTitle("Catch Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
        .accessibilityIdentifier("detail.empty")
    }
}
