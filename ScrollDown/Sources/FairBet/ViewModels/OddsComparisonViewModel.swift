//
//  OddsComparisonViewModel.swift
//  ScrollDown
//
//  ViewModel for odds comparison - fetches and displays betting odds
//  Loads ALL data for accurate stats and client-side filtering
//

import Foundation
import SwiftUI

@MainActor
final class OddsComparisonViewModel: ObservableObject {
    /// Only include odds from these 5 sportsbooks
    static let allowedBooks: Set<String> = [
        "DraftKings", "FanDuel", "BetMGM", "Caesars", "bet365"
    ]

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
    @Published var isLoading: Bool = false
    @Published var loadingProgress: String = ""
    @Published var errorMessage: String?

    // Filters
    @Published var selectedLeague: FairBetLeague? {
        didSet { applyFilters() }
    }
    @Published var selectedMarket: MarketKey? {
        didSet { applyFilters() }
    }
    @Published var showOnlyPositiveEV: Bool = false {
        didSet { applyFilters() }
    }
    @Published var sortOption: SortOption = .bestEV {
        didSet { applyFilters() }
    }

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
    private let mockDataProvider: FairBetMockDataProvider

    // MARK: - Cached Computations (for performance)

    /// Pre-computed pairs for vig removal (computed once per data load)
    private var cachedPairs: [String: APIBet] = [:]

    /// Cached EV results per bet ID (EV value + confidence)
    private var cachedEVResults: [String: EVResult] = [:]

    /// Result of EV calculation including confidence level and fair probability
    struct EVResult {
        let ev: Double
        let confidence: FairOddsConfidence
        let fairProbability: Double
        let fairAmericanOdds: Int

        /// Only count as +EV if we have reliable data (medium+ confidence with vig removal)
        var isReliablyPositive: Bool {
            ev > 0 && (confidence == .high || confidence == .medium)
        }
    }

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

    // MARK: - Initialization

    init(apiClient: FairBetAPIClient = .shared, mockDataProvider: FairBetMockDataProvider = .shared) {
        self.apiClient = apiClient
        self.mockDataProvider = mockDataProvider
        loadOddsFormat()
        loadLimitedDataPref()
    }

    // MARK: - Public Methods

    /// Load ALL data from the API (fetch all pages)
    func loadAllData() async {
        isLoading = true
        errorMessage = nil
        allBets = []
        loadingProgress = "Loading odds..."

        do {
            var allFetchedBets: [APIBet] = []
            var offset = 0
            let limit = 500 // Max per request
            var hasMore = true

            while hasMore {
                loadingProgress = "Loading \(allFetchedBets.count)+ bets..."

                let response = try await apiClient.fetchOdds(
                    league: nil, // Fetch all leagues
                    limit: limit,
                    offset: offset
                )

                allFetchedBets.append(contentsOf: response.bets)
                booksAvailable = response.booksAvailable

                // Check if we got all data
                if response.bets.count < limit || allFetchedBets.count >= response.total {
                    hasMore = false
                } else {
                    offset += limit
                }
            }

            allBets = allFetchedBets
                .map { $0.filteringBooks(to: Self.allowedBooks) }
                .filter { !$0.books.isEmpty }
            booksAvailable = booksAvailable.filter { Self.allowedBooks.contains($0) }
            loadingProgress = "Calculating EV for \(allBets.count) bets..."

            // Pre-compute pairs once (O(n) instead of O(n²))
            cachedPairs = BetPairingService.pairBets(allBets)

            // Pre-compute all EVs once
            computeAllEVs()

            applyFilters()

        } catch {
            errorMessage = error.localizedDescription
            loadMockData()
        }

        isLoading = false
        loadingProgress = ""
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

    /// Load mock data for previews and testing
    func loadMockData() {
        let response = mockDataProvider.getMockBetsResponse()
        allBets = response.bets
            .map { $0.filteringBooks(to: Self.allowedBooks) }
            .filter { !$0.books.isEmpty }
        booksAvailable = response.booksAvailable.filter { Self.allowedBooks.contains($0) }
        cachedPairs = BetPairingService.pairBets(allBets)
        computeAllEVs()
        applyFilters()
    }

    // MARK: - Private Methods

    /// Apply all filters and sorting
    private func applyFilters() {
        var filtered = allBets

        // Require minimum 3 books for reliable data
        filtered = filtered.filter { $0.books.count >= 3 }

        // Hide limited data (low/none confidence)
        if hideLimitedData {
            filtered = filtered.filter { bet in
                let conf = cachedEVResults[bet.id]?.confidence ?? .none
                return conf == .high || conf == .medium
            }
        }

        // League filter
        if let league = selectedLeague {
            filtered = filtered.filter { $0.league == league }
        }

        // Market filter
        if let market = selectedMarket {
            filtered = filtered.filter { $0.market == market }
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
            filtered = filtered.sorted { $0.commenceTime < $1.commenceTime }
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
        if let cached = cachedEVResults[bet.id] {
            return cached.isReliablyPositive
        }
        return false
    }

    /// Get confidence level for a bet
    func confidence(for bet: APIBet) -> FairOddsConfidence {
        cachedEVResults[bet.id]?.confidence ?? .none
    }

    /// Get full EV result for a bet (for UI display)
    func evResult(for bet: APIBet) -> EVResult? {
        cachedEVResults[bet.id]
    }

    /// Get cached best EV for a bet (fast lookup)
    func bestEV(for bet: APIBet) -> Double {
        if let cached = cachedEVResults[bet.id] {
            return cached.ev
        }
        return computeEVResult(for: bet).ev
    }

    /// Pre-compute all EV values once after data loads
    private func computeAllEVs() {
        cachedEVResults.removeAll()
        for bet in allBets {
            cachedEVResults[bet.id] = computeEVResult(for: bet)
        }
    }

    /// Calculate best EV for a single bet using cached pairs
    private func computeEVResult(for bet: APIBet) -> EVResult {
        let fairResult = bet.fairProbability(pairs: cachedPairs)
        let pFair = fairResult.fairProbability

        var best = -Double.greatestFiniteMagnitude
        for book in bet.books {
            let ev = EVCalculator.computeEV(
                americanOdds: book.price,
                marketProbability: pFair,
                bookKey: book.name.lowercased()
            )
            if ev > best {
                best = ev
            }
        }
        return EVResult(
            ev: best,
            confidence: fairResult.confidence,
            fairProbability: fairResult.fairProbability,
            fairAmericanOdds: fairResult.fairAmericanOdds
        )
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
