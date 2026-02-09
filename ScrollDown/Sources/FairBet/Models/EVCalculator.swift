//
//  EVCalculator.swift
//  ScrollDown
//
//  EV & Fee Model - Book Comparison Layer
//  Takes fair probabilities and computes Expected Value per book.
//  This is the comparison layer, not the brain.
//

import Foundation

// MARK: - Fee Configuration

/// Fee type for a book
enum BookFeeType: String, Codable {
    case none                   // Traditional sportsbook - no explicit fee
    case percentOnWinnings      // P2P/Exchange - fee on net profit
}

/// Fee configuration for a book
struct BookFeeConfig: Codable, Equatable {
    let feeType: BookFeeType
    let rate: Double  // Fee rate (e.g., 0.02 = 2%)

    static let none = BookFeeConfig(feeType: .none, rate: 0)

    /// Apply fee to gross profit, returning net profit
    func applyFee(to grossProfit: Double) -> Double {
        switch feeType {
        case .none:
            return grossProfit
        case .percentOnWinnings:
            return grossProfit * (1 - rate)
        }
    }
}

/// Static fee configuration by book category
struct FeeConfiguration {

    /// Book fee profiles
    static let bookFees: [String: BookFeeConfig] = [
        "draftkings": .none,
        "fanduel": .none,
        "betmgm": .none,
        "caesars": .none,
        "pointsbet": .none,
        "bet365": .none,
        "pinnacle": .none,
        "circa": .none,
        "betcris": .none,
        "betrivers": .none,
        "unibet": .none,
        "wynnbet": .none,
        "superbook": .none,

        // P2P platforms - 2% fee on winnings
        "novig": BookFeeConfig(feeType: .percentOnWinnings, rate: 0.02),
        "prophetx": BookFeeConfig(feeType: .percentOnWinnings, rate: 0.02),

        // Exchanges - 1% fee on winnings
        "betfair": BookFeeConfig(feeType: .percentOnWinnings, rate: 0.01),
        "smarkets": BookFeeConfig(feeType: .percentOnWinnings, rate: 0.01)
    ]

    /// Get fee config for a book, defaulting to no fee
    static func feeConfig(for bookKey: String) -> BookFeeConfig {
        bookFees[bookKey.lowercased()] ?? .none
    }
}

// MARK: - EV Result per Book

/// EV calculation result for a single book
struct BookEVResult: Codable, Equatable, Identifiable {
    let book: String
    let americanOdds: Int
    let grossProfit: Double      // Profit per $1 before fees
    let netProfit: Double        // Profit per $1 after fees
    let ev: Double               // EV in dollars per $1 staked
    let evPercent: Double        // EV as percentage
    let feeApplied: Bool         // Whether fees were deducted
    let feeRate: Double          // Fee rate applied (0 if none)

    var id: String { book }

    /// Check if this book has positive EV
    var hasPositiveEV: Bool { ev > 0 }

    /// Display string for EV percent
    var evPercentDisplay: String {
        let sign = evPercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", evPercent))%"
    }
}

// MARK: - Selection EV Result

/// Complete EV analysis for a selection
struct SelectionEVResult: Codable, Equatable, Identifiable {
    let betGroupKey: String
    let selectionKey: String
    let fairAvailable: Bool
    let fairAmerican: Int?
    let pFair: Double?
    let books: [BookEVResult]
    let bestByEV: String?        // Book key with highest EV
    let bestByPrice: String?     // Book key with best raw price

    var id: String { selectionKey }

    /// Get EV result for a specific book
    func evResult(for bookKey: String) -> BookEVResult? {
        books.first { $0.book.lowercased() == bookKey.lowercased() }
    }

    /// Get all books with positive EV, sorted by EV descending
    var positiveEVBooks: [BookEVResult] {
        books.filter { $0.hasPositiveEV }.sorted { $0.evPercent > $1.evPercent }
    }
}

// MARK: - EV Calculator

/// Calculator for Expected Value per book
struct EVCalculator {

    // MARK: - Core Computation

    /// Compute EV for all books on a selection
    static func computeEV(
        for selection: Selection,
        fairResult: FairOddsResult?
    ) -> SelectionEVResult {

        let fairAvailable = fairResult != nil
        let pFair = fairResult?.fairProbability
        let fairAmerican = fairResult?.fairAmericanOdds

        guard let pFair = pFair, fairAvailable else {
            return SelectionEVResult(
                betGroupKey: selection.betGroupKey,
                selectionKey: selection.selectionKey,
                fairAvailable: false,
                fairAmerican: nil,
                pFair: nil,
                books: buildBooksWithoutEV(selection: selection),
                bestByEV: nil,
                bestByPrice: findBestByPrice(selection: selection)
            )
        }

        var bookResults: [BookEVResult] = []

        for price in selection.prices {
            let result = computeBookEV(
                bookKey: price.bookKey,
                americanOdds: price.price,
                pFair: pFair
            )
            bookResults.append(result)
        }

        let bestByEV = findBestByEV(books: bookResults)
        let bestByPrice = findBestByPrice(books: bookResults)

        return SelectionEVResult(
            betGroupKey: selection.betGroupKey,
            selectionKey: selection.selectionKey,
            fairAvailable: true,
            fairAmerican: fairAmerican,
            pFair: pFair,
            books: bookResults,
            bestByEV: bestByEV,
            bestByPrice: bestByPrice
        )
    }

    /// Compute EV for a single book
    static func computeBookEV(
        bookKey: String,
        americanOdds: Int,
        pFair: Double
    ) -> BookEVResult {

        let grossProfit = americanToProfit(americanOdds)

        let feeConfig = FeeConfiguration.feeConfig(for: bookKey)
        let netProfit = feeConfig.applyFee(to: grossProfit)
        let feeApplied = feeConfig.feeType != .none

        // EV = p_fair * profit_net - (1 - p_fair)
        let ev = pFair * netProfit - (1 - pFair)
        let evPercent = ev * 100

        return BookEVResult(
            book: bookKey,
            americanOdds: americanOdds,
            grossProfit: grossProfit,
            netProfit: netProfit,
            ev: ev,
            evPercent: evPercent,
            feeApplied: feeApplied,
            feeRate: feeConfig.rate
        )
    }

    // MARK: - Odds to Profit Conversion

    /// Convert American odds to net profit per $1 stake
    static func americanToProfit(_ odds: Int) -> Double {
        if odds > 0 {
            return Double(odds) / 100.0
        } else if odds < 0 {
            return 100.0 / Double(abs(odds))
        }
        return 0
    }

    // MARK: - Best Book Identification

    private static func findBestByEV(books: [BookEVResult]) -> String? {
        let positiveEV = books.filter { $0.ev > 0 }
        return positiveEV.max { $0.ev < $1.ev }?.book
    }

    private static func findBestByPrice(books: [BookEVResult]) -> String? {
        books.max { $0.grossProfit < $1.grossProfit }?.book
    }

    private static func findBestByPrice(selection: Selection) -> String? {
        selection.prices.max { americanToProfit($0.price) < americanToProfit($1.price) }?.bookKey
    }

    private static func buildBooksWithoutEV(selection: Selection) -> [BookEVResult] {
        selection.prices.map { price in
            let grossProfit = americanToProfit(price.price)
            let feeConfig = FeeConfiguration.feeConfig(for: price.bookKey)
            let netProfit = feeConfig.applyFee(to: grossProfit)

            return BookEVResult(
                book: price.bookKey,
                americanOdds: price.price,
                grossProfit: grossProfit,
                netProfit: netProfit,
                ev: 0,
                evPercent: 0,
                feeApplied: feeConfig.feeType != .none,
                feeRate: feeConfig.rate
            )
        }
    }
}

// MARK: - Bet Group EV Extension

struct BetGroupEVResult: Codable, Equatable, Identifiable {
    let betGroupKey: String
    let selections: [SelectionEVResult]
    let fairAvailable: Bool
    let timestamp: Date

    var id: String { betGroupKey }

    func evResult(for side: SelectionSide) -> SelectionEVResult? {
        selections.first { $0.selectionKey.hasSuffix(":\(side.rawValue)") }
    }
}

extension BetGroup {

    /// Compute EV for all selections in this bet group
    var evAnalysis: BetGroupEVResult {
        let fairOddsResult = self.fairOdds

        var selectionResults: [SelectionEVResult] = []

        for selection in selections {
            let fairResult = fairOddsResult?.selections.first {
                $0.selectionKey == selection.selectionKey
            }

            let evResult = EVCalculator.computeEV(
                for: selection,
                fairResult: fairResult
            )
            selectionResults.append(evResult)
        }

        return BetGroupEVResult(
            betGroupKey: betGroupKey,
            selections: selectionResults,
            fairAvailable: fairOddsResult != nil,
            timestamp: Date()
        )
    }

    /// Get the best book by EV for a specific side
    func bestBookByEV(for side: SelectionSide) -> (book: String, evPercent: Double)? {
        guard let evResult = evAnalysis.evResult(for: side),
              let bestBook = evResult.bestByEV,
              let bookResult = evResult.evResult(for: bestBook) else {
            return nil
        }
        return (book: bestBook, evPercent: bookResult.evPercent)
    }

    /// Get all positive EV opportunities in this bet group
    var positiveEVOpportunities: [(selection: Selection, book: BookEVResult)] {
        var results: [(Selection, BookEVResult)] = []

        let analysis = evAnalysis

        for selection in selections {
            if let evResult = analysis.selections.first(where: { $0.selectionKey == selection.selectionKey }) {
                for bookResult in evResult.positiveEVBooks {
                    results.append((selection, bookResult))
                }
            }
        }

        return results.sorted { $0.1.evPercent > $1.1.evPercent }
    }
}

// MARK: - APIBet Convenience Methods

extension EVCalculator {

    /// Compute market probability from an array of American odds prices
    static func computeMarketProbability(from prices: [Int]) -> Double? {
        guard !prices.isEmpty else { return nil }

        let impliedProbs = prices.map { OddsCalculator.americanToProb($0) }
        return median(impliedProbs)
    }

    /// Compute EV for a single book given market probability
    static func computeEV(
        americanOdds: Int,
        marketProbability: Double,
        bookKey: String
    ) -> Double {
        let result = computeBookEV(
            bookKey: bookKey,
            americanOdds: americanOdds,
            pFair: marketProbability
        )
        return result.evPercent
    }

    /// Calculate median of an array of Doubles
    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count

        if count == 0 { return 0 }
        if count == 1 { return sorted[0] }

        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        }
        return sorted[count/2]
    }
}
