import Foundation
import OSLog

/// Real API implementation of GameService.
/// Uses the new date-based API that handles Eastern Time server-side.
final class RealGameService: GameService {

    // MARK: - Configuration
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.scrolldown.app", category: "networking")

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
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        // Use admin endpoint for full game detail (includes plays, stats, etc.)
        // App-facing /api/games/{id} only returns basic game info
        try await request(path: "api/admin/sports/games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        // Use admin endpoint which properly returns all games
        // The app endpoint /api/games has issues with date filtering
        let now = TimeService.shared.now
        let today = estCalendar.startOfDay(for: now)

        var queryItems: [URLQueryItem] = []

        // Calculate date range based on requested range
        // Admin endpoint uses startDate/endDate (camelCase)
        switch range {
        case .current:
            // Today's games
            let dateStr = dateFormatter.string(from: today)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .yesterday:
            // Yesterday's games
            let yesterday = estCalendar.date(byAdding: .day, value: -1, to: today)!
            let dateStr = dateFormatter.string(from: yesterday)
            queryItems.append(URLQueryItem(name: "startDate", value: dateStr))
            queryItems.append(URLQueryItem(name: "endDate", value: dateStr))

        case .earlier:
            // Games from 2+ days ago (last 7 days excluding yesterday)
            let twoDaysAgo = estCalendar.date(byAdding: .day, value: -2, to: today)!
            let weekAgo = estCalendar.date(byAdding: .day, value: -7, to: today)!
            queryItems.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: weekAgo)))
            queryItems.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: twoDaysAgo)))

        case .next24:
            // Tomorrow's games
            let tomorrow = estCalendar.date(byAdding: .day, value: 1, to: today)!
            let todayStr = dateFormatter.string(from: today)
            let tomorrowStr = dateFormatter.string(from: tomorrow)
            queryItems.append(URLQueryItem(name: "startDate", value: todayStr))
            queryItems.append(URLQueryItem(name: "endDate", value: tomorrowStr))
        }

        // Add league filter if specified
        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }

        // Add reasonable limit
        queryItems.append(URLQueryItem(name: "limit", value: "100"))

        logger.info("📡 Fetching games: range=\(range.rawValue, privacy: .public) league=\(league?.rawValue ?? "all", privacy: .public)")
        let response: GameListResponse = try await request(path: "api/admin/sports/games", queryItems: queryItems)
        logger.info("📡 Got \(response.games.count, privacy: .public) games")

        // Map admin response to expected format
        return GameListResponse(
            games: response.games,
            startDate: response.startDate,
            endDate: response.endDate,
            range: range.rawValue,
            lastUpdatedAt: response.lastUpdatedAt
        )
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        try await request(path: "api/games/\(gameId)/pbp", queryItems: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        try await request(path: "api/games/\(gameId)/social", queryItems: [])
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        try await request(path: "api/games/\(gameId)/timeline", queryItems: [])
    }

    func fetchStory(gameId: Int) async throws -> GameStoryResponse {
        // Use app endpoint for story (now returns snake_case format)
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
