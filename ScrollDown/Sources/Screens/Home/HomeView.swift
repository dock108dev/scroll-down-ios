import SwiftUI

/// Main home screen displaying list of games
struct HomeView: View {
    @EnvironmentObject var appConfig: AppConfig
    @State private var games: [GameSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedLeague: LeagueCode?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if games.isEmpty {
                emptyView
            } else {
                gameListView
            }
        }
        .navigationTitle("Scroll Down Sports")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                dataModeIndicator
            }
        }
        .task {
            await loadGames()
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                leagueFilterButton(nil, label: "All")
                ForEach(LeagueCode.allCases, id: \.self) { league in
                    leagueFilterButton(league, label: league.rawValue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func leagueFilterButton(_ league: LeagueCode?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            Task { await loadGames() }
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selectedLeague == league ? Color.blue : Color(.systemGray5))
                .foregroundColor(selectedLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading games...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadGames() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No Games")
                .font(.headline)
            Text("No games found for the selected filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameListView: some View {
        List {
            ForEach(games) { game in
                NavigationLink(value: game) {
                    GameRowView(game: game)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var dataModeIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(appConfig.dataMode == .mock ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            Text(appConfig.dataMode == .mock ? "Mock" : "Live")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadGames() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let service = appConfig.gameService
            let response = try await service.fetchGames(
                league: selectedLeague,
                limit: 50,
                offset: 0
            )
            games = response.games
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(AppConfig.shared)
}
