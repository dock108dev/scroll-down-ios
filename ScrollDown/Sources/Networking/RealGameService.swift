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
        try await request(path: "api/games/\(id)", queryItems: [])
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
        
        let response: GameListResponse = try await request(path: "api/games", queryItems: queryItems)
        
        // Client-side range filtering until backend supports it
        let filteredGames = filterGames(response.games, for: range)
        
        return GameListResponse(
            range: range.rawValue,
            games: filteredGames,
            total: filteredGames.count,
            nextOffset: nil,
            withBoxscoreCount: response.withBoxscoreCount,
            withPlayerStatsCount: response.withPlayerStatsCount,
            withOddsCount: response.withOddsCount,
            withSocialCount: response.withSocialCount,
            withPbpCount: response.withPbpCount,
            lastUpdatedAt: response.lastUpdatedAt
        )
    }
    
    /// Client-side range filtering
    private func filterGames(_ games: [GameSummary], for range: GameRange) -> [GameSummary] {
        let now = TimeService.shared.now
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-1)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let earlierEnd = yesterdayStart
        
        switch range {
        case .earlier:
            // 2+ days ago
            let historyStart = calendar.date(byAdding: .day, value: -2, to: todayStart)!
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= historyStart && date < earlierEnd
            }
        case .yesterday:
            // 1 day ago
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= yesterdayStart && date < todayStart
            }
        case .current:
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= todayStart && date <= todayEnd
            }
        case .next24:
            let windowEnd = now.addingTimeInterval(24 * 60 * 60)
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date > now && date <= windowEnd
            }
        }
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        try await request(path: "api/games/\(gameId)/pbp", queryItems: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        try await request(path: "api/games/\(gameId)/social", queryItems: [])
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        // Timeline endpoint is at /api/games/{id}/timeline (app-facing endpoint)
        try await request(path: "api/games/\(gameId)/timeline", queryItems: [])
    }

    func fetchStory(gameId: Int) async throws -> GameStoryResponse {
        try await request(path: "api/games/\(gameId)/story", queryItems: [])
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
