import XCTest
@testable import ScrollDownSports

final class DecodingTests: XCTestCase {
    func testDecodesTaggedWebGameListShape() throws {
        let json = """
        {
          "games": [
            {
              "id": 42,
              "leagueCode": "mlb",
              "gameDate": "2026-05-22T23:10:00Z",
              "localGameDate": "2026-05-22",
              "status": "in_progress",
              "homeTeam": "Seattle Mariners",
              "awayTeam": "New York Yankees",
              "homeTeamAbbr": "SEA",
              "awayTeamAbbr": "NYY",
              "score": { "home": 2, "away": 1 },
              "playCount": 98,
              "isLive": true
            }
          ],
          "total": 1
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(GameListResponse.self, from: json)

        XCTAssertEqual(response.games.count, 1)
        XCTAssertEqual(response.games[0].resolvedHomeScore, 2)
        XCTAssertEqual(response.games[0].resolvedAwayScore, 1)
        XCTAssertTrue(response.games[0].isLiveGame)
        XCTAssertEqual(response.games[0].matchupText, "New York Yankees at Seattle Mariners")
    }

    func testDecodesGameDetailStatsAndPlays() throws {
        let json = """
        {
          "game": {
            "id": 42,
            "leagueCode": "nba",
            "gameDate": "2026-05-22T23:30:00Z",
            "status": "final",
            "homeTeam": "Boston Celtics",
            "awayTeam": "New York Knicks",
            "score": { "home": 104, "away": 99 }
          },
          "teamStats": [
            { "team": "Boston Celtics", "isHome": true, "stats": { "rebounds": 42 } }
          ],
          "playerStats": [
            { "team": "Boston Celtics", "playerName": "Example Player", "points": 28, "rawStats": { "assists": 6 } }
          ],
          "plays": [
            { "playIndex": 1, "periodLabel": "Q1", "gameClock": "11:42", "description": "Made jumper" }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder.sda.decode(GameDetailResponse.self, from: json)

        XCTAssertEqual(response.game.resolvedHomeScore, 104)
        XCTAssertEqual(response.playerStats[0].points, 28)
        XCTAssertEqual(response.plays[0].description, "Made jumper")
    }
}

