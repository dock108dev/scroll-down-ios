//
//  SimulatorAPIClient.swift
//  ScrollDown
//
//  API client for the MLB Monte Carlo simulator.
//  Follows FairBetAPIClient pattern: actor, shared singleton, X-API-Key header.
//

import Foundation

actor SimulatorAPIClient {
    static let shared = SimulatorAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private static let apiKeyHeaderName = "X-API-Key"

    init(session: URLSession = .shared) {
        self.session = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

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
            case .invalidURL: return "Invalid URL"
            case .networkError(let e): return "Network error: \(e.localizedDescription)"
            case .invalidResponse: return "Invalid server response"
            case .decodingError(let e): return "Failed to decode: \(e.localizedDescription)"
            case .serverError(let code): return "Server error: \(code)"
            case .unauthorized: return "Unauthorized"
            case .missingAPIKey: return "API key not configured"
            }
        }
    }

    // MARK: - Teams

    func fetchTeams() async throws -> MLBTeamsResponse {
        try await get(path: "/api/analytics/mlb-teams")
    }

    // MARK: - Roster

    func fetchRoster(team: String) async throws -> MLBRosterResponse {
        try await get(path: "/api/analytics/mlb-roster", queryItems: [
            URLQueryItem(name: "team", value: team)
        ])
    }

    // MARK: - Simulate

    func simulate(request: SimulationRequest) async throws -> SimulatorResult {
        try await post(path: "/api/analytics/simulate", body: request)
    }

    // MARK: - Private Helpers

    private func get<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let baseURL = AppConfig.shared.apiBaseURL
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try applyAuth(&request)

        return try await execute(request)
    }

    private func post<B: Encodable, T: Decodable>(path: String, body: B) async throws -> T {
        let baseURL = AppConfig.shared.apiBaseURL
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try applyAuth(&request)

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        return try await execute(request)
    }

    private func applyAuth(_ request: inout URLRequest) throws {
        guard let apiKey = APIConfiguration.apiKey(for: AppConfig.shared.environment) else {
            throw APIError.missingAPIKey
        }
        request.setValue(apiKey, forHTTPHeaderField: Self.apiKeyHeaderName)
    }

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
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
        if httpResponse.statusCode == 401 { throw APIError.unauthorized }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
