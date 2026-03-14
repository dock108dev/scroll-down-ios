//
//  FairBetAPIClient.swift
//  ScrollDown
//
//  Networking layer for fetching odds from the FairBet API.
//  Uses ScrollDown's existing APIConfiguration for base URL and API key.
//

import Foundation

/// API client for fetching betting odds
actor FairBetAPIClient {
    static let shared = FairBetAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    /// API key header name
    private static let apiKeyHeaderName = "X-API-Key"

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - Parlay Types

    struct ParlayLeg: Codable {
        let gameId: Int
        let marketKey: String
        let selectionKey: String
        let lineValue: Double?

        enum CodingKeys: String, CodingKey {
            case gameId = "game_id"
            case marketKey = "market_key"
            case selectionKey = "selection_key"
            case lineValue = "line_value"
        }
    }

    struct ParlayEvaluation: Codable {
        let fairProbability: Double
        let fairAmericanOdds: Int
        let confidence: String
        let legCount: Int

        enum CodingKeys: String, CodingKey {
            case fairProbability = "fair_probability"
            case fairAmericanOdds = "fair_american_odds"
            case confidence
            case legCount = "leg_count"
        }
    }

    /// Errors that can occur during API calls
    enum APIError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case decodingError(Error)
        case serverError(Int)
        case unauthorized
        case missingAPIKey

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid server response"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .serverError(let code):
                return "Server error: \(code)"
            case .unauthorized:
                return "Unauthorized: Invalid or missing API key"
            case .missingAPIKey:
                return "API key not configured"
            }
        }
    }

    /// Fetch odds from the API
    /// - Parameters:
    ///   - league: Optional league filter (NBA, NHL, NCAAB)
    ///   - limit: Number of results per page (default 500, max 500)
    ///   - offset: Number of results to skip (default 0)
    ///   - marketCategory: Optional market category filter
    ///   - gameId: Optional game ID filter
    ///   - minEV: Optional minimum EV threshold
    ///   - sortBy: Optional sort field
    ///   - playerName: Optional player name filter
    ///   - book: Optional book filter
    ///   - hasFair: Optional has_fair filter (defaults to true)
    /// - Returns: BetsResponse containing bets and metadata
    func fetchOdds(
        league: FairBetLeague? = nil,
        limit: Int = 500,
        offset: Int = 0,
        marketCategory: String? = nil,
        gameId: Int? = nil,
        minEV: Double? = nil,
        sortBy: String? = nil,
        playerName: String? = nil,
        book: String? = nil,
        hasFair: Bool? = true
    ) async throws -> BetsResponse {
        // Use ScrollDown's existing infrastructure for base URL
        let baseURL = AppConfig.shared.apiBaseURL

        guard var components = URLComponents(url: baseURL.appendingPathComponent("/api/fairbet/odds"), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        if let hasFair {
            queryItems.append(URLQueryItem(name: "has_fair", value: String(hasFair)))
        }

        if let league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
        }

        if let marketCategory {
            queryItems.append(URLQueryItem(name: "market_category", value: marketCategory))
        }

        if let gameId {
            queryItems.append(URLQueryItem(name: "game_id", value: String(gameId)))
        }

        if let minEV {
            queryItems.append(URLQueryItem(name: "min_ev", value: String(minEV)))
        }

        if let sortBy {
            queryItems.append(URLQueryItem(name: "sort_by", value: sortBy))
        }

        if let playerName {
            queryItems.append(URLQueryItem(name: "player_name", value: playerName))
        }

        if let book {
            queryItems.append(URLQueryItem(name: "book", value: book))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        // Use ScrollDown's existing API key infrastructure
        guard let apiKey = APIConfiguration.apiKey(for: AppConfig.shared.environment) else {
            throw APIError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeaderName)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(BetsResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Live Odds

    /// Fetch live games that have in-play odds
    func fetchLiveGames(league: FairBetLeague? = nil) async throws -> [LiveGameInfo] {
        let baseURL = AppConfig.shared.apiBaseURL
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/api/fairbet/live/games"), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        if let league {
            components.queryItems = [URLQueryItem(name: "league", value: league.rawValue)]
        }
        guard let url = components.url else { throw APIError.invalidURL }
        guard let apiKey = APIConfiguration.apiKey(for: AppConfig.shared.environment) else {
            throw APIError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeaderName)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if httpResponse.statusCode == 401 { throw APIError.unauthorized }
        guard (200...299).contains(httpResponse.statusCode) else { throw APIError.serverError(httpResponse.statusCode) }

        do {
            return try decoder.decode([LiveGameInfo].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Fetch live odds for a specific game
    func fetchLiveOdds(gameId: Int) async throws -> FairbetLiveResponse {
        let baseURL = AppConfig.shared.apiBaseURL
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/api/fairbet/live"), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "game_id", value: String(gameId))]
        guard let url = components.url else { throw APIError.invalidURL }
        guard let apiKey = APIConfiguration.apiKey(for: AppConfig.shared.environment) else {
            throw APIError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeaderName)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if httpResponse.statusCode == 401 { throw APIError.unauthorized }
        guard (200...299).contains(httpResponse.statusCode) else { throw APIError.serverError(httpResponse.statusCode) }

        do {
            return try decoder.decode(FairbetLiveResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Evaluate a parlay via the API
    /// - Parameter legs: The parlay legs to evaluate
    /// - Returns: ParlayEvaluation with fair probability and odds
    func evaluateParlay(legs: [ParlayLeg]) async throws -> ParlayEvaluation {
        let baseURL = AppConfig.shared.apiBaseURL

        guard let url = URL(string: "/api/fairbet/parlay/evaluate", relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        guard let apiKey = APIConfiguration.apiKey(for: AppConfig.shared.environment) else {
            throw APIError.missingAPIKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeaderName)

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(["legs": legs])

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(ParlayEvaluation.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
