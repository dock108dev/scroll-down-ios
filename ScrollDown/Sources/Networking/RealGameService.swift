import Foundation
import OSLog

/// Real API implementation of GameService.
///
/// ## Why We Use Admin Endpoints (January 2026)
///
/// The app currently uses `/api/admin/sports/*` endpoints instead of the app-facing
/// `/api/*` endpoints for the following reasons:
///
/// 1. **App endpoints have bugs/issues:**
///    - `/api/games` returns empty results for date filtering
///    - `/api/games/{id}/story` returns HTTP 500 errors
///    - `/api/games/{id}/timeline` returns HTTP 404 for most games
///
/// 2. **Admin endpoints are more reliable:**
///    - `/api/admin/sports/games` properly returns all games with date filtering
///    - `/api/admin/sports/games/{id}` returns complete game detail with plays, stats, etc.
///    - `/api/admin/sports/games/{id}/story` returns story data correctly
///
/// 3. **Response format differences:**
///    - Admin uses camelCase (startDate, gameId, scoreBefore)
///    - App uses snake_case (start_date, game_id, score_before)
///    - Our models handle both formats via custom decoders
///
/// ## TODO: Switch back to app endpoints when fixed
/// Once the backend app endpoints are fixed, we should:
/// 1. Switch back to `/api/*` endpoints
/// 2. Remove admin endpoint usage
/// 3. Simplify model decoders to expect only snake_case
///
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
        // Admin endpoint: includes plays, stats, social posts, odds
        // App endpoint /api/games/{id} only returns basic game info
        try await request(path: "api/admin/sports/games/\(id)", queryItems: [])
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        // Admin endpoint: properly returns all games with date filtering
        // App endpoint /api/games has issues returning empty results
        let now = TimeService.shared.now
        let today = estCalendar.startOfDay(for: now)

        NSLog("📡 [fetchGames] range=%@ league=%@ now=%@ today=%@", range.rawValue, league?.rawValue ?? "nil", "\(now)", "\(today)")

        var queryItems: [URLQueryItem] = []

        // Calculate date range based on requested range
        // Admin endpoint uses camelCase: startDate/endDate
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

        NSLog("📡 Fetching games: range=%@ league=%@", range.rawValue, league?.rawValue ?? "all")
        logger.info("📡 Fetching games: range=\(range.rawValue, privacy: .public) league=\(league?.rawValue ?? "all", privacy: .public)")
        let response: GameListResponse = try await request(path: "api/admin/sports/games", queryItems: queryItems)
        NSLog("📡 Got %d games for range=%@", response.games.count, range.rawValue)
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
        // App endpoint for PBP - no admin equivalent for this specific endpoint
        // The admin /games/{id} endpoint includes plays, but this is called separately
        // for fallback or direct PBP-only fetches
        try await request(path: "api/games/\(gameId)/pbp", queryItems: [])
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        // App endpoint for social - the admin /games/{id} includes social posts
        // but this is called separately for fallback or direct social-only fetches
        try await request(path: "api/games/\(gameId)/social", queryItems: [])
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        // App endpoint for timeline - returns 404 for most games currently
        // Timeline artifacts are generated via admin pipeline and stored
        try await request(path: "api/games/\(gameId)/timeline", queryItems: [])
    }

    func fetchStory(gameId: Int) async throws -> GameStoryResponse {
        // Admin endpoint: returns story correctly
        // App endpoint /api/games/{id}/story returns HTTP 500
        try await request(path: "api/admin/sports/games/\(gameId)/story", queryItems: [])
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
            NSLog("📡 [DEBUG] Requesting: %@", url.absoluteString)
            logger.info("📡 Requesting: \(url.absoluteString, privacy: .public)")
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            NSLog("📡 [DEBUG] Response status: %d, bytes: %d", httpResponse.statusCode, data.count)
            logger.info("📡 Response status: \(httpResponse.statusCode, privacy: .public), bytes: \(data.count, privacy: .public)")
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
                // Log the raw response for debugging
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
