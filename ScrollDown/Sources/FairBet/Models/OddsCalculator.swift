//
//  OddsCalculator.swift
//  ScrollDown
//
//  Odds conversion and display utilities
//

import Foundation

/// Odds calculator for conversion and display formatting
struct OddsCalculator {

    // MARK: - Validation

    /// Validates that American odds are in valid range.
    /// Valid odds: <= -100 OR >= +100 (including exactly +100)
    /// Invalid: any value between -99 and +99
    static func isValidAmericanOdds(_ value: Int) -> Bool {
        // +100 is valid (even money)
        if value == 100 { return true }
        // Must be <= -100 or >= +100
        return value <= -100 || value >= 100
    }

    // MARK: - Core Conversion: American <-> Probability

    /// Convert American odds to implied probability.
    /// This is the canonical conversion.
    static func americanToProb(_ odds: Int) -> Double {
        if odds < 0 {
            // Favorite: -110 -> 110 / (110 + 100) = 0.5238
            return Double(-odds) / (Double(-odds) + 100.0)
        } else {
            // Underdog or even: +150 -> 100 / (150 + 100) = 0.40
            return 100.0 / (Double(odds) + 100.0)
        }
    }

    /// Convert probability to American odds.
    /// Ensures valid output (<=-100 or >=+100).
    static func probToAmerican(_ prob: Double) -> Int {
        guard prob > 0 && prob < 1 else {
            return 100 // Default to even money for invalid input
        }

        if prob >= 0.5 {
            // Favorite: prob 0.6 -> -150
            let odds = -Int(round((prob / (1.0 - prob)) * 100.0))
            // Ensure we don't return invalid odds
            return min(odds, -100)
        } else {
            // Underdog: prob 0.4 -> +150
            let odds = Int(round(((1.0 - prob) / prob) * 100.0))
            // Ensure we don't return invalid odds
            return max(odds, 100)
        }
    }

    /// Convert American odds struct to implied probability.
    static func impliedProbability(for odds: AmericanOdds) -> Double {
        americanToProb(odds.value)
    }

    // MARK: - Decimal Odds Conversion

    /// Convert American odds to decimal odds.
    static func decimalOdds(for odds: AmericanOdds) -> Double {
        guard odds.value != 0 else { return 0 }
        if odds.value > 0 {
            return (Double(odds.value) / 100.0) + 1.0
        }
        return (100.0 / Double(abs(odds.value))) + 1.0
    }

    /// Convert decimal odds to American odds.
    static func americanOdds(fromDecimal decimal: Double) -> AmericanOdds {
        guard decimal.isFinite, decimal > 1.0 else {
            return AmericanOdds(100)
        }

        // Convert via probability for consistency
        let prob = 1.0 / decimal
        let american = probToAmerican(prob)
        return AmericanOdds(american)
    }

    /// Convert probability to American odds struct.
    static func americanOdds(fromProbability probability: Double) -> AmericanOdds {
        let american = probToAmerican(probability)
        return AmericanOdds(american)
    }

    // MARK: - Display Formatting

    /// Format odds for display based on user's preferred format.
    static func formattedOdds(_ odds: AmericanOdds, format: OddsFormat) -> String {
        switch format {
        case .american:
            return odds.displayString
        case .decimal:
            return formattedDecimalOdds(decimalOdds(for: odds))
        }
    }

    /// Format decimal odds with 2 decimal places.
    static func formattedDecimalOdds(_ decimal: Double) -> String {
        String(format: "%.2f", decimal)
    }

    // MARK: - Profit Conversion

    /// Convert American odds to profit per $1 stake
    static func americanToProfit(_ odds: Int) -> Double {
        if odds > 0 { return Double(odds) / 100.0 }
        if odds < 0 { return 100.0 / Double(abs(odds)) }
        return 0
    }
}
