//
//  HistoryView.swift
//  ScrollDown
//
//  Browse historical games with date picker and league filters.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Date navigator
            DateNavigatorView(
                date: viewModel.selectedDate,
                onBack: { viewModel.navigateDay(-1) },
                onForward: { viewModel.navigateDay(1) },
                onPickDate: { date in
                    viewModel.selectedDate = date
                    Task { await viewModel.loadGames() }
                }
            )

            // League filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    leagueButton(nil, label: "All")
                    ForEach(LeagueCode.allCases, id: \.self) { league in
                        leagueButton(league, label: league.rawValue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            // Content
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadGames() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else if viewModel.games.isEmpty {
                Spacer()
                Text("No games found for this date.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.games) { game in
                            NavigationLink(value: game) {
                                GameRowView(game: game)
                            }
                            .buttonStyle(CardPressButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadGames() }
    }

    private func leagueButton(_ league: LeagueCode?, label: String) -> some View {
        Button {
            viewModel.selectedLeague = league
            Task { await viewModel.loadGames() }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(viewModel.selectedLeague == league ? GameTheme.accentColor : Color(.systemGray5))
                .foregroundStyle(viewModel.selectedLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
