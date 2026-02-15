//
//  BetPairing.swift
//  ScrollDown
//
//  Pairs APIBet selections to enable advanced vig-removal calculations.
//  When both sides of a market are available, we can compute true fair odds.
//

import Foundation

// MARK: - Bet Pairing Service

/// Service that pairs APIBets and computes fair odds
struct BetPairingService {

    // MARK: - Fair Probability Result

    struct FairProbabilityResult {
        let fairProbability: Double
        let fairAmericanOdds: Int
        let confidence: FairOddsConfidence
        let vigRemoved: Double
        let method: CalculationMethod

        enum CalculationMethod: String {
            case pairedVigRemoval = "Paired vig removal"
            case medianConsensus = "Median consensus"
        }
    }

    // MARK: - Pairing Logic

    /// Generate a pairing key for matching opposite sides of a market
    static func pairingKey(for bet: APIBet) -> String {
        let lineKey = bet.lineValue.map { String(format: "%.1f", abs($0)) } ?? "nil"
        return "\(bet.league.rawValue)|\(bet.homeTeam)|\(bet.awayTeam)|\(bet.market.rawValue)|\(lineKey)"
    }

    /// Find the opposite selection name for a given bet
    static func oppositeSelection(for bet: APIBet) -> String? {
        switch bet.market {
        case .h2h:
            // Moneyline: home vs away
            if bet.selection == bet.homeTeam {
                return bet.awayTeam
            } else if bet.selection == bet.awayTeam {
                return bet.homeTeam
            }
            return nil

        case .spreads:
            // Spread: opposite team
            if bet.selection == bet.homeTeam {
                return bet.awayTeam
            } else if bet.selection == bet.awayTeam {
                return bet.homeTeam
            }
            return nil

        case .totals:
            // Totals: over vs under
            if bet.selection.lowercased() == "over" {
                return "Under"
            } else if bet.selection.lowercased() == "under" {
                return "Over"
            }
            return nil

        default:
            // Props, alternates, and unknown markets: no automatic pairing
            return nil
        }
    }

    /// Pair all bets and return a dictionary of bet ID to its pair
    static func pairBets(_ bets: [APIBet]) -> [String: APIBet] {
        var pairs: [String: APIBet] = [:]
        var betsByKey: [String: [APIBet]] = [:]

        // Group bets by pairing key
        for bet in bets {
            let key = pairingKey(for: bet)
            betsByKey[key, default: []].append(bet)
        }

        // Find pairs within each group
        for (_, groupBets) in betsByKey {
            guard groupBets.count >= 2 else { continue }

            for bet in groupBets {
                if let opposite = oppositeSelection(for: bet) {
                    if let pair = groupBets.first(where: { $0.selection == opposite && $0.id != bet.id }) {
                        pairs[bet.id] = pair
                    }
                }
            }
        }

        return pairs
    }

    // MARK: - Fair Probability Computation

    /// Compute fair probability for a bet using paired data when available
    static func computeFairProbability(
        for bet: APIBet,
        allBets: [APIBet]
    ) -> FairProbabilityResult {
        let pairs = pairBets(allBets)

        if let pairedBet = pairs[bet.id] {
            return computeWithVigRemoval(bet: bet, pairedBet: pairedBet)
        } else {
            return computeWithMedianConsensus(bet: bet)
        }
    }

    /// Compute fair probability using pre-computed pairs (much faster for bulk operations)
    static func computeFairProbability(
        for bet: APIBet,
        pairs: [String: APIBet]
    ) -> FairProbabilityResult {
        if let pairedBet = pairs[bet.id] {
            return computeWithVigRemoval(bet: bet, pairedBet: pairedBet)
        } else {
            return computeWithMedianConsensus(bet: bet)
        }
    }

    /// Compute fair probability with vig removal (requires both sides)
    private static func computeWithVigRemoval(
        bet: APIBet,
        pairedBet: APIBet
    ) -> FairProbabilityResult {
        let betBooks = Set(bet.books.map { $0.name })
        let pairedBooks = Set(pairedBet.books.map { $0.name })
        let commonBooks = betBooks.intersection(pairedBooks)

        guard !commonBooks.isEmpty else {
            return computeWithMedianConsensus(bet: bet)
        }

        var vigFreeProbs: [Double] = []
        var vigs: [Double] = []

        for bookName in commonBooks {
            guard let betPrice = bet.books.first(where: { $0.name == bookName }),
                  let pairedPrice = pairedBet.books.first(where: { $0.name == bookName }) else {
                continue
            }

            let betProb = OddsCalculator.americanToProb(betPrice.price)
            let pairedProb = OddsCalculator.americanToProb(pairedPrice.price)

            let totalImplied = betProb + pairedProb
            let vig = totalImplied - 1.0
            vigs.append(vig)

            let vigFreeProb = betProb / totalImplied
            vigFreeProbs.append(vigFreeProb)
        }

        guard !vigFreeProbs.isEmpty else {
            return computeWithMedianConsensus(bet: bet)
        }

        let fairProb = median(vigFreeProbs)
        let avgVig = vigs.reduce(0, +) / Double(vigs.count)
        let fairAmerican = OddsCalculator.probToAmerican(fairProb)

        let confidence: FairOddsConfidence
        if commonBooks.count >= 4 {
            confidence = .high
        } else if commonBooks.count >= 2 {
            confidence = .medium
        } else {
            confidence = .low
        }

        return FairProbabilityResult(
            fairProbability: fairProb,
            fairAmericanOdds: fairAmerican,
            confidence: confidence,
            vigRemoved: avgVig,
            method: .pairedVigRemoval
        )
    }

    /// Compute fair probability using median consensus (no vig removal)
    private static func computeWithMedianConsensus(bet: APIBet) -> FairProbabilityResult {
        let prices = bet.books.map { $0.price }

        guard let marketProb = EVCalculator.computeMarketProbability(from: prices) else {
            let firstProb = OddsCalculator.americanToProb(bet.books.first?.price ?? -110)
            return FairProbabilityResult(
                fairProbability: firstProb,
                fairAmericanOdds: OddsCalculator.probToAmerican(firstProb),
                confidence: .none,
                vigRemoved: 0,
                method: .medianConsensus
            )
        }

        let impliedProbs = prices.map { OddsCalculator.americanToProb($0) }
        let minProb = impliedProbs.min() ?? 0
        let maxProb = impliedProbs.max() ?? 1
        let probSpread = maxProb - minProb

        let confidence: FairOddsConfidence
        if bet.market == .spreads && probSpread > 0.15 {
            confidence = .none
        } else if probSpread > 0.20 {
            confidence = .none
        } else {
            confidence = .low
        }

        return FairProbabilityResult(
            fairProbability: marketProb,
            fairAmericanOdds: OddsCalculator.probToAmerican(marketProb),
            confidence: confidence,
            vigRemoved: 0,
            method: .medianConsensus
        )
    }

    /// Calculate median of an array
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

// MARK: - APIBet Extension for Fair Odds

extension APIBet {

    /// Compute fair probability using paired data when available
    func fairProbability(allBets: [APIBet]) -> BetPairingService.FairProbabilityResult {
        BetPairingService.computeFairProbability(for: self, allBets: allBets)
    }

    /// Compute fair probability using pre-computed pairs (faster for bulk operations)
    func fairProbability(pairs: [String: APIBet]) -> BetPairingService.FairProbabilityResult {
        BetPairingService.computeFairProbability(for: self, pairs: pairs)
    }
}
