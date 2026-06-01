import Foundation

enum SDAApiError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case incompleteNormalizedFeed(String)
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
        case .incompleteNormalizedFeed:
            return "Feed unavailable."
        case .incompleteDetail:
            return "Game Data Incomplete"
        }
    }
}

enum SDAGameDetailFetchMode: Sendable {
    case normalizedWithLegacyFallback
    case legacyOnly
}

final class SDAApiClient: Sendable {
    static let shared = makeSharedClient()

    private let session: URLSession
    private let baseURL: URL
    private let apiKey: String
    private let gameDetailFetchMode: SDAGameDetailFetchMode

    init(
        baseURL: URL = SDAApiClient.configuredBaseURL(),
        apiKey: String = SDAApiClient.configuredAPIKey(),
        session: URLSession = .shared,
        gameDetailFetchMode: SDAGameDetailFetchMode = .normalizedWithLegacyFallback
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
        self.gameDetailFetchMode = gameDetailFetchMode
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
        switch gameDetailFetchMode {
        case .legacyOnly:
            return try await fetchLegacyGame(id: id)
        case .normalizedWithLegacyFallback:
            return try await fetchMigratingGame(id: id)
        }
    }

    private func fetchMigratingGame(id: Int) async throws -> GameDetail {
        do {
            let response = try await fetchNormalizedFeedResponse(id: id)
            try validateNormalizedFeedContract(response)
            let status = feedGenerationStatus(from: response.generation.status)
            if shouldUseLegacyFallback(for: response) {
                return try await fetchLegacyGame(
                    id: id,
                    fallbackMetadata: GameDetailFeedMetadata(
                        source: .legacyDetail,
                        generationStatus: status,
                        fallbackState: .legacyDetail,
                        revealAvailable: response.reveal.available,
                        revealRequiredForScores: response.reveal.revealRequiredForScores
                    )
                )
            }
            let fallbackState: GameFeedFallbackState = response.cards.isEmpty ? .safeEmpty : .none
            return SDADomainMapper.detail(from: response, fallbackState: fallbackState)
        } catch SDAApiError.incompleteNormalizedFeed {
            return try await fetchLegacyGame(
                id: id,
                fallbackMetadata: GameDetailFeedMetadata(
                    source: .legacyDetail,
                    generationStatus: .unknown,
                    fallbackState: .legacyDetail,
                    revealAvailable: false,
                    revealRequiredForScores: true
                )
            )
        } catch {
            return try await fetchLegacyGame(
                id: id,
                fallbackMetadata: GameDetailFeedMetadata(
                    source: .legacyDetail,
                    generationStatus: .unknown,
                    fallbackState: .legacyDetail,
                    revealAvailable: false,
                    revealRequiredForScores: true
                )
            )
        }
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

    private func fetchLegacyGame(
        id: Int,
        fallbackMetadata: GameDetailFeedMetadata? = nil
    ) async throws -> GameDetail {
        let url = baseURL.appending(path: "/api/v1/games/\(id)")
        let response: SDAGameDetailResponseDTO
        do {
            response = try await get(url)
        } catch is DecodingError {
            throw SDAApiError.incompleteDetail("Detail response could not decode required v2 fields")
        }
        try validateGameDetailContract(response)
        let detail = SDADomainMapper.detail(from: response)
        return fallbackMetadata.map { detail.withFeedMetadata($0) } ?? detail
    }

    private func shouldUseLegacyFallback(for response: SDACardFeedResponseDTO) -> Bool {
        let status = feedGenerationStatus(from: response.generation.status)
        if status == .unsupportedSport {
            return true
        }
        if response.cards.isEmpty && (status == .validationBlocked || status == .staleRegenerating) {
            return true
        }
        return false
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
