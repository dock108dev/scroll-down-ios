import Foundation

/// Protocol defining the game data service interface
/// All screens depend on this protocol for data, allowing easy swapping between mock and real implementations
protocol GameService {
    /// Fetch a single game by ID
    /// - Parameter id: The game ID
    /// - Returns: Full game detail response
    func fetchGame(id: Int) async throws -> GameDetailResponse
    
    /// Fetch list of games for a snapshot range.
    /// - Parameters:
    ///   - range: Backend-defined time window
    ///   - league: Optional league filter
    /// - Returns: Game list response with summaries
    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse
    
    /// Fetch play-by-play events for a game
    /// - Parameter gameId: The game ID
    /// - Returns: PBP response with events
    func fetchPbp(gameId: Int) async throws -> PbpResponse

    /// Fetch play-by-play slice for a compact moment
    /// - Parameter momentId: The compact moment ID
    /// - Returns: PBP response with events
    func fetchCompactMomentPbp(momentId: StringOrInt) async throws -> PbpResponse
    
    /// Fetch social posts for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Social post list response
    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse

    /// Fetch related posts for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Related post list response
    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse

    /// Fetch AI summary for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Summary response
    func fetchSummary(gameId: Int) async throws -> AISummaryResponse
}

// MARK: - Service Errors
enum GameServiceError: LocalizedError {
    case notFound
    case networkError(Error)
    case decodingError(Error)
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Game not found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        case .notImplemented:
            return "This feature is not yet implemented"
        }
    }
}
