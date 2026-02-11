import XCTest
@testable import ScrollDown

final class EnumsTests: XCTestCase {

    // MARK: - GameStatus

    func testGameStatusDecodingCompleted() throws {
        let json = """
        {"id":1,"league_code":"NBA","season":2025,"game_date":"2025-01-01T19:30:00Z","home_team":"A","away_team":"B","status":"completed"}
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(Game.self, from: json)
        XCTAssertEqual(game.status, .completed)
    }

    func testGameStatusDecodingInProgress() throws {
        let json = """
        {"id":1,"league_code":"NBA","season":2025,"game_date":"2025-01-01T19:30:00Z","home_team":"A","away_team":"B","status":"in_progress"}
        """.data(using: .utf8)!
        let game = try JSONDecoder().decode(Game.self, from: json)
        XCTAssertEqual(game.status, .inProgress)
    }

    func testGameStatusDecodingScheduled() throws {
        let json = """
        {"id":1,"league_code":"NBA","season":2025,"game_date":"2025-01-01T19:30:00Z","home_team":"A","away_team":"B","status":"scheduled"}
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
        {"book":"FanDuel","market_type":"spread","is_closing_line":true}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .spread)
    }

    func testMarketTypeMoneyline() throws {
        let json = """
        {"book":"FanDuel","market_type":"moneyline","is_closing_line":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .moneyline)
    }

    func testMarketTypeTotal() throws {
        let json = """
        {"book":"FanDuel","market_type":"total","is_closing_line":false}
        """.data(using: .utf8)!
        let odds = try JSONDecoder().decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .total)
    }

    // MARK: - MediaType

    func testMediaTypeDecoding() throws {
        let json = """
        {"id":1,"game_id":1,"team_id":"BOS","post_url":"https://x.com/test","posted_at":"2025-01-01T19:00:00Z","has_video":true,"media_type":"video"}
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
