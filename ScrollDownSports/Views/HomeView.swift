import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        List {
            Section {
                FilterHeader(viewModel: viewModel)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if viewModel.loading && viewModel.games.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if let error = viewModel.errorMessage, viewModel.games.isEmpty {
                ErrorState(message: error) {
                    Task { await viewModel.refresh() }
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredGames.isEmpty {
                EmptyState()
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(viewModel.filteredGames) { game in
                        NavigationLink {
                            GameDetailView(gameId: game.id, summary: game)
                        } label: {
                            GameRowView(game: game)
                        }
                    }
                } header: {
                    Text("Last 72 hours to next 48 hours")
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            guard !AppEnvironment.isRunningTests else { return }
            await viewModel.refresh()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .onChange(of: viewModel.league) { _, _ in
            Task { await viewModel.refresh() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.loading)
            }
        }
    }
}

private struct FilterHeader: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("League", selection: $viewModel.league) {
                ForEach(LeagueFilter.allCases) { league in
                    Text(league.rawValue).tag(league)
                }
            }
            .pickerStyle(.segmented)

            TextField("Filter by team", text: $viewModel.teamQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct GameRowView: View {
    let game: GameSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(game.leagueCode.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                Spacer()
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
            }

            Text(game.matchupText)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                Label(DateFormatters.shortTime.string(from: game.gameDate), systemImage: "calendar")
                if let playCount = game.playCount, playCount > 0 {
                    Label("\(playCount) plays", systemImage: "list.bullet.rectangle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var statusText: String {
        if game.isFinalGame { return "Final" }
        if game.isLiveGame { return "Live" }
        if game.isPregame { return "Upcoming" }
        return game.status.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var statusColor: Color {
        if game.isLiveGame { return .green }
        if game.isFinalGame { return .secondary }
        return .orange
    }
}

private struct EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No games in this window",
            systemImage: "calendar.badge.exclamationmark",
            description: Text("Try another league or team filter.")
        )
    }
}

private struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "Unable to load games",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
