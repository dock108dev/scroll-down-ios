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
    /// - Returns: BetsResponse containing bets and metadata
    func fetchOdds(league: FairBetLeague? = nil, limit: Int = 500, offset: Int = 0) async throws -> BetsResponse {
        // Use ScrollDown's existing infrastructure for base URL
        let baseURL = AppConfig.shared.apiBaseURL

        guard var components = URLComponents(url: baseURL.appendingPathComponent("/api/fairbet/odds"), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "has_fair", value: "true")
        ]

        if let league = league {
            queryItems.append(URLQueryItem(name: "league", value: league.rawValue))
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
}
