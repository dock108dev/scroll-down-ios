//
//  FairBetAPIModels.swift
//  ScrollDown
//
//  Codable structs matching the FairBet API response format
//  API Docs: /api/fairbet/odds
//

import Foundation

/// Supported leagues for the FairBet API
enum FairBetLeague: String, CaseIterable, Identifiable, Codable {
    case nba = "NBA"
    case nhl = "NHL"
    case ncaab = "NCAAB"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nba, .ncaab: return "basketball.fill"
        case .nhl: return "hockey.puck.fill"
        }
    }

    var displayName: String { rawValue }
}

/// Market types from the API
/// Supports known mainline markets and decodes unknown values gracefully
enum MarketKey: Identifiable, Codable, Equatable, Hashable {
    case h2h
    case spreads
    case totals
    case playerPoints
    case playerRebounds
    case playerAssists
    case playerThrees
    case playerBlocks
    case playerSteals
    case playerGoals
    case playerShotsOnGoal
    case playerTotalSaves
    case playerPRA
    case teamTotals
    case alternateSpreads
    case alternateTotals
    case unknown(String)

    var id: String { rawValue }

    var rawValue: String {
        switch self {
        case .h2h: return "h2h"
        case .spreads: return "spreads"
        case .totals: return "totals"
        case .playerPoints: return "player_points"
        case .playerRebounds: return "player_rebounds"
        case .playerAssists: return "player_assists"
        case .playerThrees: return "player_threes"
        case .playerBlocks: return "player_blocks"
        case .playerSteals: return "player_steals"
        case .playerGoals: return "player_goals"
        case .playerShotsOnGoal: return "player_shots_on_goal"
        case .playerTotalSaves: return "player_total_saves"
        case .playerPRA: return "player_points_rebounds_assists"
        case .teamTotals: return "team_totals"
        case .alternateSpreads: return "alternate_spreads"
        case .alternateTotals: return "alternate_totals"
        case .unknown(let val): return val
        }
    }

    var displayName: String {
        switch self {
        case .h2h: return "Moneyline"
        case .spreads: return "Spread"
        case .totals: return "Total"
        case .playerPoints: return "Player Points"
        case .playerRebounds: return "Player Rebounds"
        case .playerAssists: return "Player Assists"
        case .playerThrees: return "Player Threes"
        case .playerBlocks: return "Player Blocks"
        case .playerSteals: return "Player Steals"
        case .playerGoals: return "Player Goals"
        case .playerShotsOnGoal: return "Shots on Goal"
        case .playerTotalSaves: return "Goalie Saves"
        case .playerPRA: return "PRA"
        case .teamTotals: return "Team Total"
        case .alternateSpreads: return "Alt Spread"
        case .alternateTotals: return "Alt Total"
        case .unknown(let val): return val.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Known mainline markets for filtering UI
    static var mainlineMarkets: [MarketKey] {
        [.h2h, .spreads, .totals]
    }

    /// Player prop markets
    static var playerPropMarkets: [MarketKey] {
        [.playerPoints, .playerRebounds, .playerAssists, .playerThrees,
         .playerBlocks, .playerSteals, .playerGoals, .playerShotsOnGoal,
         .playerTotalSaves, .playerPRA]
    }

    /// Team prop markets
    static var teamPropMarkets: [MarketKey] {
        [.teamTotals]
    }

    /// Whether this market is a player prop
    var isPlayerProp: Bool {
        MarketKey.playerPropMarkets.contains(self)
    }

    /// Whether this market is a team prop
    var isTeamProp: Bool {
        MarketKey.teamPropMarkets.contains(self)
    }

    init(rawValue: String) {
        switch rawValue {
        case "h2h": self = .h2h
        case "spreads": self = .spreads
        case "totals": self = .totals
        case "player_points": self = .playerPoints
        case "player_rebounds": self = .playerRebounds
        case "player_assists": self = .playerAssists
        case "player_threes": self = .playerThrees
        case "player_blocks": self = .playerBlocks
        case "player_steals": self = .playerSteals
        case "player_goals": self = .playerGoals
        case "player_shots_on_goal": self = .playerShotsOnGoal
        case "player_total_saves": self = .playerTotalSaves
        case "player_points_rebounds_assists": self = .playerPRA
        case "team_totals": self = .teamTotals
        case "alternate_spreads": self = .alternateSpreads
        case "alternate_totals": self = .alternateTotals
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Game dropdown option from the API
struct GameDropdown: Codable, Identifiable, Equatable {
    let gameId: Int
    let matchup: String
    let gameDate: String

    var id: Int { gameId }

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case matchup
        case gameDate = "game_date"
    }
}

/// EV diagnostics from the API
struct EVDiagnostics: Codable, Equatable {
    let totalPairs: Int?
    let totalUnpaired: Int?
    let eligible: Int?
    let noPair: Int?
    let referenceMissing: Int?
    let extrapolated: Int?

    enum CodingKeys: String, CodingKey {
        case totalPairs = "total_pairs"
        case totalUnpaired = "total_unpaired"
        case eligible
        case noPair = "no_pair"
        case referenceMissing = "reference_missing"
        case extrapolated
    }
}

/// API response wrapper from /api/fairbet/odds
struct BetsResponse: Codable {
    let bets: [APIBet]
    let total: Int
    let booksAvailable: [String]
    var gamesAvailable: [GameDropdown]? = nil
    var marketCategoriesAvailable: [String]? = nil
    var evDiagnostics: EVDiagnostics? = nil

    enum CodingKeys: String, CodingKey {
        case bets
        case total
        case booksAvailable = "books_available"
        case gamesAvailable = "games_available"
        case marketCategoriesAvailable = "market_categories_available"
        case evDiagnostics = "ev_diagnostics"
    }
}

/// Individual bet from the FairBet API
/// Maps from API format to app-friendly format
struct APIBet: Identifiable, Codable, Equatable {
    let gameId: Int
    let leagueCode: String
    let homeTeam: String
    let awayTeam: String
    let gameDate: Date
    let marketKey: String
    let selectionKey: String
    let lineValue: Double?
    let books: [BookPrice]
    // Server-side EV annotations
    var marketCategory: String? = nil
    var hasFair: Bool? = nil
    var playerName: String? = nil
    var evMethod: String? = nil
    var evConfidenceTier: String? = nil
    var evDisabledReason: String? = nil
    var trueProb: Double? = nil
    var referencePrice: Int? = nil
    var oppositeReferencePrice: Int? = nil
    var betDescription: String? = nil

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case leagueCode = "league_code"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case gameDate = "game_date"
        case marketKey = "market_key"
        case selectionKey = "selection_key"
        case lineValue = "line_value"
        case books
        case marketCategory = "market_category"
        case hasFair = "has_fair"
        case playerName = "player_name"
        case evMethod = "ev_method"
        case evConfidenceTier = "ev_confidence_tier"
        case evDisabledReason = "ev_disabled_reason"
        case trueProb = "true_prob"
        case referencePrice = "reference_price"
        case oppositeReferencePrice = "opposite_reference_price"
        case betDescription = "bet_description"
    }

    /// Unique identifier for the bet
    var id: String {
        "\(gameId)_\(marketKey)_\(selectionKey)_\(lineValue ?? 0)"
    }

    /// Parsed league enum
    var league: FairBetLeague {
        FairBetLeague(rawValue: leagueCode) ?? .nba
    }

    /// Parsed market enum
    var market: MarketKey {
        MarketKey(rawValue: marketKey)
    }

    /// Parse selection from selection_key (e.g., "team:los_angeles_lakers" -> "Los Angeles Lakers")
    var selection: String {
        let parts = selectionKey.split(separator: ":")
        guard parts.count >= 2 else { return selectionKey }

        let rawSelection = String(parts[1...].joined(separator: ":"))

        // Handle totals (over/under)
        if rawSelection == "over" { return "Over" }
        if rawSelection == "under" { return "Under" }

        // Handle team names - convert from slug to display name
        // e.g., "los_angeles_lakers" -> try to match with homeTeam/awayTeam
        let normalized = rawSelection.replacingOccurrences(of: "_", with: " ")

        // Check if it matches home or away team (case insensitive)
        if homeTeam.lowercased().contains(normalized.lowercased()) ||
           normalized.lowercased().contains(homeTeam.lowercased().split(separator: " ").last?.description ?? "") {
            return homeTeam
        }
        if awayTeam.lowercased().contains(normalized.lowercased()) ||
           normalized.lowercased().contains(awayTeam.lowercased().split(separator: " ").last?.description ?? "") {
            return awayTeam
        }

        // No team match — capitalize each word
        return normalized.capitalized
    }

    /// Display string for the selection with line if applicable.
    /// Enriched for player props, team props, and alternates.
    var selectionDisplay: String {
        let marketLabel = FairBetCopy.marketLabel(for: marketKey)

        // Player props: "Player Name Stat O/U Line"
        if market.isPlayerProp {
            let name = playerName ?? selection
            let side = selection  // "Over" / "Under" from selection_key
            if let line = lineValue {
                return "\(name) \(marketLabel) \(side) \(line)"
            }
            return "\(name) \(marketLabel)"
        }

        // Team props: "Team Name Team Total O/U Line"
        if market.isTeamProp {
            let side = selection  // "Over" / "Under" or team name
            if let line = lineValue {
                return "\(selection) \(marketLabel) \(line)"
            }
            return "\(side) \(marketLabel)"
        }

        // Alternates: "Selection Alt Spread/Total Line"
        if market == .alternateSpreads || market == .alternateTotals {
            if let line = lineValue, line != 0 {
                let formattedLine = line >= 0 ? "+\(line)" : "\(line)"
                return "\(selection) \(marketLabel) \(formattedLine)"
            }
            return "\(selection) \(marketLabel)"
        }

        // Mainline: standard display
        if let line = lineValue, line != 0 {
            let formattedLine = line >= 0 ? "+\(line)" : "\(line)"
            return "\(selection) \(formattedLine)"
        }
        return selection
    }

    /// The best price available across all books (highest decimal odds = best for bettor)
    var bestBook: BookPrice? {
        books.max { $0.price < $1.price }
    }

    static func == (lhs: APIBet, rhs: APIBet) -> Bool {
        lhs.id == rhs.id
    }
}


/// Sportsbook price from the API
struct BookPrice: Identifiable, Codable, Equatable {
    let book: String
    let priceValue: Double
    let observedAt: Date
    // Server-side EV annotations
    var evPercent: Double? = nil
    var impliedProb: Double? = nil
    var trueProb: Double? = nil
    var isSharp: Bool? = nil
    var evMethod: String? = nil
    var evConfidenceTier: String? = nil

    var id: String { book }

    /// Display name for the book
    var name: String { book }

    /// Price as Int for calculations (rounds the Double from API)
    var price: Int { Int(priceValue) }

    enum CodingKeys: String, CodingKey {
        case book
        case priceValue = "price"
        case observedAt = "observed_at"
        case evPercent = "ev_percent"
        case impliedProb = "implied_prob"
        case trueProb = "true_prob"
        case isSharp = "is_sharp"
        case evMethod = "ev_method"
        case evConfidenceTier = "ev_confidence_tier"
    }

    /// Convert American odds to AmericanOdds struct
    var americanOdds: AmericanOdds {
        AmericanOdds(price)
    }
}

/// Filter for odds market pills — supports individual markets and grouped categories
enum MarketFilter: Equatable, Hashable {
    case single(MarketKey)
    case playerProps
    case teamProps

    var label: String {
        switch self {
        case .single(let market): return market.displayName
        case .playerProps: return "Player Props"
        case .teamProps: return "Team Props"
        }
    }

    /// Returns true if the given market matches this filter
    func matches(_ market: MarketKey) -> Bool {
        switch self {
        case .single(let key): return market == key
        case .playerProps: return market.isPlayerProp
        case .teamProps: return market.isTeamProp
        }
    }
}
