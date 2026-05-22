import Foundation
import SwiftUI

enum LeagueFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mlb = "MLB"
    case nba = "NBA"
    case nhl = "NHL"
    case nfl = "NFL"
    case ncaab = "NCAAB"
    case ncaaf = "NCAAF"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue.lowercased() }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var league: LeagueFilter = .all
    @Published var teamQuery = ""
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private let apiClient: SDAApiClient
    private var refreshTask: Task<Void, Never>?

    init(apiClient: SDAApiClient = .shared) {
        self.apiClient = apiClient
    }

    var filteredGames: [GameSummary] {
        let query = teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sortedGames }
        return sortedGames.filter { game in
            [
                game.homeTeam,
                game.awayTeam,
                game.homeTeamAbbr ?? "",
                game.awayTeamAbbr ?? ""
            ]
            .contains { $0.lowercased().contains(query) }
        }
    }

    private var sortedGames: [GameSummary] {
        games.sorted { left, right in
            if left.gameDate != right.gameDate {
                return left.gameDate < right.gameDate
            }
            return left.id < right.id
        }
    }

    func refresh(silent: Bool = false) async {
        if !silent {
            loading = true
        }
        errorMessage = nil
        do {
            games = try await apiClient.fetchGames(
                window: GameWindow.current(),
                league: league.apiValue
            )
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5 * 60))
                await self?.refresh(silent: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

