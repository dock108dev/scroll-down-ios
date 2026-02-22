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

    // MARK: - Cached Computations (for performance)

    /// Cached EV results per bet ID (EV value + confidence)
    private var cachedEVResults: [String: EVResult] = [:]

    /// Result of EV calculation including confidence level and fair probability
    struct EVResult {
        let ev: Double
        let confidence: FairOddsConfidence
        let fairProbability: Double
        let fairAmericanOdds: Int
        var referencePrice: Int? = nil
        var evDisabledReason: String? = nil

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

    // MARK: - Parlay Computed Properties

    var parlayCount: Int { parlayBetIDs.count }

    /// Resolved from allBets so filter changes don't lose selections
    var parlayBets: [APIBet] {
        allBets.filter { parlayBetIDs.contains($0.id) }
    }

    var canShowParlay: Bool { parlayCount >= 2 }

    var parlayFairProbability: Double {
        let bets = parlayBets
        guard !bets.isEmpty else { return 0 }
        return bets.reduce(1.0) { result, bet in
            let prob = cachedEVResults[bet.id]?.fairProbability ?? 0.5
            return result * prob
        }
    }

    var parlayFairAmericanOdds: Int {
        let prob = parlayFairProbability
        guard prob > 0 && prob < 1 else { return 100 }
        return OddsCalculator.probToAmerican(prob)
    }

    var parlayConfidence: FairOddsConfidence {
        let confidences = parlayBets.compactMap { cachedEVResults[$0.id]?.confidence }
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

            // Compute and display first page results immediately
            computeAllEVs()
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
                    let insertionIndex = allBets.count
                    allBets.append(contentsOf: remainingBets)
                    computeEVsForNewBets(startingAt: insertionIndex)
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
    }

    func isInParlay(_ bet: APIBet) -> Bool {
        parlayBetIDs.contains(bet.id)
    }

    func clearParlay() {
        parlayBetIDs.removeAll()
    }

    /// Load mock data for previews
    func loadMockData() {
        let response = FairBetMockDataProvider.shared.getMockBetsResponse()
        allBets = response.bets
        booksAvailable = response.booksAvailable
        computeAllEVs()
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

    /// Compute EVs only for newly appended bets (avoids recomputing the entire cache)
    private func computeEVsForNewBets(startingAt index: Int) {
        guard index < allBets.count else { return }
        for i in index..<allBets.count {
            let bet = allBets[i]
            cachedEVResults[bet.id] = computeEVResult(for: bet)
        }
    }

    /// Calculate best EV for a single bet using server-side annotations exclusively.
    private func computeEVResult(for bet: APIBet) -> EVResult {
        // Use server-side EV annotations exclusively
        guard let serverTier = bet.evConfidenceTier,
              let bestServerBook = bet.books
                  .compactMap({ b -> (book: BookPrice, ev: Double)? in
                      guard let ev = b.evPercent else { return nil }
                      return (b, ev)
                  }).max(by: { $0.ev < $1.ev }),
              let fairProb = bet.trueProb
        else {
            // Server didn't provide EV — return "not available"
            return EVResult(
                ev: 0,
                confidence: .none,
                fairProbability: 0,
                fairAmericanOdds: 0,
                referencePrice: bet.referencePrice,
                evDisabledReason: bet.evDisabledReason ?? "Server EV not available"
            )
        }

        let confidence: FairOddsConfidence
        switch serverTier {
        case "high": confidence = .high
        case "medium": confidence = .medium
        case "low": confidence = .low
        default: confidence = .none
        }

        return EVResult(
            ev: bestServerBook.ev,
            confidence: confidence,
            fairProbability: fairProb,
            fairAmericanOdds: OddsCalculator.probToAmerican(fairProb),
            referencePrice: bet.referencePrice,
            evDisabledReason: bet.evDisabledReason
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
