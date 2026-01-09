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
    
    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
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

        games = filterGames(games, for: range)
        
        return GameListResponse(
            games: games,
            total: games.count,
            nextOffset: nil,
            withBoxscoreCount: games.filter { $0.hasBoxscore == true }.count,
            withPlayerStatsCount: games.filter { $0.hasPlayerStats == true }.count,
            withOddsCount: games.filter { $0.hasOdds == true }.count,
            withSocialCount: games.filter { $0.hasSocial == true }.count,
            withPbpCount: games.filter { $0.hasPbp == true }.count,
            lastUpdatedAt: ISO8601DateFormatter().string(from: AppDate.now())
        )
    }

    private func filterGames(_ games: [GameSummary], for range: GameRange) -> [GameSummary] {
        let todayStart = AppDate.startOfToday
        let todayEnd = AppDate.endOfToday

        switch range {
        case .last2:
            let historyStart = AppDate.historyWindowStart
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= historyStart && date < todayStart
            }
        case .current:
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= todayStart && date <= todayEnd
            }
        case .next24:
            let now = AppDate.now()
            let windowEnd = now.addingTimeInterval(24 * 60 * 60)
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date > now && date <= windowEnd
            }
        }
    }
    
    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Use cached detail if available to ensure consistency
        if let detail = gameCache[gameId] {
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }
        
        // Try to generate detail if not in cache
        if let gameSummary = findOrGenerateSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }
        
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
        
        // Use cached detail if available
        if let detail = gameCache[gameId] {
            let posts = detail.socialPosts.map { entry in
                SocialPostResponse(
                    id: entry.id,
                    gameId: gameId,
                    teamId: entry.teamAbbreviation,
                    postUrl: entry.postUrl,
                    postedAt: entry.postedAt,
                    hasVideo: entry.hasVideo,
                    videoUrl: entry.videoUrl,
                    imageUrl: entry.imageUrl,
                    tweetText: entry.tweetText,
                    sourceHandle: entry.sourceHandle,
                    mediaType: entry.mediaType,
                    revealLevel: .pre
                )
            }
            return SocialPostListResponse(
                posts: posts,
                total: posts.count
            )
        }
        
        // Try to generate detail if not in cache
        if let gameSummary = findOrGenerateSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return try await fetchSocialPosts(gameId: gameId)
        }
        
        return MockLoader.load("social-posts")
    }

    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        return MockLoader.load("related-posts")
    }

    func fetchSummary(gameId: Int, reveal: RevealLevel) async throws -> AISummaryResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 180_000_000) // 180ms

        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        let homeTeam: String?
        let awayTeam: String?
        let homeScore: Int?
        let awayScore: Int?
        
        if let cachedGame = gameCache[gameId]?.game {
            homeTeam = cachedGame.homeTeam
            awayTeam = cachedGame.awayTeam
            homeScore = cachedGame.homeScore
            awayScore = cachedGame.awayScore
        } else if let summary = generatedGames?.first(where: { $0.id == gameId }) {
            homeTeam = summary.homeTeam
            awayTeam = summary.awayTeam
            homeScore = summary.homeScore
            awayScore = summary.awayScore
        } else {
            homeTeam = nil
            awayTeam = nil
            homeScore = nil
            awayScore = nil
        }

        guard let homeTeam, let awayTeam else {
            throw GameServiceError.notFound
        }

        return AISummaryResponse(
            summary: MockDataGenerator.generateSummary(
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                homeScore: homeScore,
                awayScore: awayScore,
                reveal: reveal
            )
        )
    }

    // MARK: - Helpers

    private func findOrGenerateSummary(for gameId: Int) -> GameSummary? {
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }
        return generatedGames?.first(where: { $0.id == gameId })
    }

    private func mapPlaysToEvents(_ plays: [PlayEntry], gameId: Int) -> [PbpEvent] {
        plays.map { play in
            PbpEvent(
                id: .int(play.playIndex),
                gameId: .int(gameId),
                period: play.quarter,
                gameClock: play.gameClock,
                elapsedSeconds: nil,
                eventType: play.playType?.rawValue,
                description: play.description,
                team: play.teamAbbreviation,
                teamId: nil,
                playerName: play.playerName,
                playerId: nil,
                homeScore: play.homeScore,
                awayScore: play.awayScore
            )
        }
    }
}
