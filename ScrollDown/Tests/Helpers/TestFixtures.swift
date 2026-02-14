import Foundation
@testable import ScrollDown

// MARK: - Stub Game Service

struct StubGameService: GameService {
    var detail: GameDetailResponse
    var gameList: GameListResponse?
    var pbpResponse: PbpResponse?
    var socialResponse: SocialPostListResponse?
    var flowResponse: GameFlowResponse?
    var shouldThrow: Error?

    init(detail: GameDetailResponse) {
        self.detail = detail
    }

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        if let error = shouldThrow { throw error }
        return detail
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        if let error = shouldThrow { throw error }
        return gameList ?? GameListResponse(games: [], range: range.rawValue)
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        if let error = shouldThrow { throw error }
        return pbpResponse ?? PbpResponse(events: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        if let error = shouldThrow { throw error }
        return socialResponse ?? SocialPostListResponse(posts: [], total: 0)
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        if let error = shouldThrow { throw error }
        return TimelineArtifactResponse(
            gameId: gameId,
            sport: nil,
            timelineVersion: nil,
            generatedAt: nil,
            timelineJson: nil,
            gameAnalysisJson: nil,
            summaryJson: nil
        )
    }

    func fetchFlow(gameId: Int) async throws -> GameFlowResponse {
        if let error = shouldThrow { throw error }
        return flowResponse ?? GameFlowResponse(gameId: gameId, sport: "NBA")
    }

    func fetchTeamColors() async throws -> [TeamSummary] {
        return []
    }

    func fetchUnifiedTimeline(gameId: Int) async throws -> [[String: Any]] {
        return []
    }
}

// MARK: - Test Factories

enum TestFixtures {

    static func makeGame(
        id: Int = 1,
        leagueCode: String = "NBA",
        season: Int = 2025,
        seasonType: String? = "regular",
        gameDate: String = "2025-01-15T19:30:00Z",
        homeTeam: String = "Boston Celtics",
        awayTeam: String = "Los Angeles Lakers",
        homeScore: Int? = 112,
        awayScore: Int? = 108,
        status: GameStatus = .completed,
        hasBoxscore: Bool? = true,
        hasPlayerStats: Bool? = true,
        hasOdds: Bool? = true,
        hasSocial: Bool? = true,
        hasPbp: Bool? = true
    ) -> Game {
        Game(
            id: id,
            leagueCode: leagueCode,
            season: season,
            seasonType: seasonType,
            gameDate: gameDate,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: homeScore,
            awayScore: awayScore,
            status: status,
            scrapeVersion: 1,
            lastScrapedAt: "2025-01-15T22:00:00Z",
            hasBoxscore: hasBoxscore,
            hasPlayerStats: hasPlayerStats,
            hasOdds: hasOdds,
            hasSocial: hasSocial,
            hasPbp: hasPbp,
            playCount: 200,
            socialPostCount: 5,
            homeTeamXHandle: nil,
            awayTeamXHandle: nil,
            homeTeamAbbr: nil,
            awayTeamAbbr: nil,
            homeTeamColorLight: nil,
            homeTeamColorDark: nil,
            awayTeamColorLight: nil,
            awayTeamColorDark: nil
        )
    }

    static func makeGameSummary(
        id: Int = 42,
        leagueCode: String = "NBA",
        gameDate: String = "2025-01-15T19:30:00Z",
        status: GameStatus? = nil,
        homeTeam: String = "Team A",
        awayTeam: String = "Team B",
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        playCount: Int? = nil
    ) -> GameSummary {
        GameSummary(
            id: id,
            leagueCode: leagueCode,
            gameDate: gameDate,
            status: status,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
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
            lastScrapedAt: "2025-01-15T22:00:00Z"
        )
    }

    static func makeGameDetail(
        game: Game? = nil,
        teamStats: [TeamStat] = [],
        playerStats: [PlayerStat] = [],
        odds: [OddsEntry] = [],
        socialPosts: [SocialPostEntry] = [],
        plays: [PlayEntry] = []
    ) -> GameDetailResponse {
        GameDetailResponse(
            game: game ?? makeGame(),
            teamStats: teamStats,
            playerStats: playerStats,
            odds: odds,
            socialPosts: socialPosts,
            plays: plays,
            derivedMetrics: [:],
            rawPayloads: [:]
        )
    }

    static func makePlayEntry(
        playIndex: Int = 1,
        quarter: Int? = 1,
        gameClock: String? = "10:00",
        playType: PlayType? = .madeShot,
        teamAbbreviation: String? = "BOS",
        playerName: String? = "Jayson Tatum",
        description: String? = nil,
        homeScore: Int? = 2,
        awayScore: Int? = 0
    ) -> PlayEntry {
        PlayEntry(
            playIndex: playIndex,
            quarter: quarter,
            gameClock: gameClock,
            playType: playType,
            teamAbbreviation: teamAbbreviation,
            playerName: playerName,
            description: description,
            homeScore: homeScore,
            awayScore: awayScore
        )
    }

    static func makeOddsEntry(
        book: String = "DraftKings",
        marketType: MarketType = .spread,
        side: String? = "Boston Celtics",
        line: Double? = -5.5,
        price: Double? = -110,
        isClosingLine: Bool = true
    ) -> OddsEntry {
        OddsEntry(
            book: book,
            marketType: marketType,
            side: side,
            line: line,
            price: price,
            isClosingLine: isClosingLine
        )
    }

    static func makeSocialPost(
        id: Int = 1,
        postUrl: String = "https://x.com/test/1",
        postedAt: String = "2025-01-15T19:00:00Z",
        hasVideo: Bool = false,
        teamAbbreviation: String = "BOS",
        tweetText: String? = "Great game!",
        imageUrl: String? = nil
    ) -> SocialPostEntry {
        SocialPostEntry(
            id: id,
            postUrl: postUrl,
            postedAt: postedAt,
            hasVideo: hasVideo,
            teamAbbreviation: teamAbbreviation,
            tweetText: tweetText,
            imageUrl: imageUrl
        )
    }

    static func makeSocialPostResponse(
        id: Int = 1,
        gameId: Int = 1,
        teamId: String = "BOS",
        postUrl: String = "https://x.com/test/1",
        postedAt: String = "2025-01-15T19:00:00Z",
        hasVideo: Bool = false,
        revealLevel: RevealLevel? = nil,
        tweetText: String? = "Great game!"
    ) -> SocialPostResponse {
        SocialPostResponse(
            id: id,
            gameId: gameId,
            teamId: teamId,
            postUrl: postUrl,
            postedAt: postedAt,
            hasVideo: hasVideo,
            tweetText: tweetText,
            revealLevel: revealLevel
        )
    }
}
