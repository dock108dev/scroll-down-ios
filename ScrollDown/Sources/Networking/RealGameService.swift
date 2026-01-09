import Foundation
import OSLog

/// Real API implementation of GameService.
final class RealGameService: GameService {

    // MARK: - Configuration
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.scrolldown.app", category: "networking")

    init(
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        try await request(path: "games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        var queryItems = [URLQueryItem(name: "range", value: range.rawValue)]
        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }
        // Trust backend snapshot windows for ordering and membership; avoid client-side guessing.
        return try await request(path: "games", queryItems: queryItems)
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

    func fetchSummary(gameId: Int, reveal: RevealLevel) async throws -> AISummaryResponse {
        let queryItems = [URLQueryItem(name: "reveal", value: reveal.rawValue)]
        return try await request(path: "games/\(gameId)/summary", queryItems: queryItems)
    }

    // MARK: - Networking

    private func request<T: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw GameServiceError.notFound
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw GameServiceError.notFound
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                logger.error("Request failed path=\(path, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
                throw URLError(.badServerResponse)
            }
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw GameServiceError.decodingError(error)
        } catch {
            throw GameServiceError.networkError(error)
        }
    }
}
