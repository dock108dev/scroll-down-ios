//
//  LiveOddsView.swift
//  ScrollDown
//
//  Live in-game odds grouped by game, with pull-to-refresh.
//

import SwiftUI

struct LiveOddsView: View {
    @ObservedObject var viewModel: LiveOddsViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading live odds…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.loadLiveGames() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if viewModel.gameGroups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sportscourt")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No live games")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.gameGroups) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                LiveGameHeader(game: group.game, betCount: group.bets.count)

                                ForEach(group.bets) { bet in
                                    BetCard(bet: bet, oddsFormat: .american)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await viewModel.loadLiveGames()
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
}
