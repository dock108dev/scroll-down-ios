//
//  BetGroup.swift
//  ScrollDown
//
//  Bet grouping and pairing models per the FairBet specification.
//  A BetGroup is the atomic unit representing a single wagering proposition,
//  independent of any sportsbook.
//

import Foundation

// MARK: - Selection Side

/// The side of a selection within a bet group
enum SelectionSide: String, Codable, CaseIterable {
    case home
    case away
    case over
    case under
    case draw

    /// Returns the paired/opposite side, if one exists
    var pairedSide: SelectionSide? {
        switch self {
        case .home: return .away
        case .away: return .home
        case .over: return .under
        case .under: return .over
        case .draw: return nil  // 3-way markets: draw has no direct pair
        }
    }
}

// MARK: - Pairing Status

/// Status indicating whether a bet group has valid paired selections
enum PairingStatus: String, Codable {
    case paired      // Both sides priced by at least one book
    case oneSided    // Only one side has prices
    case unpaired    // Sides exist but no book prices both
}

// MARK: - Book Price

/// A price from a specific sportsbook
struct GroupBookPrice: Identifiable, Codable, Equatable {
    let bookKey: String
    let price: Int  // American odds
    let observedAt: Date

    var id: String { bookKey }

    /// Convert to AmericanOdds struct
    var americanOdds: AmericanOdds {
        AmericanOdds(price)
    }
}

// MARK: - Selection

/// A specific outcome within a BetGroup that a user can wager on
struct Selection: Identifiable, Codable, Equatable {
    let selectionKey: String
    let betGroupKey: String
    let side: SelectionSide
    let label: String
    let teamId: String?
    var prices: [GroupBookPrice]

    var id: String { selectionKey }

    /// Check if this selection has any prices
    var hasPrices: Bool {
        !prices.isEmpty
    }

    /// Get price from a specific book
    func price(for bookKey: String) -> GroupBookPrice? {
        prices.first { $0.bookKey == bookKey }
    }

    /// Get the best price (highest American odds = best for bettor)
    var bestPrice: GroupBookPrice? {
        prices.max { OddsCalculator.decimalOdds(for: $0.americanOdds) < OddsCalculator.decimalOdds(for: $1.americanOdds) }
    }

    /// Books that have priced this selection
    var bookKeys: Set<String> {
        Set(prices.map { $0.bookKey })
    }
}

// MARK: - Bet Group

/// The atomic unit representing a single wagering proposition, independent of sportsbooks.
/// Books only supply prices for a bet group; they do not define it.
struct BetGroup: Identifiable, Codable, Equatable {
    let betGroupKey: String
    let gameId: String
    let marketKey: String
    let subjectId: String?
    let line: Double?
    var pairingStatus: PairingStatus
    var selections: [Selection]

    var id: String { betGroupKey }

    // MARK: - Computed Properties

    /// Get selection by side
    func selection(for side: SelectionSide) -> Selection? {
        selections.first { $0.side == side }
    }

    /// Get the paired selection for a given selection
    func pairedSelection(for selection: Selection) -> Selection? {
        guard let pairedSide = selection.side.pairedSide else { return nil }
        return self.selection(for: pairedSide)
    }

    /// All unique books that have priced any selection in this group
    var allBookKeys: Set<String> {
        var books = Set<String>()
        for selection in selections {
            books.formUnion(selection.bookKeys)
        }
        return books
    }

    /// Books that have priced both sides (required for vig removal)
    var booksPricingBothSides: Set<String> {
        guard selections.count >= 2 else { return [] }

        // Start with books from first selection
        var commonBooks = selections[0].bookKeys

        // Intersect with books from other selections
        for selection in selections.dropFirst() {
            commonBooks.formIntersection(selection.bookKeys)
        }

        return commonBooks
    }

    /// Check if fair odds can be computed (requires paired selections with prices)
    var canComputeFairOdds: Bool {
        pairingStatus == .paired && !booksPricingBothSides.isEmpty
    }

    // MARK: - Display Helpers

    /// Human-readable market type
    var marketDisplayName: String {
        switch marketKey {
        case "h2h": return "Moneyline"
        case "spread": return "Spread"
        case "total": return "Total"
        case "player_points": return "Points"
        case "player_rebounds": return "Rebounds"
        case "player_assists": return "Assists"
        default: return marketKey.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Extract league from game_id (e.g., "nba" from "nba:2024-01-31:BOS-LAL")
    var league: String? {
        gameId.components(separatedBy: ":").first
    }

    /// Extract teams from game_id
    var teams: (away: String, home: String)? {
        let parts = gameId.components(separatedBy: ":")
        guard parts.count >= 3 else { return nil }
        let teamPart = parts[2]
        let teamParts = teamPart.components(separatedBy: "-")
        guard teamParts.count == 2 else { return nil }
        return (away: teamParts[0], home: teamParts[1])
    }
}
