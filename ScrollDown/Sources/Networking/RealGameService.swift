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

    /// EST calendar for date formatting (API expects dates in Eastern Time)
    private var estCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        return formatter
    }

    init(
        baseURL: URL,
        apiKey: String? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        try await request(path: "api/admin/sports/games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        let now = TimeService.shared.now
        let today = estCalendar.startOfDay(for: now)

        NSLog("📡 [fetchGames] range=%@ league=%@ now=%@ today=%@", range.rawValue, league?.rawValue ?? "nil", "\(now)", "\(today)")

        var queryItems: [URLQueryItem] = []

        switch range {
        case .current:
            let dateStr = dateFormatter.string(from: today)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .yesterday:
            let yesterday = estCalendar.date(byAdding: .day, value: -1, to: today)!
            let dateStr = dateFormatter.string(from: yesterday)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .earlier:
            let twoDaysAgo = estCalendar.date(byAdding: .day, value: -2, to: today)!
            let threeDaysAgo = estCalendar.date(byAdding: .day, value: -3, to: today)!
            queryItems.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: threeDaysAgo)))
            queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: twoDaysAgo)))

        case .tomorrow:
            let tomorrow = estCalendar.date(byAdding: .day, value: 1, to: today)!
            let dateStr = dateFormatter.string(from: tomorrow)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .next24:
            let tomorrow = estCalendar.date(byAdding: .day, value: 1, to: today)!
            let todayStr = dateFormatter.string(from: today)
            let tomorrowStr = dateFormatter.string(from: tomorrow)
            queryItems.append(URLQueryItem(name: "startDate", value: todayStr))
            queryItems.append(URLQueryItem(name: "endDate", value: tomorrowStr))
        }

        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }

        queryItems.append(URLQueryItem(name: "limit", value: "100"))

        NSLog("📡 Fetching games: range=%@ league=%@", range.rawValue, league?.rawValue ?? "all")
        logger.info("📡 Fetching games: range=\(range.rawValue, privacy: .public) league=\(league?.rawValue ?? "all", privacy: .public)")
        let response: GameListResponse = try await request(path: "api/admin/sports/games", queryItems: queryItems)
        NSLog("📡 Got %d games for range=%@", response.games.count, range.rawValue)
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
        // Note: No GET endpoint exists for timelines per API docs.
        // Timelines are generated via POST /timelines/generate/{gameId}.
        // This will fail until a GET endpoint is added or we use POST.
        try await request(path: "api/admin/sports/timelines/game/\(gameId)", queryItems: [])
    }

    func fetchFlow(gameId: Int) async throws -> GameFlowResponse {
        try await request(path: "api/admin/sports/games/\(gameId)/flow", queryItems: [])
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

        do {
            NSLog("📡 [DEBUG] Requesting: %@", url.absoluteString)
            logger.info("📡 Requesting: \(url.absoluteString, privacy: .public)")
            let (data, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            NSLog("📡 [DEBUG] Response status: %d, bytes: %d", httpResponse.statusCode, data.count)
            logger.info("📡 Response status: \(httpResponse.statusCode, privacy: .public), bytes: \(data.count, privacy: .public)")

            // Handle authentication errors specifically
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
                NSLog("📡 [DEBUG] Decode success for %@", path)
                logger.info("📡 Decode success for \(path, privacy: .public)")
                return result
            } catch {
                if let jsonString = String(data: data, encoding: .utf8) {
                    NSLog("📡 [DEBUG] Decode failed. Raw: %@", String(jsonString.prefix(1000)))
                    logger.error("📡 Decode failed. Raw response: \(jsonString.prefix(500), privacy: .public)")
                }
                NSLog("📡 [DEBUG] Decode error: %@", "\(error)")
                logger.error("📡 Decode error: \(error.localizedDescription, privacy: .public)")
                throw error
            }
        } catch let error as DecodingError {
            NSLog("📡 [DEBUG] DecodingError: %@", "\(error)")
            logger.error("📡 DecodingError: \(String(describing: error), privacy: .public)")
            throw GameServiceError.decodingError(error)
        } catch {
            NSLog("📡 [DEBUG] NetworkError: %@", "\(error)")
            logger.error("📡 NetworkError: \(error.localizedDescription, privacy: .public)")
            throw GameServiceError.networkError(error)
        }
    }
}
