import Foundation

enum SDAApiError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case incompleteDetail(String)

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
        case .incompleteDetail:
            return "Game Data Incomplete"
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
        limit: Int = 200
    ) async throws -> [Game] {
        var components = URLComponents(
            url: baseURL.appending(path: "/api/v1/games"),
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

        let response: SDAGameListResponseDTO = try await get(url)
        return SDADomainMapper.games(from: response)
            .filter { window.contains($0.scheduledStart) }
    }

    func fetchGame(id: Int) async throws -> GameDetail {
        let url = baseURL.appending(path: "/api/v1/games/\(id)")
        let response: SDAGameDetailResponseDTO
        do {
            response = try await get(url)
        } catch is DecodingError {
            throw SDAApiError.incompleteDetail("Detail response could not decode required v2 fields")
        }
        try validateGameDetailContract(response)
        return SDADomainMapper.detail(from: response)
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

    private func validateGameDetailContract(_ response: SDAGameDetailResponseDTO) throws {
        guard response.detailContractVersion >= 2 else {
            throw SDAApiError.incompleteDetail("Unsupported detail contract")
        }
        for play in response.plays {
            guard play.modeEligibility.all else {
                throw SDAApiError.incompleteDetail("modeEligibility.all missing or false")
            }
            guard !play.displayType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SDAApiError.incompleteDetail("displayType missing")
            }
            guard !play.periodLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SDAApiError.incompleteDetail("periodLabel missing")
            }
            guard hasUsableEventText(play) else {
                throw SDAApiError.incompleteDetail("play text missing")
            }
        }
    }

    private func hasUsableEventText(_ play: SDAPlayDTO) -> Bool {
        [
            play.presentation?.headline,
            play.presentation?.body,
            play.description
        ].contains { EventLabelResolver.customerText(from: $0) != nil }
            || EventLabelResolver.customerLabel(from: play.displayType) != nil
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
