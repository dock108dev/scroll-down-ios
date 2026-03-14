//
//  MLBSimulatorViewModel.swift
//  ScrollDown
//
//  ViewModel for the MLB Monte Carlo simulator.
//  Manages team selection, roster loading, lineup building, and simulation.
//

import Foundation
import SwiftUI

@MainActor
final class MLBSimulatorViewModel: ObservableObject {
    // MARK: - Published State

    // Teams
    @Published var teams: [SimulatorTeam] = []
    @Published var isLoadingTeams = false

    // Selection
    @Published var awayTeam: SimulatorTeam?
    @Published var homeTeam: SimulatorTeam?

    // Rosters
    @Published var awayBatters: [RosterBatter] = []
    @Published var awayPitchers: [RosterPitcher] = []
    @Published var homeBatters: [RosterBatter] = []
    @Published var homePitchers: [RosterPitcher] = []
    @Published var isLoadingRoster = false

    // Lineup (9 slots per side + starter pitcher)
    @Published var awayLineup: [RosterBatter?] = Array(repeating: nil, count: 9)
    @Published var homeLineup: [RosterBatter?] = Array(repeating: nil, count: 9)
    @Published var awayStarter: RosterPitcher?
    @Published var homeStarter: RosterPitcher?

    // Simulation
    @Published var result: SimulatorResult?
    @Published var isSimulating = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let apiClient: SimulatorAPIClient

    init(apiClient: SimulatorAPIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Computed

    var canSimulate: Bool {
        awayTeam != nil && homeTeam != nil && awayTeam != homeTeam
    }

    var hasLineupCustomization: Bool {
        awayLineup.contains(where: { $0 != nil }) ||
        homeLineup.contains(where: { $0 != nil }) ||
        awayStarter != nil || homeStarter != nil
    }

    // MARK: - Load Teams

    func loadTeams() async {
        guard teams.isEmpty else { return }
        isLoadingTeams = true
        errorMessage = nil
        do {
            let response = try await apiClient.fetchTeams()
            teams = response.teams.sorted { $0.name < $1.name }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingTeams = false
    }

    // MARK: - Select Team

    func selectAwayTeam(_ team: SimulatorTeam?) {
        awayTeam = team
        awayLineup = Array(repeating: nil, count: 9)
        awayStarter = nil
        awayBatters = []
        awayPitchers = []
        result = nil
        if let team { Task { await loadRoster(for: team, side: .away) } }
    }

    func selectHomeTeam(_ team: SimulatorTeam?) {
        homeTeam = team
        homeLineup = Array(repeating: nil, count: 9)
        homeStarter = nil
        homeBatters = []
        homePitchers = []
        result = nil
        if let team { Task { await loadRoster(for: team, side: .home) } }
    }

    enum Side { case home, away }

    private func loadRoster(for team: SimulatorTeam, side: Side) async {
        isLoadingRoster = true
        do {
            let roster = try await apiClient.fetchRoster(team: team.abbreviation)
            switch side {
            case .away:
                awayBatters = roster.batters.sorted { $0.gamesPlayed > $1.gamesPlayed }
                awayPitchers = roster.pitchers.sorted { $0.games > $1.games }
            case .home:
                homeBatters = roster.batters.sorted { $0.gamesPlayed > $1.gamesPlayed }
                homePitchers = roster.pitchers.sorted { $0.games > $1.games }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingRoster = false
    }

    // MARK: - Simulate

    func runSimulation() async {
        guard let away = awayTeam, let home = homeTeam else { return }
        isSimulating = true
        errorMessage = nil

        let awaySlots: [LineupSlot]? = awayLineup.contains(where: { $0 != nil })
            ? awayLineup.compactMap { batter in
                guard let b = batter else { return nil }
                return LineupSlot(externalRef: b.externalRef, name: b.name)
            }
            : nil

        let homeSlots: [LineupSlot]? = homeLineup.contains(where: { $0 != nil })
            ? homeLineup.compactMap { batter in
                guard let b = batter else { return nil }
                return LineupSlot(externalRef: b.externalRef, name: b.name)
            }
            : nil

        let awayPitcherSlot: PitcherSlot? = awayStarter.map {
            PitcherSlot(externalRef: $0.externalRef, name: $0.name, avgIp: $0.avgIp)
        }
        let homePitcherSlot: PitcherSlot? = homeStarter.map {
            PitcherSlot(externalRef: $0.externalRef, name: $0.name, avgIp: $0.avgIp)
        }

        let request = SimulationRequest(
            sport: "mlb",
            homeTeam: home.abbreviation,
            awayTeam: away.abbreviation,
            iterations: 10000,
            probabilityMode: nil,
            homeLineup: homeSlots,
            awayLineup: awaySlots,
            homeStarter: homePitcherSlot,
            awayStarter: awayPitcherSlot,
            starterInnings: nil,
            excludePlayoffs: true
        )

        do {
            result = try await apiClient.simulate(request: request)
            HapticService.notification(.success)
        } catch {
            errorMessage = error.localizedDescription
            HapticService.notification(.error)
        }
        isSimulating = false
    }

    // MARK: - Reset

    func reset() {
        awayTeam = nil
        homeTeam = nil
        awayBatters = []
        awayPitchers = []
        homeBatters = []
        homePitchers = []
        awayLineup = Array(repeating: nil, count: 9)
        homeLineup = Array(repeating: nil, count: 9)
        awayStarter = nil
        homeStarter = nil
        result = nil
        errorMessage = nil
    }
}
