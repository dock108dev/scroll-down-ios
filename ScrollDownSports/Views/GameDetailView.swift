import SwiftUI

struct GameDetailView: View {
    let gameId: Int
    let summary: GameSummary?

    @StateObject private var viewModel: GameDetailViewModel

    init(gameId: Int, summary: GameSummary? = nil) {
        self.gameId = gameId
        self.summary = summary
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                if let detail = viewModel.detail {
                    GameHeaderView(game: detail.game)
                    PlayByPlaySection(plays: detail.plays)
                    PlayerStatsSection(detail: detail)
                    TeamStatsSection(detail: detail)
                    BoxScoreSection(game: detail.game)
                } else if viewModel.loading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView(
                        "Unable to load game",
                        systemImage: "wifi.exclamationmark",
                        description: Text(error)
                    )
                    .padding(.top, 80)
                } else if let summary {
                    GameHeaderPlaceholder(summary: summary)
                }
            }
            .padding()
        }
        .navigationTitle("Catch Up")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !AppEnvironment.isRunningTests else { return }
            await viewModel.refresh()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}

private struct GameHeaderView: View {
    let game: Game

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(game.leagueCode.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                Spacer()
                Text(DateFormatters.shortTime.string(from: game.gameDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(game.matchupText)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            if let label = game.currentPeriodLabel, game.isLiveGame {
                Text([label, game.gameClock].compactMap { $0 }.joined(separator: " "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GameHeaderPlaceholder: View {
    let summary: GameSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(summary.leagueCode.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
            Text(summary.matchupText)
                .font(.largeTitle.weight(.bold))
            Text(DateFormatters.shortTime.string(from: summary.gameDate))
                .foregroundStyle(.secondary)
        }
    }
}
