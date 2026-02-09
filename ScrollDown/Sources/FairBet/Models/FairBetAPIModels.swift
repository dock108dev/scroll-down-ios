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
enum MarketKey: String, CaseIterable, Identifiable, Codable {
    case h2h = "h2h"
    case spreads = "spreads"
    case totals = "totals"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .h2h: return "Moneyline"
        case .spreads: return "Spread"
        case .totals: return "Total"
        }
    }
}

/// API response wrapper from /api/fairbet/odds
struct BetsResponse: Codable {
    let bets: [APIBet]
    let total: Int
    let booksAvailable: [String]

    enum CodingKeys: String, CodingKey {
        case bets
        case total
        case booksAvailable = "books_available"
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
        MarketKey(rawValue: marketKey) ?? .h2h
    }

    /// Commence time (alias for gameDate)
    var commenceTime: Date { gameDate }

    /// Line value (alias)
    var line: Double? { lineValue }

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

        // Fallback: capitalize each word
        return normalized.capitalized
    }

    /// Display string for the matchup (Away @ Home)
    var matchupDisplay: String {
        "\(awayTeam) @ \(homeTeam)"
    }

    /// Display string for the selection with line if applicable
    var selectionDisplay: String {
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

// MARK: - Book Filtering

extension APIBet {
    /// Returns a copy of this bet with books filtered to only the allowed set.
    func filteringBooks(to allowedBooks: Set<String>) -> APIBet {
        APIBet(
            gameId: gameId, leagueCode: leagueCode,
            homeTeam: homeTeam, awayTeam: awayTeam,
            gameDate: gameDate, marketKey: marketKey,
            selectionKey: selectionKey, lineValue: lineValue,
            books: books.filter { allowedBooks.contains($0.name) }
        )
    }
}

/// Sportsbook price from the API
struct BookPrice: Identifiable, Codable, Equatable {
    let book: String
    let priceValue: Double
    let observedAt: Date

    var id: String { book }

    /// Alias for book name (for compatibility)
    var name: String { book }

    /// Price as Int for calculations (rounds the Double from API)
    var price: Int { Int(priceValue) }

    enum CodingKeys: String, CodingKey {
        case book
        case priceValue = "price"
        case observedAt = "observed_at"
    }

    /// Convert American odds to AmericanOdds struct
    var americanOdds: AmericanOdds {
        AmericanOdds(price)
    }
}
