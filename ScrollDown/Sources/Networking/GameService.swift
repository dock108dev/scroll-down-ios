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

    /// Fetch pre-generated timeline artifact for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Timeline artifact response
    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse

    /// Fetch related posts for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Related post list response
    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse
    
    /// Fetch moments for a game
    /// Moments partition the entire game timeline - every play belongs to exactly one moment
    /// - Parameter gameId: The game ID
    /// - Returns: Moments response with all moments for the game
    func fetchMoments(gameId: Int) async throws -> MomentsResponse
}

// MARK: - Reveal Level
/// Backend-provided reveal level for social posts
/// Used to filter posts based on outcome visibility preference
enum RevealLevel: String, Codable {
    case pre  // Safe to show before outcome reveal
    case post // Only show after outcome reveal
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
