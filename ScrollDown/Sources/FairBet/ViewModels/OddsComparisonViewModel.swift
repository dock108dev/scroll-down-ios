//
//  OddsComparisonViewModel.swift
//  ScrollDown
//
//  ViewModel for odds comparison - fetches and displays betting odds
//  Loads ALL data for accurate stats and filtering
//

import Foundation
import SwiftUI

@MainActor
final class OddsComparisonViewModel: ObservableObject {
    private enum StorageKeys {
        static let oddsFormat = "oddsFormatPreference"
        static let hideLimitedData = "hideLimitedData"
    }

    // MARK: - Published Properties

    /// All bets from API (full dataset)
    @Published var allBets: [APIBet] = []

    /// Filtered/sorted bets for display
    @Published var displayedBets: [APIBet] = []

    @Published var booksAvailable: [String] = []
    @Published var gamesAvailable: [GameDropdown] = []
    @Published var marketCategoriesAvailable: [String] = []
    @Published var evDiagnostics: EVDiagnostics?
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var loadingProgress: String = ""
    @Published var loadingFraction: Double = 0
    @Published var errorMessage: String?

    // Filters
    @Published var selectedLeague: FairBetLeague? {
        didSet { applyFilters() }
    }
    @Published var selectedMarketFilter: MarketFilter? {
        didSet { applyFilters() }
    }
    @Published var showOnlyPositiveEV: Bool = false {
        didSet { applyFilters() }
    }
    @Published var sortOption: SortOption = .bestEV {
        didSet { applyFilters() }
    }
    @Published var searchText: String = "" {
        didSet { applyFilters() }
    }

    // Parlay
    @Published var parlayBetIDs: Set<String> = []
    @Published var showParlaySheet: Bool = false
    @Published var parlayApiResult: FairBetAPIClient.ParlayEvaluation?

    @Published var oddsFormat: OddsFormat = .american {
        didSet { saveOddsFormat() }
    }

    @Published var hideLimitedData: Bool = true {
        didSet {
            saveLimitedDataPref()
            applyFilters()
        }
    }

    // MARK: - Sort Options

    enum SortOption: String, CaseIterable {
        case bestEV = "Best EV"
        case gameTime = "Game Time"
        case league = "League"
    }

    // MARK: - Dependencies

    private let apiClient: FairBetAPIClient

    // MARK: - Computed Properties (Global Stats)

    /// Bets with sufficient data (3+ books)
    private var qualifiedBets: [APIBet] {
        allBets.filter { $0.books.count >= 3 }
    }

    /// Total bets with sufficient data
    var totalBetsCount: Int {
        qualifiedBets.count
    }

    /// Total +EV opportunities (only counts reliable high-confidence bets with 3+ books)
    var positiveEVCount: Int {
        qualifiedBets.filter { betHasReliablePositiveEV($0) }.count
    }

    /// Rarity percentage of +EV opportunities
    var positiveEVRarity: Double {
        guard totalBetsCount > 0 else { return 0 }
        return (Double(positiveEVCount) / Double(totalBetsCount)) * 100
    }

    /// Best EV percentage available (from qualified bets only)
    var bestEVAvailable: Double? {
        qualifiedBets.compactMap { bestEV(for: $0) }.max()
    }

    /// Best bet (highest EV from qualified bets)
    var bestBet: APIBet? {
        qualifiedBets.max { bestEV(for: $0) < bestEV(for: $1) }
    }

    /// Breakdown by league (qualified bets only)
    var leagueBreakdown: [(league: FairBetLeague, total: Int, positiveEV: Int)] {
        FairBetLeague.allCases.map { league in
            let leagueBets = qualifiedBets.filter { $0.league == league }
            let positiveEV = leagueBets.filter { betHasReliablePositiveEV($0) }.count
            return (league: league, total: leagueBets.count, positiveEV: positiveEV)
        }.filter { $0.total > 0 }
    }

    /// Filtered stats
    var filteredTotalCount: Int {
        displayedBets.count
    }

    var filteredPositiveEVCount: Int {
        displayedBets.filter { betHasReliablePositiveEV($0) }.count
    }

    // MARK: - Parlay Computed Properties

    var parlayCount: Int { parlayBetIDs.count }

    /// Resolved from allBets so filter changes don't lose selections
    var parlayBets: [APIBet] {
        allBets.filter { parlayBetIDs.contains($0.id) }
    }

    var canShowParlay: Bool { parlayCount >= 2 }

    var parlayFairProbability: Double {
        if let api = parlayApiResult { return api.fairProbability }
        let bets = parlayBets
        guard !bets.isEmpty else { return 0 }
        return bets.reduce(1.0) { result, bet in
            let prob = bet.trueProb ?? 0.5
            return result * prob
        }
    }

    var parlayFairAmericanOdds: Int {
        if let api = parlayApiResult { return api.fairAmericanOdds }
        let prob = parlayFairProbability
        guard prob > 0 && prob < 1 else { return 100 }
        let decimal = 1.0 / prob
        if decimal >= 2.0 {
            return Int((decimal - 1.0) * 100)
        } else {
            return Int(-100.0 / (decimal - 1.0))
        }
    }

    var parlayConfidence: FairOddsConfidence {
        let confidences = parlayBets.map { confidence(for: $0) }
        guard !confidences.isEmpty else { return .none }
        let order: [FairOddsConfidence] = [.none, .low, .medium, .high]
        return confidences.min(by: { order.firstIndex(of: $0)! < order.firstIndex(of: $1)! }) ?? .none
    }

    // MARK: - Initialization

    init(apiClient: FairBetAPIClient = .shared) {
        self.apiClient = apiClient
        loadOddsFormat()
        loadLimitedDataPref()
    }

    // MARK: - Public Methods

    /// Load data progressively: show first page immediately, then load remaining in background
    func loadAllData() async {
        let isInitialLoad = allBets.isEmpty
        isLoading = true
        errorMessage = nil
        let limit = 500

        if isInitialLoad {
            loadingProgress = "Loading bets…"
            loadingFraction = 0
        }

        do {
            // Phase 1: Fetch first page → display immediately
            let firstResponse = try await apiClient.fetchOdds(
                league: nil,
                limit: limit,
                offset: 0
            )

            allBets = firstResponse.bets
            booksAvailable = firstResponse.booksAvailable
            gamesAvailable = firstResponse.gamesAvailable ?? []
            marketCategoriesAvailable = firstResponse.marketCategoriesAvailable ?? []
            evDiagnostics = firstResponse.evDiagnostics

            applyFilters()

            isLoading = false
            loadingProgress = ""
            loadingFraction = 0

            let totalExpected = firstResponse.total

            // Phase 2: Fetch remaining pages concurrently
            if firstResponse.bets.count >= limit && firstResponse.bets.count < totalExpected {
                isLoadingMore = true
                defer { isLoadingMore = false }

                // Build list of remaining offsets
                var offsets: [Int] = []
                var offset = limit
                while offset < totalExpected {
                    offsets.append(offset)
                    offset += limit
                }

                // Fetch pages concurrently (max 3 at a time)
                let remainingBets: [APIBet] = try await withThrowingTaskGroup(of: (Int, [APIBet]).self) { group in
                    var results: [(Int, [APIBet])] = []
                    var activeCount = 0
                    var offsetIndex = 0

                    // Seed initial batch
                    while offsetIndex < offsets.count && activeCount < 3 {
                        let currentOffset = offsets[offsetIndex]
                        group.addTask { [apiClient] in
                            let response = try await apiClient.fetchOdds(
                                league: nil,
                                limit: limit,
                                offset: currentOffset
                            )
                            return (currentOffset, response.bets)
                        }
                        activeCount += 1
                        offsetIndex += 1
                    }

                    // As each completes, add next
                    for try await result in group {
                        results.append(result)
                        if offsetIndex < offsets.count {
                            let currentOffset = offsets[offsetIndex]
                            group.addTask { [apiClient] in
                                let response = try await apiClient.fetchOdds(
                                    league: nil,
                                    limit: limit,
                                    offset: currentOffset
                                )
                                return (currentOffset, response.bets)
                            }
                            offsetIndex += 1
                        }
                    }

                    // Sort by offset to maintain order, then flatten
                    return results.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
                }

                if !remainingBets.isEmpty {
                    allBets.append(contentsOf: remainingBets)
                    applyFilters()
                }
            }

        } catch {
            if allBets.isEmpty {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            isLoadingMore = false
            loadingProgress = ""
            loadingFraction = 0
        }
    }

    /// Refresh all data
    func refresh() async {
        await loadAllData()
    }

    /// Select a league filter
    func selectLeague(_ league: FairBetLeague?) {
        selectedLeague = league
    }

    /// Toggle +EV only filter
    func togglePositiveEVOnly() {
        showOnlyPositiveEV.toggle()
    }

    // MARK: - Parlay

    func toggleParlay(_ bet: APIBet) {
        if parlayBetIDs.contains(bet.id) {
            parlayBetIDs.remove(bet.id)
        } else {
            parlayBetIDs.insert(bet.id)
        }
        Task { await evaluateParlayViaAPI() }
    }

    func isInParlay(_ bet: APIBet) -> Bool {
        parlayBetIDs.contains(bet.id)
    }

    func clearParlay() {
        parlayBetIDs.removeAll()
        parlayApiResult = nil
    }

    /// Evaluate parlay via API, falling back to client-side math on failure
    private func evaluateParlayViaAPI() async {
        let bets = parlayBets
        guard bets.count >= 2 else {
            parlayApiResult = nil
            return
        }

        let legs = bets.map { bet in
            FairBetAPIClient.ParlayLeg(
                gameId: bet.gameId,
                marketKey: bet.marketKey,
                selectionKey: bet.selectionKey,
                lineValue: bet.lineValue
            )
        }

        do {
            parlayApiResult = try await apiClient.evaluateParlay(legs: legs)
        } catch {
            // Silently fall back to client-side math
            parlayApiResult = nil
        }
    }

    /// Load mock data for previews
    func loadMockData() {
        let response = FairBetMockDataProvider.shared.getMockBetsResponse()
        allBets = response.bets
        booksAvailable = response.booksAvailable
        applyFilters()
    }

    // MARK: - Private Methods

    /// Apply all filters and sorting
    private func applyFilters() {
        var filtered = allBets

        // Hide games that have already started (no live support)
        let now = Date()
        filtered = filtered.filter { $0.gameDate > now }

        // Require minimum 3 books for reliable data
        filtered = filtered.filter { $0.books.count >= 3 }

        // Hide thin markets (low/none confidence)
        if hideLimitedData {
            filtered = filtered.filter { bet in
                let conf = confidence(for: bet)
                return conf == .high || conf == .medium
            }
        }

        // League filter
        if let league = selectedLeague {
            filtered = filtered.filter { $0.league == league }
        }

        // Market filter
        if let marketFilter = selectedMarketFilter {
            filtered = filtered.filter { marketFilter.matches($0.market) }
        }

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter {
                $0.homeTeam.lowercased().contains(query) ||
                $0.awayTeam.lowercased().contains(query) ||
                $0.selection.lowercased().contains(query) ||
                ($0.playerName?.lowercased().contains(query) ?? false)
            }
        }

        // +EV only filter
        if showOnlyPositiveEV {
            filtered = filtered.filter { betHasPositiveEV($0) }
        }

        // Sort
        switch sortOption {
        case .bestEV:
            filtered = filtered.sorted { bestEV(for: $0) > bestEV(for: $1) }
        case .gameTime:
            filtered = filtered.sorted { $0.gameDate < $1.gameDate }
        case .league:
            filtered = filtered.sorted { $0.leagueCode < $1.leagueCode }
        }

        displayedBets = filtered
    }

    /// Check if a bet has positive EV (any confidence level - for display)
    private func betHasPositiveEV(_ bet: APIBet) -> Bool {
        bestEV(for: bet) > 0
    }

    /// Check if a bet has RELIABLE positive EV (medium/high confidence - for stats)
    private func betHasReliablePositiveEV(_ bet: APIBet) -> Bool {
        let ev = bestEV(for: bet)
        let conf = confidence(for: bet)
        return ev > 0 && (conf == .high || conf == .medium)
    }

    /// Get confidence level for a bet from API tier
    func confidence(for bet: APIBet) -> FairOddsConfidence {
        guard let tier = bet.evConfidenceTier else { return .none }
        switch tier {
        case "full": return .high
        case "decent": return .medium
        case "thin": return .low
        default: return .none
        }
    }

    /// Get best EV for a bet from API fields
    func bestEV(for bet: APIBet) -> Double {
        bet.bestEvPercent ?? 0
    }

    private func loadOddsFormat() {
        guard let stored = UserDefaults.standard.string(forKey: StorageKeys.oddsFormat),
              let format = OddsFormat(rawValue: stored) else {
            return
        }
        oddsFormat = format
    }

    private func saveOddsFormat() {
        UserDefaults.standard.set(oddsFormat.rawValue, forKey: StorageKeys.oddsFormat)
    }

    private func loadLimitedDataPref() {
        hideLimitedData = UserDefaults.standard.object(forKey: StorageKeys.hideLimitedData) as? Bool ?? true
    }

    private func saveLimitedDataPref() {
        UserDefaults.standard.set(hideLimitedData, forKey: StorageKeys.hideLimitedData)
    }
}
