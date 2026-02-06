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

// MARK: - Bet Group Key Builder

/// Utility for constructing canonical bet_group_key and selection_key
struct BetGroupKeyBuilder {

    /// Construct a canonical bet_group_key
    /// Format: {game_id}|{market_key}|{subject_id}|{line}
    static func buildBetGroupKey(
        gameId: String,
        marketKey: String,
        subjectId: String?,
        line: Double?
    ) -> String {
        let subjectPart = subjectId ?? ""
        let linePart = line.map { formatLine($0) } ?? ""
        return "\(gameId)|\(marketKey)|\(subjectPart)|\(linePart)"
    }

    /// Construct a canonical selection_key
    /// Format: {bet_group_key}:{side}
    static func buildSelectionKey(
        betGroupKey: String,
        side: SelectionSide
    ) -> String {
        "\(betGroupKey):\(side.rawValue)"
    }

    /// Build a canonical game_id
    /// Format: {league}:{date}:{away_team}-{home_team}
    static func buildGameId(
        league: String,
        date: Date,
        awayTeam: String,
        homeTeam: String
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let normalizedAway = normalizeTeamCode(awayTeam)
        let normalizedHome = normalizeTeamCode(homeTeam)

        return "\(league.lowercased()):\(dateString):\(normalizedAway)-\(normalizedHome)"
    }

    /// Normalize team code (uppercase, trimmed)
    static func normalizeTeamCode(_ team: String) -> String {
        team.uppercased().trimmingCharacters(in: .whitespaces)
    }

    /// Normalize player ID for subject_id
    static func normalizePlayerId(_ name: String, disambiguationId: String? = nil) -> String {
        var normalized = name.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")

        if let id = disambiguationId {
            normalized += "-\(id)"
        }

        return normalized
    }

    /// Format line value (one decimal place, absolute for spreads)
    static func formatLine(_ line: Double) -> String {
        String(format: "%.1f", line)
    }
}

// MARK: - Selection Label Builder

/// Utility for building human-readable selection labels
struct SelectionLabelBuilder {

    static func buildLabel(
        marketKey: String,
        side: SelectionSide,
        line: Double?,
        homeTeam: String?,
        awayTeam: String?,
        playerName: String?
    ) -> String {
        switch marketKey {
        case "spread":
            return buildSpreadLabel(side: side, line: line, homeTeam: homeTeam, awayTeam: awayTeam)
        case "total":
            return buildTotalLabel(side: side, line: line)
        case "h2h":
            return buildMoneylineLabel(side: side, homeTeam: homeTeam, awayTeam: awayTeam)
        default:
            // Player props and other markets
            if let player = playerName, let line = line {
                return buildPlayerPropLabel(side: side, playerName: player, line: line, marketKey: marketKey)
            }
            return side.rawValue.capitalized
        }
    }

    private static func buildSpreadLabel(
        side: SelectionSide,
        line: Double?,
        homeTeam: String?,
        awayTeam: String?
    ) -> String {
        guard let line = line else { return side.rawValue.capitalized }

        switch side {
        case .home:
            let team = homeTeam ?? "Home"
            return "\(team) -\(BetGroupKeyBuilder.formatLine(line))"
        case .away:
            let team = awayTeam ?? "Away"
            return "\(team) +\(BetGroupKeyBuilder.formatLine(line))"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildTotalLabel(side: SelectionSide, line: Double?) -> String {
        guard let line = line else { return side.rawValue.capitalized }

        switch side {
        case .over:
            return "Over \(BetGroupKeyBuilder.formatLine(line))"
        case .under:
            return "Under \(BetGroupKeyBuilder.formatLine(line))"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildMoneylineLabel(
        side: SelectionSide,
        homeTeam: String?,
        awayTeam: String?
    ) -> String {
        switch side {
        case .home:
            return homeTeam ?? "Home"
        case .away:
            return awayTeam ?? "Away"
        case .draw:
            return "Draw"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildPlayerPropLabel(
        side: SelectionSide,
        playerName: String,
        line: Double,
        marketKey: String
    ) -> String {
        let propType = marketKey
            .replacingOccurrences(of: "player_", with: "")
            .capitalized

        switch side {
        case .over:
            return "\(playerName) Over \(BetGroupKeyBuilder.formatLine(line)) \(propType)"
        case .under:
            return "\(playerName) Under \(BetGroupKeyBuilder.formatLine(line)) \(propType)"
        default:
            return "\(playerName) \(side.rawValue.capitalized)"
        }
    }
}

// MARK: - Bet Group Factory

/// Factory for creating BetGroups from raw data
struct BetGroupFactory {

    /// Create a spread bet group
    static func createSpread(
        gameId: String,
        line: Double,
        homeTeam: String,
        awayTeam: String,
        homePrices: [GroupBookPrice],
        awayPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "spread",
            subjectId: nil,
            line: line
        )

        let homeSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .home),
            betGroupKey: betGroupKey,
            side: .home,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "spread",
                side: .home,
                line: line,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                playerName: nil
            ),
            teamId: homeTeam,
            prices: homePrices
        )

        let awaySelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .away),
            betGroupKey: betGroupKey,
            side: .away,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "spread",
                side: .away,
                line: line,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                playerName: nil
            ),
            teamId: awayTeam,
            prices: awayPrices
        )

        let pairingStatus = determinePairingStatus(selections: [homeSelection, awaySelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "spread",
            subjectId: nil,
            line: line,
            pairingStatus: pairingStatus,
            selections: [homeSelection, awaySelection]
        )
    }

    /// Create a total bet group
    static func createTotal(
        gameId: String,
        line: Double,
        overPrices: [GroupBookPrice],
        underPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "total",
            subjectId: nil,
            line: line
        )

        let overSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .over),
            betGroupKey: betGroupKey,
            side: .over,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "total",
                side: .over,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: nil
            ),
            teamId: nil,
            prices: overPrices
        )

        let underSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .under),
            betGroupKey: betGroupKey,
            side: .under,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "total",
                side: .under,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: nil
            ),
            teamId: nil,
            prices: underPrices
        )

        let pairingStatus = determinePairingStatus(selections: [overSelection, underSelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "total",
            subjectId: nil,
            line: line,
            pairingStatus: pairingStatus,
            selections: [overSelection, underSelection]
        )
    }

    /// Create a moneyline bet group
    static func createMoneyline(
        gameId: String,
        homeTeam: String,
        awayTeam: String,
        homePrices: [GroupBookPrice],
        awayPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "h2h",
            subjectId: nil,
            line: nil
        )

        let homeSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .home),
            betGroupKey: betGroupKey,
            side: .home,
            label: homeTeam,
            teamId: homeTeam,
            prices: homePrices
        )

        let awaySelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .away),
            betGroupKey: betGroupKey,
            side: .away,
            label: awayTeam,
            teamId: awayTeam,
            prices: awayPrices
        )

        let pairingStatus = determinePairingStatus(selections: [homeSelection, awaySelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "h2h",
            subjectId: nil,
            line: nil,
            pairingStatus: pairingStatus,
            selections: [homeSelection, awaySelection]
        )
    }

    /// Create a player prop bet group
    static func createPlayerProp(
        gameId: String,
        marketKey: String,
        playerId: String,
        playerName: String,
        line: Double,
        overPrices: [GroupBookPrice],
        underPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: marketKey,
            subjectId: playerId,
            line: line
        )

        let overSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .over),
            betGroupKey: betGroupKey,
            side: .over,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: marketKey,
                side: .over,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: playerName
            ),
            teamId: nil,
            prices: overPrices
        )

        let underSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .under),
            betGroupKey: betGroupKey,
            side: .under,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: marketKey,
                side: .under,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: playerName
            ),
            teamId: nil,
            prices: underPrices
        )

        let pairingStatus = determinePairingStatus(selections: [overSelection, underSelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: marketKey,
            subjectId: playerId,
            line: line,
            pairingStatus: pairingStatus,
            selections: [overSelection, underSelection]
        )
    }

    /// Determine pairing status based on selection prices
    private static func determinePairingStatus(selections: [Selection]) -> PairingStatus {
        guard selections.count >= 2 else { return .oneSided }

        let allHavePrices = selections.allSatisfy { $0.hasPrices }
        let anyHasPrices = selections.contains { $0.hasPrices }

        if !anyHasPrices {
            return .unpaired
        }

        if !allHavePrices {
            return .oneSided
        }

        // Check if any book prices both sides
        let firstBookKeys = selections[0].bookKeys
        for selection in selections.dropFirst() {
            if !firstBookKeys.isDisjoint(with: selection.bookKeys) {
                return .paired
            }
        }

        return .unpaired
    }
}
