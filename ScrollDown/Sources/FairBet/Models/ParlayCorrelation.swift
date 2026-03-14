//
//  ParlayCorrelation.swift
//  ScrollDown
//
//  Correlation detection for parlay legs.
//  Warns when legs share the same game (SGP) or have opposing sides.
//

import Foundation

enum ParlayCorrelation {
    /// Check if any two legs are from the same game (same-game parlay)
    static func hasCorrelatedLegs(_ bets: [APIBet]) -> Bool {
        var seen = Set<Int>()
        for bet in bets {
            if seen.contains(bet.gameId) { return true }
            seen.insert(bet.gameId)
        }
        return false
    }

    /// Check if any two legs have opposing sides in the same market
    static func hasOpposingSides(_ bets: [APIBet]) -> Bool {
        for i in 0..<bets.count {
            for j in (i + 1)..<bets.count {
                if bets[i].gameId == bets[j].gameId &&
                   bets[i].marketKey == bets[j].marketKey &&
                   bets[i].selectionKey != bets[j].selectionKey {
                    return true
                }
            }
        }
        return false
    }

    /// Generate warning messages for a set of parlay legs
    static func warnings(for bets: [APIBet]) -> [String] {
        var warnings: [String] = []

        if hasOpposingSides(bets) {
            warnings.append("Opposing sides detected — legs cancel each other out.")
        } else if hasCorrelatedLegs(bets) {
            warnings.append("Same-game legs detected — outcomes may be correlated.")
        }

        if bets.count >= 4 {
            warnings.append("Large parlays are harder to estimate accurately.")
        }

        return warnings
    }

    /// Confidence tier considering correlation
    static func confidenceTier(bets: [APIBet], allProbsValid: Bool) -> String {
        if !allProbsValid { return "none" }
        if hasCorrelatedLegs(bets) { return "low" }
        if bets.count >= 4 { return "low" }
        return "medium"
    }
}
