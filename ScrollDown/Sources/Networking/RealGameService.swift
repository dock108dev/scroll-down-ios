import Foundation

/// Real API implementation of GameService.
/// Uses a not-yet-implemented backend while the service is under development.
final class RealGameService: GameService {

    // MARK: - Configuration
    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = Self.defaultBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        throw GameServiceError.notImplemented
    }

    func fetchGames(league: LeagueCode?, limit: Int, offset: Int) async throws -> GameListResponse {
        throw GameServiceError.notImplemented
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        throw GameServiceError.notImplemented
    }

    func fetchCompactMomentPbp(momentId: StringOrInt) async throws -> PbpResponse {
        throw GameServiceError.notImplemented
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        throw GameServiceError.notImplemented
    }

    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse {
        throw GameServiceError.notImplemented
    }

    func fetchSummary(gameId: Int) async throws -> AISummaryResponse {
        throw GameServiceError.notImplemented
    }
}

private extension RealGameService {
    static let defaultBaseURL: URL = URL(string: "https://api.scrolldown.sports")!
}
