import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appConfig: AppConfig
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .game(let id, let league):
                        GameDetailView(gameId: id, leagueCode: league)
                            .onAppear {
                                GameRoutingLogger.logNavigation(tappedId: id, destinationId: id, league: league)
                            }
                    case .team(let name, let abbreviation, let league):
                        TeamView(teamName: name, abbreviation: abbreviation, leagueCode: league)
                    }
                }
        }
    }
}

enum AppRoute: Hashable {
    case game(id: Int, league: String)
    case team(name: String, abbreviation: String, league: String)
}

#Preview {
    ContentView()
        .environmentObject(AppConfig.shared)
        .environmentObject(ReadStateStore.shared)
}

