//
//  FairBetMockDataProvider.swift
//  ScrollDown
//
//  Provides mock data for development, previews, and testing
//

import Foundation

/// Provides mock betting data for development and previews
final class FairBetMockDataProvider: ObservableObject {

    static let shared = FairBetMockDataProvider()

    /// Available sportsbooks
    let sportsbooks = [
        "DraftKings",
        "FanDuel",
        "BetMGM",
        "Caesars",
        "PointsBet",
        "BetRivers"
    ]

    /// Get mock API response for previews and testing
    func getMockBetsResponse() -> BetsResponse {
        let bets = getMockBets()
        return BetsResponse(
            bets: bets,
            total: bets.count,
            booksAvailable: sportsbooks,
            gamesAvailable: [
                GameDropdown(gameId: 1001, matchup: "Celtics @ Lakers", gameDate: "2025-03-01T02:00:00Z"),
                GameDropdown(gameId: 2001, matchup: "Bruins @ Maple Leafs", gameDate: "2025-03-01T03:00:00Z"),
                GameDropdown(gameId: 3001, matchup: "Tar Heels @ Blue Devils", gameDate: "2025-03-02T00:00:00Z")
            ],
            marketCategoriesAvailable: ["mainline", "player_prop", "team_prop"]
        )
    }

    /// Get mock bets matching the API format
    /// Includes paired selections for proper vig removal
    func getMockBets() -> [APIBet] {
        let now = Date()

        return [
            // NBA Games - Celtics @ Lakers
            // Spread: Lakers -3.5 (paired with Celtics +3.5) — with server EV
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "spreads",
                selectionKey: "team:los_angeles_lakers",
                lineValue: -3.5,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -110, observedAt: now, evPercent: 2.1, trueProb: 0.52),
                    BookPrice(book: "FanDuel", priceValue: -108, observedAt: now, evPercent: 3.0, trueProb: 0.52),
                    BookPrice(book: "BetMGM", priceValue: -112, observedAt: now, evPercent: 1.2),
                    BookPrice(book: "Caesars", priceValue: -105, observedAt: now, evPercent: 4.5),
                    BookPrice(book: "PointsBet", priceValue: -115, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: -110, observedAt: now)
                ],
                evConfidenceTier: "high",
                trueProb: 0.52,
                referencePrice: -108
            ),
            // Spread: Celtics +3.5 (opposite side)
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "spreads",
                selectionKey: "team:boston_celtics",
                lineValue: 3.5,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -110, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: -112, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: -108, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -115, observedAt: now),
                    BookPrice(book: "PointsBet", priceValue: -105, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: -110, observedAt: now)
                ]
            ),
            // Moneyline: Celtics (paired with Lakers) — with server EV + sharp book
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "h2h",
                selectionKey: "team:boston_celtics",
                lineValue: nil,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -145, observedAt: now, evPercent: 1.5),
                    BookPrice(book: "FanDuel", priceValue: -140, observedAt: now, evPercent: 3.2),
                    BookPrice(book: "BetMGM", priceValue: -150, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -142, observedAt: now),
                    BookPrice(book: "Pinnacle", priceValue: -143, observedAt: now, isSharp: true),
                    BookPrice(book: "BetRivers", priceValue: -145, observedAt: now)
                ],
                evConfidenceTier: "medium",
                trueProb: 0.59,
                referencePrice: -143
            ),
            // Moneyline: Lakers (opposite side)
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "h2h",
                selectionKey: "team:los_angeles_lakers",
                lineValue: nil,
                books: [
                    BookPrice(book: "DraftKings", priceValue: 125, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: 120, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: 130, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: 122, observedAt: now),
                    BookPrice(book: "PointsBet", priceValue: 118, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: 125, observedAt: now)
                ]
            ),
            // Total: Over 224.5 (paired with Under)
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "totals",
                selectionKey: "total:over",
                lineValue: 224.5,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -110, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: -105, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: -108, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -110, observedAt: now),
                    BookPrice(book: "PointsBet", priceValue: -112, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: -108, observedAt: now)
                ]
            ),
            // Total: Under 224.5 (opposite side)
            APIBet(
                gameId: 1001,
                leagueCode: "NBA",
                homeTeam: "Los Angeles Lakers",
                awayTeam: "Boston Celtics",
                gameDate: now.addingTimeInterval(7200),
                marketKey: "totals",
                selectionKey: "total:under",
                lineValue: 224.5,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -110, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: -115, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: -112, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -110, observedAt: now),
                    BookPrice(book: "PointsBet", priceValue: -108, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: -112, observedAt: now)
                ]
            ),
            // NHL Game
            APIBet(
                gameId: 2001,
                leagueCode: "NHL",
                homeTeam: "Toronto Maple Leafs",
                awayTeam: "Boston Bruins",
                gameDate: now.addingTimeInterval(10800),
                marketKey: "h2h",
                selectionKey: "team:boston_bruins",
                lineValue: nil,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -125, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: -120, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: -128, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -122, observedAt: now),
                    BookPrice(book: "BetRivers", priceValue: -118, observedAt: now)
                ]
            ),
            // NCAAB Game
            APIBet(
                gameId: 3001,
                leagueCode: "NCAAB",
                homeTeam: "Duke Blue Devils",
                awayTeam: "North Carolina Tar Heels",
                gameDate: now.addingTimeInterval(86400),
                marketKey: "spreads",
                selectionKey: "team:duke_blue_devils",
                lineValue: -4.5,
                books: [
                    BookPrice(book: "DraftKings", priceValue: -110, observedAt: now),
                    BookPrice(book: "FanDuel", priceValue: -108, observedAt: now),
                    BookPrice(book: "BetMGM", priceValue: -115, observedAt: now),
                    BookPrice(book: "Caesars", priceValue: -105, observedAt: now),
                    BookPrice(book: "PointsBet", priceValue: -110, observedAt: now)
                ]
            )
        ]
    }
}
