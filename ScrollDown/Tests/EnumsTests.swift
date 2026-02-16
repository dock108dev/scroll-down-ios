import XCTest
@testable import ScrollDown

final class EnumsTests: XCTestCase {

    // MARK: - GameStatus

    func testGameStatusDecodingCompleted() throws {
        let json = """
        {"id":1,"leagueCode":"NBA","season":2025,"gameDate":"2025-01-01T19:30:00Z","homeTeam":"A","awayTeam":"B","status":"completed"}
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(Game.self, from: json)
        XCTAssertEqual(game.status, .completed)
    }

    func testGameStatusDecodingInProgress() throws {
        let json = """
        {"id":1,"leagueCode":"NBA","season":2025,"gameDate":"2025-01-01T19:30:00Z","homeTeam":"A","awayTeam":"B","status":"in_progress"}
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(Game.self, from: json)
        XCTAssertEqual(game.status, .inProgress)
    }

    func testGameStatusDecodingScheduled() throws {
        let json = """
        {"id":1,"leagueCode":"NBA","season":2025,"gameDate":"2025-01-01T19:30:00Z","homeTeam":"A","awayTeam":"B","status":"scheduled"}
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(Game.self, from: json)
        XCTAssertEqual(game.status, .scheduled)
    }

    func testGameStatusIsCompleted() {
        XCTAssertTrue(GameStatus.completed.isCompleted)
        XCTAssertTrue(GameStatus.final.isCompleted)
        XCTAssertFalse(GameStatus.scheduled.isCompleted)
        XCTAssertFalse(GameStatus.inProgress.isCompleted)
        XCTAssertFalse(GameStatus.postponed.isCompleted)
    }

    // MARK: - MarketType

    func testMarketTypeDecoding() throws {
        let json = """
        {"book":"FanDuel","marketType":"spread","isClosingLine":true}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .spread)
    }

    func testMarketTypeMoneyline() throws {
        let json = """
        {"book":"FanDuel","marketType":"moneyline","isClosingLine":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .moneyline)
    }

    func testMarketTypeTotal() throws {
        let json = """
        {"book":"FanDuel","marketType":"total","isClosingLine":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .total)
    }

    func testMarketTypeAlternateSpreads() throws {
        let json = """
        {"book":"FanDuel","marketType":"alternate_spreads","isClosingLine":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .alternateSpread)
    }

    func testMarketTypeUnknownFallback() throws {
        let json = """
        {"book":"FanDuel","marketType":"some_future_market","isClosingLine":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .unknown("some_future_market"))
    }

    func testMarketTypeAliasH2H() {
        XCTAssertEqual(MarketType(rawValue: "h2h"), .moneyline)
    }

    func testMarketTypeAliasSpreads() {
        XCTAssertEqual(MarketType(rawValue: "spreads"), .spread)
    }

    func testMarketTypeAliasTotals() {
        XCTAssertEqual(MarketType(rawValue: "totals"), .total)
    }

    func testMarketTypeRoundTrip() throws {
        let original = MarketType.alternateSpread
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoded = try JSONDecoder().decode(MarketType.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - MarketKey

    func testMarketKeyInitRawValueKnownCases() {
        XCTAssertEqual(MarketKey(rawValue: "h2h"), .h2h)
        XCTAssertEqual(MarketKey(rawValue: "spreads"), .spreads)
        XCTAssertEqual(MarketKey(rawValue: "totals"), .totals)
        XCTAssertEqual(MarketKey(rawValue: "player_points"), .playerPoints)
        XCTAssertEqual(MarketKey(rawValue: "player_rebounds"), .playerRebounds)
        XCTAssertEqual(MarketKey(rawValue: "player_assists"), .playerAssists)
        XCTAssertEqual(MarketKey(rawValue: "player_threes"), .playerThrees)
        XCTAssertEqual(MarketKey(rawValue: "player_blocks"), .playerBlocks)
        XCTAssertEqual(MarketKey(rawValue: "player_steals"), .playerSteals)
    }

    func testMarketKeyInitRawValueNewCases() {
        XCTAssertEqual(MarketKey(rawValue: "player_goals"), .playerGoals)
        XCTAssertEqual(MarketKey(rawValue: "player_shots_on_goal"), .playerShotsOnGoal)
        XCTAssertEqual(MarketKey(rawValue: "player_total_saves"), .playerTotalSaves)
        XCTAssertEqual(MarketKey(rawValue: "player_points_rebounds_assists"), .playerPRA)
        XCTAssertEqual(MarketKey(rawValue: "team_totals"), .teamTotals)
        XCTAssertEqual(MarketKey(rawValue: "alternate_spreads"), .alternateSpreads)
        XCTAssertEqual(MarketKey(rawValue: "alternate_totals"), .alternateTotals)
    }

    func testMarketKeyUnknownFallback() {
        let key = MarketKey(rawValue: "some_future_market")
        XCTAssertEqual(key, .unknown("some_future_market"))
        XCTAssertEqual(key.rawValue, "some_future_market")
    }

    func testMarketKeyDecoding() throws {
        let json = "\"player_goals\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MarketKey.self, from: json)
        XCTAssertEqual(decoded, .playerGoals)
    }

    func testMarketKeyDecodingUnknown() throws {
        let json = "\"xyz_market\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(MarketKey.self, from: json)
        XCTAssertEqual(decoded, .unknown("xyz_market"))
    }

    func testMarketKeyRoundTrip() throws {
        let cases: [MarketKey] = [
            .h2h, .spreads, .totals,
            .playerGoals, .playerShotsOnGoal, .playerTotalSaves,
            .playerPRA, .teamTotals, .alternateSpreads, .alternateTotals
        ]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for original in cases {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(MarketKey.self, from: data)
            XCTAssertEqual(decoded, original)
        }
    }

    func testMarketKeyRoundTripUnknown() throws {
        let original = MarketKey.unknown("brand_new_thing")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MarketKey.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.rawValue, "brand_new_thing")
    }

    // MARK: - MediaType

    func testMediaTypeDecoding() throws {
        let json = """
        {"id":1,"gameId":1,"teamId":"BOS","postUrl":"https://x.com/test","postedAt":"2025-01-01T19:00:00Z","hasVideo":true,"mediaType":"video"}
        """.data(using: .utf8)!
        let post = try JSONDecoder().decode(SocialPostResponse.self, from: json)
        XCTAssertEqual(post.mediaType, .video)
    }

    // MARK: - PlayType

    func testPlayTypeKnownValues() {
        XCTAssertEqual(PlayType(rawValue: "made_shot"), .madeShot)
        XCTAssertEqual(PlayType(rawValue: "jump_ball"), .jumpBall)
        XCTAssertEqual(PlayType(rawValue: "goal"), .goal)
        XCTAssertEqual(PlayType(rawValue: "period_end"), .periodEnd)
    }

    func testPlayTypeUnknown() {
        let playType = PlayType(rawValue: "custom_event")
        XCTAssertEqual(playType, .unknown("custom_event"))
    }

    func testPlayTypeRoundTrip() {
        let original = PlayType.madeShot
        let rawValue = original.rawValue
        let decoded = PlayType(rawValue: rawValue)
        XCTAssertEqual(decoded, original)
    }

    // MARK: - LeagueCode

    func testLeagueCodeCaseIterable() {
        XCTAssertEqual(LeagueCode.allCases.count, 6)
    }

    func testLeagueCodeRawValues() {
        XCTAssertEqual(LeagueCode.nba.rawValue, "NBA")
        XCTAssertEqual(LeagueCode.nhl.rawValue, "NHL")
        XCTAssertEqual(LeagueCode.nfl.rawValue, "NFL")
        XCTAssertEqual(LeagueCode.mlb.rawValue, "MLB")
    }

    // MARK: - RevealLevel

    func testRevealLevelDecoding() throws {
        let preJSON = "\"pre\"".data(using: .utf8)!
        let pre = try JSONDecoder().decode(RevealLevel.self, from: preJSON)
        XCTAssertEqual(pre, .pre)

        let postJSON = "\"post\"".data(using: .utf8)!
        let post = try JSONDecoder().decode(RevealLevel.self, from: postJSON)
        XCTAssertEqual(post, .post)
    }
}
