import Foundation

enum SDAApiError: LocalizedError {
    case invalidURL
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The data URL is invalid."
        case .badStatus(let status):
            return "The data service returned HTTP \(status)."
        }
    }
}

final class SDAApiClient: Sendable {
    static let shared = SDAApiClient()

    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String

    init(
        baseURL: URL = SDAApiClient.configuredBaseURL(),
        apiKey: String = SDAApiClient.configuredAPIKey(),
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    func fetchGames(
        window: GameWindow,
        league: String? = nil,
        limit: Int = 200
    ) async throws -> [GameSummary] {
        var components = URLComponents(
            url: baseURL.appending(path: "/api/admin/sports/games"),
            resolvingAgainstBaseURL: false
        )

        var queryItems = [
            URLQueryItem(name: "startDate", value: window.startDateQuery),
            URLQueryItem(name: "endDate", value: window.endDateQuery),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let league, !league.isEmpty {
            queryItems.append(URLQueryItem(name: "league", value: league))
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw SDAApiError.invalidURL }

        let response: GameListResponse = try await get(url)
        return response.games.filter { window.contains($0.gameDate) }
    }

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        let url = baseURL.appending(path: "/api/admin/sports/games/\(id)")
        return try await get(url)
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SDAApiError.badStatus(-1)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SDAApiError.badStatus(httpResponse.statusCode)
        }
        return try JSONDecoder.sda.decode(T.self, from: data)
    }

    private static func configuredBaseURL() -> URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "SDABaseURL") as? String
        let sanitized = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.flatMap(URL.init(string:)) ?? URL(string: "https://sda.dock108.dev")!
    }

    private static func configuredAPIKey() -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: "SDAApiKey") as? String ?? ""
        let sanitized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if sanitized.isEmpty || sanitized.hasPrefix("$(") {
            return ""
        }
        return sanitized
    }
}
