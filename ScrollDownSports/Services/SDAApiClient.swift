import Foundation

enum SDAApiError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case incompleteNormalizedFeed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The data URL is invalid."
        case .badStatus(let status):
            if status == 404 {
                return "Game Data Not Found"
            }
            if status == 422 {
                return "Game Data Incomplete"
            }
            return "The data service returned HTTP \(status)."
        case .incompleteNormalizedFeed:
            return "Feed unavailable."
        }
    }
}

final class SDAApiClient: Sendable {
    static let shared = makeSharedClient()

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
        limit: Int = 200,
        offset: Int = 0
    ) async throws -> [Game] {
        try await fetchGamePage(window: window, league: league, limit: limit, offset: offset).games
    }

    func fetchGamePage(
        window: GameWindow,
        league: String? = nil,
        limit: Int = 200,
        offset: Int = 0
    ) async throws -> SDAGameListPage {
        var components = URLComponents(
            url: baseURL.appending(path: "/api/v1/games"),
            resolvingAgainstBaseURL: false
        )

        var queryItems = [
            URLQueryItem(name: "startDate", value: window.startDateQuery),
            URLQueryItem(name: "endDate", value: window.endDateQuery),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        if let league, !league.isEmpty {
            queryItems.append(URLQueryItem(name: "league", value: league))
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw SDAApiError.invalidURL }

        let response: SDAGameListResponseDTO = try await get(url)
        return SDAGameListPage(
            games: SDADomainMapper.games(from: response)
                .filter { window.contains($0.scheduledStart) },
            total: response.total,
            returnedCount: response.games.count
        )
    }

    func fetchGame(id: Int) async throws -> GameDetail {
        let response = try await fetchNormalizedFeedResponse(id: id)
        try validateNormalizedFeedContract(response)
        let fallbackState: GameFeedFallbackState = response.cards.isEmpty ? .safeEmpty : .none
        return SDADomainMapper.detail(from: response, fallbackState: fallbackState)
    }

    private func fetchNormalizedFeedResponse(id: Int) async throws -> SDACardFeedResponseDTO {
        var components = URLComponents(
            url: baseURL.appending(path: "/api/v1/feed/games/\(id)/cards"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "spoilerPolicy", value: "pre_reveal")]
        guard let url = components?.url else { throw SDAApiError.invalidURL }
        do {
            return try await get(url)
        } catch is DecodingError {
            throw SDAApiError.incompleteNormalizedFeed("Feed response could not decode required fields")
        }
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

    private func validateNormalizedFeedContract(_ response: SDACardFeedResponseDTO) throws {
        guard response.contractVersion >= 1 else {
            throw SDAApiError.incompleteNormalizedFeed("Unsupported feed contract")
        }
        guard response.game.gameId > 0 else {
            throw SDAApiError.incompleteNormalizedFeed("Feed game identity missing")
        }
        if response.generation.cardCount > 0 && response.cards.isEmpty {
            throw SDAApiError.incompleteNormalizedFeed("Feed card count did not match cards")
        }
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

    private static func makeSharedClient() -> SDAApiClient {
        #if DEBUG
        if AppEnvironment.uiTestFixtureName != nil {
            return SDAUITestFixtureAPI.makeClient()
        }
        #endif
        return SDAApiClient()
    }
}

private func feedGenerationStatus(from value: String) -> GameFeedGenerationStatus {
    switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
    case "no_pbp_yet", "nopbpyet":
        return .noPbpYet
    case "unsupported_sport", "unsupportedsport":
        return .unsupportedSport
    case "generation_pending", "generationpending":
        return .generationPending
    case "validation_blocked", "validationblocked":
        return .validationBlocked
    case "stale_regenerating", "staleregenerating":
        return .staleRegenerating
    case "ready":
        return .ready
    default:
        return .unknown
    }
}
