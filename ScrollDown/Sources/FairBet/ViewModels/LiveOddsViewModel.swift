//
//  LiveOddsViewModel.swift
//  ScrollDown
//
//  ViewModel for live in-game odds with polling-based refresh.
//

import Foundation
import SwiftUI

@MainActor
final class LiveOddsViewModel: ObservableObject {
    @Published var liveGames: [LiveGameInfo] = []
    @Published var gameGroups: [LiveGameGroup] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastRefreshed: Date?

    private let apiClient: FairBetAPIClient
    private var pollingTask: Task<Void, Never>?

    private static let pollInterval: TimeInterval = 30

    init(apiClient: FairBetAPIClient = .shared) {
        self.apiClient = apiClient
    }

    deinit {
        pollingTask?.cancel()
    }

    // MARK: - Load

    func loadLiveGames() async {
        isLoading = gameGroups.isEmpty
        errorMessage = nil

        do {
            let games = try await apiClient.fetchLiveGames()
            liveGames = games

            // Fetch odds for each live game
            var groups: [LiveGameGroup] = []
            for game in games {
                let response = try await apiClient.fetchLiveOdds(gameId: game.gameId)
                groups.append(LiveGameGroup(game: game, bets: response.bets))
            }
            gameGroups = groups
            lastRefreshed = Date()
        } catch {
            if gameGroups.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
        isRefreshing = false
    }

    func refresh() async {
        isRefreshing = true
        await loadLiveGames()
    }

    // MARK: - Polling

    func startPolling() {
        stopPolling()
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Self.pollInterval * 1_000_000_000))
                guard !Task.isCancelled else { break }
                await loadLiveGames()
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
