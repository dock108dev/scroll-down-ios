import Foundation

/// Mock implementation of GameService that generates realistic game data
/// Uses AppDate.now() to create games relative to the dev clock
final class MockGameService: GameService {
    
    // MARK: - Cache for loaded data
    private var gameCache: [Int: GameDetailResponse] = [:]
    private var generatedGames: [GameSummary]?
    
    // MARK: - GameService Implementation
    
    func fetchGame(id: Int) async throws -> GameDetailResponse {
        // Simulate network delay for realistic feel
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Check cache first
        if let cached = gameCache[id] {
            return cached
        }
        
        // Ensure games are generated
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }
        
        // Find the game summary for this ID
        guard let gameSummary = generatedGames?.first(where: { $0.id == id }) else {
            throw GameServiceError.notFound
        }
        
        // Generate a detail response for this specific game
        let response = MockDataGenerator.generateGameDetail(from: gameSummary)
        gameCache[id] = response
        return response
    }
    
    func fetchGames(league: LeagueCode?, limit: Int, offset: Int) async throws -> GameListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Generate games if not cached
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }
        
        var games = generatedGames ?? []
        
        // Apply league filter if specified
        if let league = league {
            games = games.filter { $0.leagueCode == league.rawValue }
        }
        
        return GameListResponse(
            games: games,
            total: games.count,
            nextOffset: nil,
            withBoxscoreCount: games.filter { $0.hasBoxscore == true }.count,
            withPlayerStatsCount: games.filter { $0.hasPlayerStats == true }.count,
            withOddsCount: games.filter { $0.hasOdds == true }.count,
            withSocialCount: games.filter { $0.hasSocial == true }.count,
            withPbpCount: games.filter { $0.hasPbp == true }.count
        )
    }
    
    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        return MockLoader.load("pbp-001")
    }

    func fetchCompactMomentPbp(momentId: StringOrInt) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 120_000_000) // 120ms

        return MockLoader.load("pbp-001")
    }
    
    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        return MockLoader.load("social-posts")
    }

    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        return MockLoader.load("related-posts")
    }

    func fetchSummary(gameId: Int) async throws -> AISummaryResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 180_000_000) // 180ms

        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        let homeTeam: String?
        let awayTeam: String?
        if let cachedGame = gameCache[gameId]?.game {
            homeTeam = cachedGame.homeTeam
            awayTeam = cachedGame.awayTeam
        } else if let summary = generatedGames?.first(where: { $0.id == gameId }) {
            homeTeam = summary.homeTeam
            awayTeam = summary.awayTeam
        } else {
            homeTeam = nil
            awayTeam = nil
        }

        guard let homeTeam, let awayTeam else {
            throw GameServiceError.notFound
        }

        return AISummaryResponse(summary: MockDataGenerator.generateSummary(homeTeam: homeTeam, awayTeam: awayTeam))
    }
}


