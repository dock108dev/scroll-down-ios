//
//  HistoryViewModel.swift
//  ScrollDown
//
//  ViewModel for browsing historical games with date range and league filters.
//

import Foundation
import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filters
    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @Published var selectedLeague: LeagueCode?

    // Pagination
    @Published var hasMore = false
    private var currentOffset = 0
    private let pageSize = 50

    func loadGames() async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0

        do {
            let service = AppConfig.shared.gameService
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: selectedDate)

            let response = try await service.fetchGames(range: .earlier, league: selectedLeague)
            // Filter by selected date
            games = response.games.filter { game in
                game.gameDate.hasPrefix(dateStr)
            }
            hasMore = response.games.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func navigateDay(_ offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        selectedDate = newDate
        Task { await loadGames() }
    }
}
