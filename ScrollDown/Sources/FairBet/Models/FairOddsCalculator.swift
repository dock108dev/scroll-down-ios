//
//  FairOddsCalculator.swift
//  ScrollDown
//
//  Fair odds computation using sharp book vig-removal and median aggregation.
//

import Foundation

// MARK: - Sharp Book Configuration

/// Configuration for sharp (market-making) sportsbooks by sport and market
struct SharpBookConfig {

    /// Sharp books used for baseline fair odds calculation by sport
    static let sharpBooksBySport: [String: [String]] = [
        "nba": ["pinnacle", "circa", "betcris"],
        "nhl": ["pinnacle", "circa", "betcris"],
        "ncaab": ["pinnacle", "circa"],
        "nfl": ["pinnacle", "circa", "betcris"],
        "mlb": ["pinnacle", "circa", "betcris"],
        "default": ["pinnacle", "circa"]
    ]

    /// Get sharp books for a given sport
    static func sharpBooks(for sport: String) -> [String] {
        sharpBooksBySport[sport.lowercased()] ?? sharpBooksBySport["default"] ?? ["pinnacle", "circa"]
    }

    /// Check if a book is considered sharp for a given sport
    static func isSharp(_ bookKey: String, sport: String) -> Bool {
        sharpBooks(for: sport).contains(bookKey.lowercased())
    }

    /// Minimum number of sharp books required for high confidence
    static let minSharpBooksForHighConfidence = 2

    /// Minimum number of sharp books required for medium confidence
    static let minSharpBooksForMediumConfidence = 1
}

// MARK: - Fair Odds Result

/// Confidence level for fair odds computation
enum FairOddsConfidence: String, Codable {
    case high       // 2+ sharp books pricing both sides
    case medium     // 1 sharp book pricing both sides
    case low        // No sharp books available
    case none       // Cannot compute fair odds
}

/// Result of fair odds calculation for a selection
struct FairOddsResult: Codable, Equatable {
    let selectionKey: String
    let fairProbability: Double
    let fairAmericanOdds: Int
    let confidence: FairOddsConfidence
    let sharpBooksUsed: [String]
    let vigRemoved: Double  // Total vig removed from market

    /// Format fair odds for display
    var displayOdds: String {
        fairAmericanOdds > 0 ? "+\(fairAmericanOdds)" : "\(fairAmericanOdds)"
    }
}

/// Result for an entire bet group (both sides)
struct BetGroupFairOdds: Codable, Equatable {
    let betGroupKey: String
    let selections: [FairOddsResult]
    let marketVig: Double  // Vig in the sharp market
    let confidence: FairOddsConfidence
    let timestamp: Date

    /// Get fair odds for a specific side
    func fairOdds(for side: SelectionSide) -> FairOddsResult? {
        selections.first { $0.selectionKey.hasSuffix(":\(side.rawValue)") }
    }
}

// MARK: - Fair Odds Calculator

/// Calculator for deriving fair (vig-free) odds from sharp book prices
struct FairOddsCalculator {

    // MARK: - Main Computation

    /// Compute fair odds for a bet group using sharp book median aggregation
    static func computeFairOdds(for betGroup: BetGroup) -> BetGroupFairOdds? {
        guard betGroup.pairingStatus == .paired,
              betGroup.selections.count >= 2 else {
            return nil
        }

        let sport = betGroup.league ?? "default"
        let sharpBooks = SharpBookConfig.sharpBooks(for: sport)

        let validSharpBooks = findValidSharpBooks(
            betGroup: betGroup,
            sharpBooks: sharpBooks
        )

        guard !validSharpBooks.isEmpty else {
            return nil
        }

        var vigFreeProbsByBook: [(bookKey: String, probs: [SelectionSide: Double], vig: Double)] = []

        for bookKey in validSharpBooks {
            if let result = computeVigFreeProbabilities(
                betGroup: betGroup,
                bookKey: bookKey
            ) {
                vigFreeProbsByBook.append(result)
            }
        }

        guard !vigFreeProbsByBook.isEmpty else {
            return nil
        }

        let aggregatedProbs = aggregateMedian(probsByBook: vigFreeProbsByBook)
        let avgVig = vigFreeProbsByBook.map { $0.vig }.reduce(0, +) / Double(vigFreeProbsByBook.count)

        var selectionResults: [FairOddsResult] = []
        let booksUsed = vigFreeProbsByBook.map { $0.bookKey }

        for selection in betGroup.selections {
            guard let fairProb = aggregatedProbs[selection.side] else { continue }

            let fairAmerican = OddsCalculator.probToAmerican(fairProb)

            let result = FairOddsResult(
                selectionKey: selection.selectionKey,
                fairProbability: fairProb,
                fairAmericanOdds: fairAmerican,
                confidence: determineConfidence(sharpBookCount: booksUsed.count),
                sharpBooksUsed: booksUsed,
                vigRemoved: avgVig
            )
            selectionResults.append(result)
        }

        let confidence = determineConfidence(sharpBookCount: booksUsed.count)

        return BetGroupFairOdds(
            betGroupKey: betGroup.betGroupKey,
            selections: selectionResults,
            marketVig: avgVig,
            confidence: confidence,
            timestamp: Date()
        )
    }

    // MARK: - Vig Removal

    private static func computeVigFreeProbabilities(
        betGroup: BetGroup,
        bookKey: String
    ) -> (bookKey: String, probs: [SelectionSide: Double], vig: Double)? {

        var impliedProbs: [SelectionSide: Double] = [:]

        for selection in betGroup.selections {
            guard let price = selection.price(for: bookKey) else {
                return nil
            }
            let prob = OddsCalculator.americanToProb(price.price)
            impliedProbs[selection.side] = prob
        }

        let totalImplied = impliedProbs.values.reduce(0, +)
        let vig = totalImplied - 1.0

        var vigFreeProbs: [SelectionSide: Double] = [:]
        for (side, prob) in impliedProbs {
            vigFreeProbs[side] = prob / totalImplied
        }

        return (bookKey: bookKey, probs: vigFreeProbs, vig: vig)
    }

    // MARK: - Aggregation

    private static func aggregateMedian(
        probsByBook: [(bookKey: String, probs: [SelectionSide: Double], vig: Double)]
    ) -> [SelectionSide: Double] {

        var allSides = Set<SelectionSide>()
        for (_, probs, _) in probsByBook {
            allSides.formUnion(probs.keys)
        }

        var medianProbs: [SelectionSide: Double] = [:]

        for side in allSides {
            var values: [Double] = []
            for (_, probs, _) in probsByBook {
                if let prob = probs[side] {
                    values.append(prob)
                }
            }

            if !values.isEmpty {
                medianProbs[side] = median(values)
            }
        }

        let total = medianProbs.values.reduce(0, +)
        if total > 0 && abs(total - 1.0) > 0.001 {
            medianProbs = medianProbs.mapValues { $0 / total }
        }

        return medianProbs
    }

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

    // MARK: - Helper Functions

    private static func findValidSharpBooks(
        betGroup: BetGroup,
        sharpBooks: [String]
    ) -> [String] {
        let booksPricingBothSides = betGroup.booksPricingBothSides

        return sharpBooks.filter { sharpBook in
            booksPricingBothSides.contains { $0.lowercased() == sharpBook.lowercased() }
        }
    }

    private static func determineConfidence(sharpBookCount: Int) -> FairOddsConfidence {
        if sharpBookCount >= SharpBookConfig.minSharpBooksForHighConfidence {
            return .high
        } else if sharpBookCount >= SharpBookConfig.minSharpBooksForMediumConfidence {
            return .medium
        }
        return .low
    }

    // MARK: - Edge Calculation

    /// Calculate the edge (expected value advantage) for a selection
    static func calculateEdge(
        bookPrice: Int,
        fairProbability: Double
    ) -> Double {
        let bookImpliedProb = OddsCalculator.americanToProb(bookPrice)
        return fairProbability - bookImpliedProb
    }

    /// Calculate expected value percentage
    static func calculateEVPercent(
        bookPrice: Int,
        fairProbability: Double
    ) -> Double {
        let bookImpliedProb = OddsCalculator.americanToProb(bookPrice)
        guard bookImpliedProb > 0 else { return 0 }
        return ((fairProbability / bookImpliedProb) - 1.0) * 100.0
    }

    /// Check if a book price has positive expected value
    static func hasPositiveEV(
        bookPrice: Int,
        fairProbability: Double
    ) -> Bool {
        calculateEdge(bookPrice: bookPrice, fairProbability: fairProbability) > 0
    }
}

// MARK: - BetGroup Extension for Fair Odds

extension BetGroup {

    /// Compute fair odds for this bet group
    var fairOdds: BetGroupFairOdds? {
        FairOddsCalculator.computeFairOdds(for: self)
    }

    /// Get the best book price and its edge for a selection
    func bestPriceWithEdge(for side: SelectionSide) -> (price: GroupBookPrice, edge: Double, evPercent: Double)? {
        guard let selection = selection(for: side),
              let bestPrice = selection.bestPrice,
              let fairOdds = self.fairOdds,
              let fairResult = fairOdds.fairOdds(for: side) else {
            return nil
        }

        let edge = FairOddsCalculator.calculateEdge(
            bookPrice: bestPrice.price,
            fairProbability: fairResult.fairProbability
        )

        let evPercent = FairOddsCalculator.calculateEVPercent(
            bookPrice: bestPrice.price,
            fairProbability: fairResult.fairProbability
        )

        return (price: bestPrice, edge: edge, evPercent: evPercent)
    }
}
