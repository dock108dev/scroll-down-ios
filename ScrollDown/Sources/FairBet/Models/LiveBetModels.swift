//
//  LiveBetModels.swift
//  ScrollDown
//
//  Models for live in-game odds from the FairBet API.
//

import Foundation

// MARK: - Live Games Discovery

struct LiveGameInfo: Codable, Identifiable {
    let gameId: Int
    let leagueCode: String
    let homeTeam: String
    let awayTeam: String
    let gameDate: String
    let status: String

    var id: Int { gameId }

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case leagueCode = "league_code"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case gameDate = "game_date"
        case status
    }
}

// MARK: - Live Odds Response

struct FairbetLiveResponse: Codable {
    let gameId: Int
    let leagueCode: String?
    let homeTeam: String?
    let awayTeam: String?
    let bets: [APIBet]
    let total: Int
    let booksAvailable: [String]
    let marketCategoriesAvailable: [String]?
    let lastUpdatedAt: String?
    let evDiagnostics: EVDiagnostics?

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case leagueCode = "league_code"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case bets, total
        case booksAvailable = "books_available"
        case marketCategoriesAvailable = "market_categories_available"
        case lastUpdatedAt = "last_updated_at"
        case evDiagnostics = "ev_diagnostics"
    }
}

// MARK: - Grouped Live Games

struct LiveGameGroup: Identifiable {
    let game: LiveGameInfo
    var bets: [APIBet]

    var id: Int { game.gameId }

    var matchupDisplay: String {
        "\(game.awayTeam) @ \(game.homeTeam)"
    }
}
