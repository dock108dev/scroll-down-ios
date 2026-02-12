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

    /// Fetch social posts for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Social post list response
    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse

    /// Fetch pre-generated timeline artifact for a game
    /// - Parameter gameId: The game ID
    /// - Returns: Timeline artifact response
    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse

    /// Fetch game flow
    /// - Parameter gameId: The game ID
    /// - Returns: Flow response with blocks and plays
    func fetchFlow(gameId: Int) async throws -> GameFlowResponse

    /// Fetch team colors for all teams
    /// - Returns: Array of team summaries with color hex values
    func fetchTeamColors() async throws -> [TeamSummary]

    /// Fetch unified timeline for a game (merged PBP + social + odds)
    /// - Parameter gameId: The game ID
    /// - Returns: Array of raw event dictionaries
    func fetchUnifiedTimeline(gameId: Int) async throws -> [[String: Any]]
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
    case unauthorized
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Game not found"
        case .unauthorized:
            return "API authentication failed - check your API key configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            if let decodingError = error as? DecodingError {
                return "Data error: \(decodingError.detailedDescription)"
            }
            return "Data error: \(error.localizedDescription)"
        }
    }
}

extension DecodingError {
    var detailedDescription: String {
        switch self {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Null value for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Corrupted data at \(context.codingPath.map(\.stringValue).joined(separator: ".")): \(context.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}
