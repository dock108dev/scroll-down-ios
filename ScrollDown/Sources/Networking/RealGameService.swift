import Foundation

/// Real API implementation of GameService
/// TODO: Implement actual network requests when backend is ready
final class RealGameService: GameService {
    
    // MARK: - Configuration
    private let baseURL: URL
    private let session: URLSession
    
    init(
        baseURL: URL = URL(string: "https://api.scrolldown.sports")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - GameService Implementation
    
    func fetchGame(id: Int) async throws -> GameDetailResponse {
        // TODO: Implement real API call
        // let url = baseURL.appendingPathComponent("/api/admin/sports/games/\(id)")
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode(GameDetailResponse.self, from: data)
        
        throw GameServiceError.notImplemented
    }
    
    func fetchGames(league: LeagueCode?, limit: Int, offset: Int) async throws -> GameListResponse {
        // TODO: Implement real API call
        // var components = URLComponents(url: baseURL.appendingPathComponent("/api/admin/sports/games"), resolvingAgainstBaseURL: true)!
        // var queryItems: [URLQueryItem] = [
        //     URLQueryItem(name: "limit", value: String(limit)),
        //     URLQueryItem(name: "offset", value: String(offset))
        // ]
        // if let league = league {
        //     queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        // }
        // components.queryItems = queryItems
        // let (data, _) = try await session.data(from: components.url!)
        // return try JSONDecoder().decode(GameListResponse.self, from: data)
        
        throw GameServiceError.notImplemented
    }
    
    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        // TODO: Implement real API call
        // let url = baseURL.appendingPathComponent("/api/pbp/game/\(gameId)")
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode(PbpResponse.self, from: data)
        
        throw GameServiceError.notImplemented
    }

    func fetchCompactMomentPbp(momentId: StringOrInt) async throws -> PbpResponse {
        // TODO: Implement real API call
        // let url = baseURL.appendingPathComponent("/compact/\(momentId.stringValue)/pbp")
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode(PbpResponse.self, from: data)

        throw GameServiceError.notImplemented
    }
    
    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        // TODO: Implement real API call
        // var components = URLComponents(url: baseURL.appendingPathComponent("/api/social/posts"), resolvingAgainstBaseURL: true)!
        // components.queryItems = [URLQueryItem(name: "game_id", value: String(gameId))]
        // let (data, _) = try await session.data(from: components.url!)
        // return try JSONDecoder().decode(SocialPostListResponse.self, from: data)
        
        throw GameServiceError.notImplemented
    }

    func fetchSummary(gameId: Int) async throws -> AISummaryResponse {
        // TODO: Implement real API call
        // let url = baseURL.appendingPathComponent("/summary").appendingPathComponent(String(gameId))
        // let (data, _) = try await session.data(from: url)
        // return try JSONDecoder().decode(AISummaryResponse.self, from: data)

        throw GameServiceError.notImplemented
    }
}
