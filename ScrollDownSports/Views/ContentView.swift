import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: HomeViewModel

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
        NavigationStack {
            HomeView(viewModel: viewModel)
                .navigationTitle("Scroll Down")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView(gameStateStore: InMemoryGameStateStore())
}
