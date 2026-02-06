//
//  FairBetCopy.swift
//  ScrollDown
//
//  UI Semantics, Copy & Trust Signals
//  Centralized copy system ensuring consistent, honest, non-misleading language.
//
//  Core principle: FairBet estimates what a bet is worth based on current market prices —
//  it does not predict what will happen.
//

import Foundation

// MARK: - FairBet Copy System

/// Centralized copy for all UI text in FairBet
enum FairBetCopy {

    // MARK: - Brand & Core Concepts

    static let appName = "FairBet"
    static let tagline = "Compare prices across sportsbooks"
    static let whatIsFairBet = "FairBet helps you compare odds across sportsbooks."

    // MARK: - Fair Odds Labels

    static let fairEstimateLabel = "FairBet Estimate"
    static let fairEstimateShort = "Fair"
    static let fairEstimateExplanation = "Estimated from select books' current prices."
    static let fairEstimateDetail = "FairBet uses current prices from select books to estimate a fair baseline."

    // MARK: - EV Labels

    static let evLabel = "EV vs FairBet"
    static let evLabelShort = "EV"
    static let evExplanation = "Compares this price to FairBet's estimated fair odds."
    static let positiveEVMeaning = "Better than estimate"
    static let negativeEVMeaning = "Worse than estimate"

    // MARK: - Confidence Indicators

    static let confidenceLow = "Limited data"
    static let confidenceUnavailable = "Estimate unavailable"

    // MARK: - Empty / Unavailable States

    static let fairUnavailable = "Fair estimate unavailable for this bet."
    static let fairUnavailableSecondary = "Prices shown for comparison only."
    static let noBooksEnabled = "Enable sportsbooks to see prices."
    static let noResults = "No bets match your filters."
    static let loading = "Loading..."
    static let refreshing = "Updating prices..."

    // MARK: - Best Offer Labels

    static let bestOfferLabel = "Best Price"
    static let bestEVLabel = "Best EV"
    static let bestIndicator = "Best"

    // MARK: - Section Headers

    static let allBooksHeader = "All Sportsbooks"
    static let comparisonHeader = "Price Comparison"

    // MARK: - Timestamps

    static let updatedPrefix = "Updated"

    static func updatedAt(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "\(updatedPrefix) \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    // MARK: - Disclaimers

    static let disclaimer = "FairBet provides estimates for comparison purposes only."
    static let fullDisclaimer = "FairBet estimates are based on current market prices and are for comparison purposes only. Past performance does not guarantee future results."

    // MARK: - Accessibility Labels

    static func fairOddsAccessibility(odds: String) -> String {
        "FairBet estimate: \(odds)"
    }

    static func evAccessibility(percent: String, isPositive: Bool) -> String {
        let comparison = isPositive ? "better than" : "worse than"
        return "Expected value \(percent), \(comparison) FairBet estimate"
    }

    static func bookPriceAccessibility(book: String, odds: String, isBest: Bool) -> String {
        var label = "\(book): \(odds)"
        if isBest { label += ", best price" }
        return label
    }

    // MARK: - Formatting

    static func formatEV(_ percent: Double) -> String {
        let sign = percent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", percent))%"
    }

    static func formatOdds(_ odds: Int) -> String {
        odds > 0 ? "+\(odds)" : "\(odds)"
    }

    static func formatProbability(_ prob: Double) -> String {
        String(format: "%.1f%%", prob * 100)
    }

    // MARK: - Market Labels

    static func marketLabel(for marketKey: String) -> String {
        switch marketKey.lowercased() {
        case "h2h": return "Moneyline"
        case "spread", "spreads": return "Spread"
        case "total", "totals": return "Total"
        case "player_points": return "Points"
        case "player_rebounds": return "Rebounds"
        case "player_assists": return "Assists"
        case "player_threes": return "3-Pointers"
        default:
            return marketKey.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: - League Labels

    static func leagueLabel(for league: String) -> String {
        league.uppercased()
    }

    static func leagueFullName(for league: String) -> String {
        switch league.uppercased() {
        case "NBA": return "NBA Basketball"
        case "NHL": return "NHL Hockey"
        case "NCAAB": return "College Basketball"
        case "NFL": return "NFL Football"
        case "MLB": return "MLB Baseball"
        default: return league.uppercased()
        }
    }

    // MARK: - Color Semantics

    static func colorSemantic(evPercent: Double?, isBest: Bool) -> FairBetColorSemantic {
        guard let ev = evPercent else { return .neutral }
        if isBest && ev > 0 { return .bestRelativeValue }
        if ev < -2 { return .worseRelativeValue }
        return .neutral
    }

    static func shouldHighlightEV(_ percent: Double, isBest: Bool) -> Bool {
        isBest && percent > 0
    }
}

// MARK: - Color Semantics Enum

enum FairBetColorSemantic {
    case bestRelativeValue
    case neutral
    case worseRelativeValue

    var meaning: String {
        switch self {
        case .bestRelativeValue: return "Better priced"
        case .neutral: return "Neutral"
        case .worseRelativeValue: return "Worse priced"
        }
    }
}

// MARK: - Debug Validation

#if DEBUG
extension FairBetCopy {
    static let forbiddenTerms = [
        "true odds", "correct odds", "guaranteed", "best bet",
        "prediction", "lock", "sharp pick", "you should bet",
        "will win", "will happen"
    ]

    static func containsForbiddenTerms(_ text: String) -> [String] {
        let lowercased = text.lowercased()
        return forbiddenTerms.filter { lowercased.contains($0) }
    }

    static func validateCopy(_ text: String) -> Bool {
        containsForbiddenTerms(text).isEmpty
    }
}
#endif
