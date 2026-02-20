//
//  EVCalculator.swift
//  ScrollDown
//
//  EV Calculator — Takes fair probabilities and computes Expected Value per book.
//

import Foundation

// MARK: - EV Calculator

/// Calculator for Expected Value per book
struct EVCalculator {

    /// Compute EV for a single book
    /// EV = pFair * profit - (1 - pFair)
    static func computeBookEV(
        bookKey: String,
        americanOdds: Int,
        pFair: Double
    ) -> BookEVResult {
        let profit = americanToProfit(americanOdds)
        let ev = pFair * profit - (1 - pFair)
        let evPercent = ev * 100

        return BookEVResult(
            book: bookKey,
            americanOdds: americanOdds,
            ev: ev,
            evPercent: evPercent
        )
    }

    /// Convert American odds to profit per $1 stake
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

    /// Compute EV percentage for a single book given fair probability
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
    let ev: Double
    let evPercent: Double
}
