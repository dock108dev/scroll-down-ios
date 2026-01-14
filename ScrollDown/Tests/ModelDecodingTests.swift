import XCTest
@testable import ScrollDown

/// Tests to verify mock JSON decodes correctly into models
final class ModelDecodingTests: XCTestCase {
    
    // MARK: - Game List Response
    
    func testGameListResponseDecoding() throws {
        let response: GameListResponse = MockLoader.load("game-list")
        
        XCTAssertEqual(response.games.count, 4)
        XCTAssertEqual(response.total, 157)
        XCTAssertEqual(response.nextOffset, 50)
        
        // Verify first game
        let firstGame = response.games[0]
        XCTAssertEqual(firstGame.id, 12345)
        XCTAssertEqual(firstGame.leagueCode, "NBA")
        XCTAssertEqual(firstGame.homeTeam, "Boston Celtics")
        XCTAssertEqual(firstGame.awayTeam, "Los Angeles Lakers")
        XCTAssertEqual(firstGame.homeScore, 112)
        XCTAssertEqual(firstGame.awayScore, 108)
        XCTAssertEqual(firstGame.status, .completed)
        XCTAssertTrue(firstGame.hasBoxscore ?? false)

        let inProgressGame = response.games[2]
        XCTAssertEqual(inProgressGame.status, .inProgress)
    }
    
    // MARK: - Game Detail Response
    
    func testGameDetailResponseDecoding() throws {
        let response: GameDetailResponse = MockLoader.load("game-001")
        
        // Verify game metadata
        XCTAssertEqual(response.game.id, 12345)
        XCTAssertEqual(response.game.leagueCode, "NBA")
        XCTAssertEqual(response.game.season, 2025)
        XCTAssertEqual(response.game.status, .completed)
        
        // Verify team stats
        XCTAssertEqual(response.teamStats.count, 2)
        
        // Verify player stats
        XCTAssertEqual(response.playerStats.count, 2)
        let tatum = response.playerStats.first { $0.playerName == "Jayson Tatum" }
        XCTAssertNotNil(tatum)
        XCTAssertEqual(tatum?.points, 32)
        
        // Verify odds
        XCTAssertEqual(response.odds.count, 4)
        
        // Verify social posts
        XCTAssertEqual(response.socialPosts.count, 2)
        
        // Verify plays
        XCTAssertEqual(response.plays.count, 3)

        // Verify compact moments
        XCTAssertEqual(response.compactMoments?.count, 2)
        XCTAssertEqual(response.compactMoments?.first?.description, "Opening tip sets the tempo early.")
    }
    
    // MARK: - PBP Response
    
    func testPbpResponseDecoding() throws {
        let response: PbpResponse = MockLoader.load("pbp-001")
        
        XCTAssertEqual(response.events.count, 9)
        
        // Verify first event
        let firstEvent = response.events[0]
        XCTAssertEqual(firstEvent.id.intValue, 1)
        XCTAssertEqual(firstEvent.gameId.intValue, 12345)
        XCTAssertEqual(firstEvent.period, 1)
        XCTAssertEqual(firstEvent.eventType, "jump_ball")
    }
    
    // MARK: - Social Posts Response
    
    func testSocialPostsResponseDecoding() throws {
        let response: SocialPostListResponse = MockLoader.load("social-posts")
        
        XCTAssertEqual(response.posts.count, 4)
        XCTAssertEqual(response.total, 4)
        
        // Verify first post
        let firstPost = response.posts[0]
        XCTAssertEqual(firstPost.id, 101)
        XCTAssertEqual(firstPost.teamId, "BOS")
        XCTAssertFalse(firstPost.hasVideo)
        XCTAssertEqual(firstPost.mediaType, .image)
    }

    // MARK: - Related Posts Response

    func testRelatedPostsResponseDecoding() throws {
        let response: RelatedPostListResponse = MockLoader.load("related-posts")

        XCTAssertEqual(response.posts.count, 5)
        XCTAssertEqual(response.total, 5)

        let firstPost = response.posts[0]
        XCTAssertEqual(firstPost.id, 201)
        XCTAssertTrue(firstPost.containsScore)
        XCTAssertEqual(firstPost.sourceHandle, "NBA")
    }

    // MARK: - Enum Decoding
    
    func testGameStatusDecoding() throws {
        let json = """
        {
            "id": 1,
            "league_code": "NBA",
            "season": 2025,
            "game_date": "2026-01-01T19:30:00Z",
            "home_team": "Team A",
            "away_team": "Team B",
            "status": "completed"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let game = try decoder.decode(Game.self, from: json)
        XCTAssertEqual(game.status, .completed)
    }
    
    func testMarketTypeDecoding() throws {
        let json = """
        {
            "book": "FanDuel",
            "market_type": "spread",
            "is_closing_line": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let odds = try decoder.decode(OddsEntry.self, from: json)
        XCTAssertEqual(odds.marketType, .spread)
    }
    
    func testMediaTypeDecoding() throws {
        let json = """
        {
            "id": 1,
            "game_id": 1,
            "team_id": "BOS",
            "post_url": "https://x.com/test",
            "posted_at": "2026-01-01T19:00:00Z",
            "has_video": true,
            "media_type": "video"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let post = try decoder.decode(SocialPostResponse.self, from: json)
        XCTAssertEqual(post.mediaType, .video)
    }

    // MARK: - Game Summary Logic

    func testGameSummaryInferredStatus() {
        let scheduledGame = makeGameSummary(playCount: 0)
        XCTAssertEqual(scheduledGame.inferredStatus, .scheduled)

        let inProgressGame = makeGameSummary(playCount: 12)
        XCTAssertEqual(inProgressGame.inferredStatus, .inProgress)

        let completedGame = makeGameSummary(homeScore: 3, awayScore: 2)
        XCTAssertEqual(completedGame.inferredStatus, .completed)
    }
}

private func makeGameSummary(
    status: GameStatus? = nil,
    homeScore: Int? = nil,
    awayScore: Int? = nil,
    playCount: Int? = nil
) -> GameSummary {
    GameSummary(
        id: 42,
        leagueCode: "NBA",
        gameDate: "2026-01-01T19:30:00Z",
        status: status,
        homeTeam: "Team A",
        awayTeam: "Team B",
        homeScore: homeScore,
        awayScore: awayScore,
        hasBoxscore: false,
        hasPlayerStats: false,
        hasOdds: false,
        hasSocial: false,
        hasPbp: false,
        playCount: playCount,
        socialPostCount: 0,
        hasRequiredData: false,
        scrapeVersion: 1,
        lastScrapedAt: "2026-01-01T20:00:00Z"
    )
}

