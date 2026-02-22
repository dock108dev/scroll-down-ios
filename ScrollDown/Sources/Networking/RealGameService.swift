import Foundation
import OSLog

/// Real API implementation of GameService using admin endpoints.
final class RealGameService: GameService {

    // MARK: - Configuration
    private let baseURL: URL
    private let apiKey: String?
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.scrolldown.app", category: "networking")

    /// HTTP header name for API key authentication
    private static let apiKeyHeader = "X-API-Key"

    /// Shared formatters for date/calendar operations (API expects Eastern Time)
    private enum Formatting {
        static let estCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "America/New_York")!
            return calendar
        }()

        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "America/New_York")!
            return formatter
        }()
    }

    /// URLError codes that are safe to retry (transient network failures)
    private static let retryableCodes: Set<URLError.Code> = [
        .timedOut, .networkConnectionLost, .notConnectedToInternet,
        .cannotFindHost, .cannotConnectToHost
    ]

    init(
        baseURL: URL,
        apiKey: String? = nil,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            self.session = URLSession(configuration: config)
        }
        self.decoder = JSONDecoder()
    }

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        try await request(path: "api/admin/sports/games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        let now = TimeService.shared.now
        let today = Formatting.estCalendar.startOfDay(for: now)

        var queryItems: [URLQueryItem] = []

        switch range {
        case .current:
            let dateStr = Formatting.dateFormatter.string(from: today)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .yesterday:
            guard let yesterday = Formatting.estCalendar.date(byAdding: .day, value: -1, to: today) else {
                throw GameServiceError.networkError(URLError(.unknown))
            }
            let dateStr = Formatting.dateFormatter.string(from: yesterday)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .earlier:
            guard let twoDaysAgo = Formatting.estCalendar.date(byAdding: .day, value: -2, to: today),
                  let threeDaysAgo = Formatting.estCalendar.date(byAdding: .day, value: -3, to: today) else {
                throw GameServiceError.networkError(URLError(.unknown))
            }
            queryItems.append(URLQueryItem(name: "startDate", value: Formatting.dateFormatter.string(from: threeDaysAgo)))
            queryItems.append(URLQueryItem(name: "endDate", value: Formatting.dateFormatter.string(from: twoDaysAgo)))

        case .tomorrow:
            guard let tomorrow = Formatting.estCalendar.date(byAdding: .day, value: 1, to: today) else {
                throw GameServiceError.networkError(URLError(.unknown))
            }
            let dateStr = Formatting.dateFormatter.string(from: tomorrow)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .next24:
            guard let tomorrow = Formatting.estCalendar.date(byAdding: .day, value: 1, to: today) else {
                throw GameServiceError.networkError(URLError(.unknown))
            }
            let todayStr = Formatting.dateFormatter.string(from: today)
            let tomorrowStr = Formatting.dateFormatter.string(from: tomorrow)
            queryItems.append(URLQueryItem(name: "startDate", value: todayStr))
            queryItems.append(URLQueryItem(name: "endDate", value: tomorrowStr))
        }

        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }

        queryItems.append(URLQueryItem(name: "limit", value: "200"))

        logger.info("📡 Fetching games: range=\(range.rawValue, privacy: .public) league=\(league?.rawValue ?? "all", privacy: .public)")
        let response: GameListResponse = try await request(path: "api/admin/sports/games", queryItems: queryItems)
        logger.info("📡 Got \(response.games.count, privacy: .public) games")

        return GameListResponse(
            games: response.games,
            startDate: response.startDate,
            endDate: response.endDate,
            range: range.rawValue,
            lastUpdatedAt: response.lastUpdatedAt
        )
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        try await request(path: "api/admin/sports/pbp/game/\(gameId)", queryItems: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        try await request(path: "api/social/posts/game/\(gameId)", queryItems: [])
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        try await request(path: "api/admin/sports/games/\(gameId)/timeline", queryItems: [])
    }

    func fetchFlow(gameId: Int) async throws -> GameFlowResponse {
        try await request(path: "api/admin/sports/games/\(gameId)/flow", queryItems: [])
    }

    func fetchTeamColors() async throws -> [TeamSummary] {
        let response: TeamListResponse = try await request(path: "api/admin/sports/teams", queryItems: [])
        return response.teams
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

        // Build URLRequest with authentication header
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        if let apiKey = apiKey {
            urlRequest.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeader)
        }

        return try await requestWithRetry(urlRequest, path: path)
    }

    /// Execute a URLRequest with automatic retry for transient network failures.
    /// Max 2 retries with exponential backoff (1s, 2s).
    private func requestWithRetry<T: Decodable>(_ urlRequest: URLRequest, path: String, maxRetries: Int = 2) async throws -> T {
        var lastError: Error?

        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = UInt64(attempt) * 1_000_000_000 // 1s, 2s
                logger.info("📡 Retry \(attempt, privacy: .public)/\(maxRetries, privacy: .public) for \(path, privacy: .public)")
                try await Task.sleep(nanoseconds: delay)
            }

            do {
                logger.info("📡 Requesting: \(urlRequest.url?.absoluteString ?? "nil", privacy: .public)")
                let (data, response) = try await session.data(for: urlRequest)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                logger.info("📡 Response status: \(httpResponse.statusCode, privacy: .public), bytes: \(data.count, privacy: .public)")

                if httpResponse.statusCode == 401 {
                    logger.error("📡 Authentication failed - missing or invalid API key")
                    throw GameServiceError.unauthorized
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    logger.error("Request failed path=\(path, privacy: .public) status=\(httpResponse.statusCode, privacy: .public)")
                    throw URLError(.badServerResponse)
                }
                do {
                    let result = try decoder.decode(T.self, from: data)
                    logger.info("📡 Decode success for \(path, privacy: .public)")
                    return result
                } catch {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        logger.error("📡 Decode failed. Raw response: \(jsonString.prefix(500), privacy: .public)")
                    }
                    logger.error("📡 Decode error: \(error.localizedDescription, privacy: .public)")
                    throw error
                }
            } catch let error as URLError where Self.retryableCodes.contains(error.code) && attempt < maxRetries {
                lastError = error
                logger.warning("📡 Retryable error: \(error.localizedDescription, privacy: .public)")
                continue
            } catch let error as DecodingError {
                logger.error("📡 DecodingError: \(String(describing: error), privacy: .public)")
                throw GameServiceError.decodingError(error)
            } catch {
                logger.error("📡 NetworkError: \(error.localizedDescription, privacy: .public)")
                throw GameServiceError.networkError(error)
            }
        }

        // Should only reach here if all retries exhausted
        throw GameServiceError.networkError(lastError ?? URLError(.unknown))
    }
}
