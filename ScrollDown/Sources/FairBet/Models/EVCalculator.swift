//
//  EVCalculator.swift
//  ScrollDown
//
//  EV & Fee Model - Book Comparison Layer
//  Takes fair probabilities and computes Expected Value per book.
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

// MARK: - EV Calculator

/// Calculator for Expected Value per book
struct EVCalculator {

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

    /// Convert American odds to net profit per $1 stake
    static func americanToProfit(_ odds: Int) -> Double {
        if odds > 0 {
            return Double(odds) / 100.0
        } else if odds < 0 {
            return 100.0 / Double(abs(odds))
        }
        return 0
    }

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

// MARK: - Book EV Result

/// EV calculation result for a single book
struct BookEVResult: Codable, Equatable {
    let book: String
    let americanOdds: Int
    let grossProfit: Double
    let netProfit: Double
    let ev: Double
    let evPercent: Double
    let feeApplied: Bool
    let feeRate: Double
}
