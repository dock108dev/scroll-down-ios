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
        try await request(path: "api/admin/sports/games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        var queryItems = [URLQueryItem(name: "range", value: range.rawValue)]
        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }
        
        // Beta: Pass assume_now when snapshot mode is active
        #if DEBUG
        if let snapshotDate = TimeService.shared.snapshotDate {
            let isoString = ISO8601DateFormatter().string(from: snapshotDate)
            queryItems.append(URLQueryItem(name: "assume_now", value: isoString))
            logger.debug("🕐 Passing assume_now=\(isoString) to backend")
        }
        #endif
        
        // NOTE: The /games snapshot endpoint is not deployed yet on Hetzner
        // Using admin endpoint with workarounds:
        // - range param is ignored (returns all games paginated)
        // - no status field (inferred from has_required_data/scores)
        // TODO: Switch to /games when snapshot endpoint is deployed
        return try await request(path: "api/admin/sports/games", queryItems: queryItems)
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

        // #region agent log
        DebugLogger.log(hypothesisId: "A", location: "RealGameService.swift:80", message: "📡 Request URL", data: ["url": url.absoluteString])
        // #endregion

        do {
            logger.info("📡 Requesting: \(url.absoluteString, privacy: .public)")
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            logger.info("📡 Response status: \(httpResponse.statusCode, privacy: .public), bytes: \(data.count, privacy: .public)")
            guard (200..<300).contains(httpResponse.statusCode) else {
                logger.error("Request failed path=\(path, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
                throw URLError(.badServerResponse)
            }
            do {
                let result = try decoder.decode(T.self, from: data)
                logger.info("📡 Decode success for \(path, privacy: .public)")
                return result
            } catch {
                // Log the raw response for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    logger.error("📡 Decode failed. Raw response: \(jsonString.prefix(500), privacy: .public)")
                }
                logger.error("📡 Decode error: \(error.localizedDescription, privacy: .public)")
                throw error
            }
        } catch let error as DecodingError {
            logger.error("📡 DecodingError: \(String(describing: error), privacy: .public)")
            throw GameServiceError.decodingError(error)
        } catch {
            logger.error("📡 NetworkError: \(error.localizedDescription, privacy: .public)")
            throw GameServiceError.networkError(error)
        }
    }
}
