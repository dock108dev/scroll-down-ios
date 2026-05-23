import Foundation
@testable import ScrollDownSports

enum TestFixtures {
    static func makeAPIClient(
        responses: [MockHTTPResponse],
        protocolClass: MockHTTPURLProtocol.Type
    ) -> SDAApiClient {
        MockHTTPURLProtocol.setResponses(responses, for: protocolClass)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return SDAApiClient(
            baseURL: URL(string: "https://example.test")!,
            apiKey: "",
            session: URLSession(configuration: configuration)
        )
    }

    static func fixedDate(_ value: String = "2026-05-22T16:00:00Z") -> Date {
        ISO8601DateFormatter().date(from: value) ?? Date(timeIntervalSince1970: 0)
    }

    static func makeGame(
        id: Int = 42,
        leagueCode: String = "mlb",
        scheduledStart: Date = fixedDate("2026-05-22T23:10:00Z"),
        status: String = "in_progress",
        isLive: Bool? = true,
        isFinal: Bool? = nil,
        awayName: String = "New York Yankees",
        awayAbbreviation: String? = "NYY",
        homeName: String = "Seattle Mariners",
        homeAbbreviation: String? = "SEA",
        awayScore: Int? = 1,
        homeScore: Int? = 2,
        eventCount: Int? = 12,
        periodOrdinal: Int? = 1,
        periodLabel: String? = "T4",
        clockLabel: String? = "1 out",
        hasTimeline: Bool = true,
        hasStats: Bool = true,
        hasScoreboard: Bool = true,
        presentation: GamePresentationData? = nil,
        scoreboard: GameScoreboardData? = nil
    ) -> Game {
        let participants = [
            GameParticipant(id: "away-\(id)", role: .away, name: awayName, abbreviation: awayAbbreviation),
            GameParticipant(id: "home-\(id)", role: .home, name: homeName, abbreviation: homeAbbreviation)
        ]
        return Game(
            id: id,
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            scheduledStart: scheduledStart,
            localDateLabel: "2026-05-22",
            status: GameStatus(rawValue: status, isLiveOverride: isLive, isFinalOverride: isFinal),
            participants: participants,
            scoreState: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: participants[0].id, participantRole: .away, score: awayScore),
                    ParticipantScore(participantID: participants[1].id, participantRole: .home, score: homeScore)
                ]
            ),
            presentation: presentation,
            scoreboard: scoreboard,
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: periodOrdinal,
                periodLabel: periodLabel,
                clockLabel: clockLabel,
                eventCount: eventCount,
                lastReadEventID: nil,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: nil,
                restoredAt: nil,
                persistence: nil
            ),
            availableFeatures: GameAvailableFeatures(
                hasTimeline: hasTimeline,
                hasStats: hasStats,
                hasScoreboard: hasScoreboard
            )
        )
    }

    static func makeEvent(
        sequence: Int,
        sourceEventID: String? = nil,
        importance: GameEventImportance = .contextual,
        headline: String? = nil,
        detail: String? = nil,
        periodOrdinal: Int? = 1,
        periodLabel: String? = "Q1",
        clockLabel: String? = "10:00",
        scoreDelta: ScoreDelta? = nil,
        eventType: String = "play",
        eligibleModes: Set<GameMode>? = nil,
        usesBackendModeEligibility: Bool = true,
        presentation: EventPresentationData? = nil,
        importanceMetadata: EventImportanceData? = nil,
        rawFeedSource: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        sportMetadata: [String: JSONValue] = [:]
    ) -> GameEvent {
        GameEvent(
            id: sourceEventID ?? "event-\(sequence)",
            sourceEventID: sourceEventID,
            sequence: sequence,
            periodOrdinal: periodOrdinal,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            teamOwnership: .home,
            teamAbbreviation: "SEA",
            eventType: eventType,
            importance: importance,
            eligibleModes: eligibleModes ?? Self.eligibleModes(for: importance),
            usesBackendModeEligibility: usesBackendModeEligibility,
            presentation: presentation,
            importanceMetadata: importanceMetadata,
            headline: headline ?? "Game update \(sequence)",
            detail: detail,
            rawText: nil,
            rawFeedSource: rawFeedSource,
            rawFeedUpdatedAt: nil,
            scoreBefore: nil,
            scoreAfter: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "home", participantRole: .home, score: homeScore),
                    ParticipantScore(participantID: "away", participantRole: .away, score: awayScore)
                ]
            ),
            scoreDelta: scoreDelta,
            sportMetadata: sportMetadata
        )
    }

    private static func eligibleModes(for importance: GameEventImportance) -> Set<GameMode> {
        switch importance {
        case .primary:
            return [.timeline, .flow, .stream]
        case .secondary:
            return [.flow, .stream]
        case .contextual:
            return [.stream]
        }
    }

    static func makeDetail(game: Game, events: [GameEvent]) -> GameDetail {
        GameDetail(
            game: game,
            teamStats: [],
            playerStats: [],
            events: events,
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
    }

    static func sdaGameListJSON(ids: [Int]) -> Data {
        do {
            return try SDAFixturePayloadFactory.gameList(ids: ids)
        } catch {
            preconditionFailure("Unable to build SDA game-list fixture payload: \(error)")
        }
    }

    static func sdaGameSummaryJSON(id: Int, playCount: Int = 2) -> String {
        do {
            return try SDAFixturePayloadFactory.gameSummary(id: id, playCount: playCount)
        } catch {
            preconditionFailure("Unable to build SDA game-summary fixture payload: \(error)")
        }
    }

    static func sdaGameDetailJSON(gameId: Int = 504, playIDs: [String]) -> Data {
        do {
            return try SDAFixturePayloadFactory.gameDetail(gameId: gameId, playIDs: playIDs)
        } catch {
            preconditionFailure("Unable to build SDA game-detail fixture payload: \(error)")
        }
    }

    static func makeProgress(
        gameId: Int,
        lastReadEventID: String? = nil,
        lastReadEventIndex: Int? = nil,
        lastKnownEventCount: Int = 0,
        reachedScoreboard: Bool = false
    ) -> GameProgressRecord {
        var progress = GameProgressRecord.empty(gameId: gameId, now: fixedDate())
        progress.firstViewedAt = fixedDate("2026-05-22T15:00:00Z")
        progress.lastViewedAt = fixedDate("2026-05-22T15:30:00Z")
        progress.lastReadEventID = lastReadEventID
        progress.lastReadEventIndex = lastReadEventIndex
        progress.lastKnownEventCount = lastKnownEventCount
        progress.newEventCount = max(0, lastKnownEventCount - progress.readEventCount)
        progress.reachedScoreboard = reachedScoreboard
        return progress
    }
}

enum MockHTTPResponse {
    case ok(Data)
    case httpError(statusCode: Int)
}

class MockHTTPURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var responseQueues: [ObjectIdentifier: [MockHTTPResponse]] = [:]
    nonisolated(unsafe) private static var requestedURLs: [ObjectIdentifier: [URL]] = [:]

    static func setResponses(_ responses: [MockHTTPResponse], for protocolClass: MockHTTPURLProtocol.Type) {
        let key = ObjectIdentifier(protocolClass)
        responseQueues[key] = responses
        requestedURLs[key] = []
    }

    static func requestURLs(for protocolClass: MockHTTPURLProtocol.Type) -> [URL] {
        requestedURLs[ObjectIdentifier(protocolClass)] ?? []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let next = Self.nextResponse(for: type(of: self)) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        Self.recordRequest(url, for: type(of: self))

        switch next {
        case .ok(let data):
            respond(url: url, statusCode: 200, data: data)
        case .httpError(let statusCode):
            respond(url: url, statusCode: statusCode, data: Data())
        }
    }

    override func stopLoading() {}

    private static func nextResponse(for protocolClass: MockHTTPURLProtocol.Type) -> MockHTTPResponse? {
        let key = ObjectIdentifier(protocolClass)
        guard var queue = responseQueues[key], !queue.isEmpty else {
            return nil
        }
        let response = queue.removeFirst()
        responseQueues[key] = queue
        return response
    }

    private static func recordRequest(_ url: URL, for protocolClass: MockHTTPURLProtocol.Type) {
        let key = ObjectIdentifier(protocolClass)
        requestedURLs[key, default: []].append(url)
    }

    private func respond(url: URL, statusCode: Int, data: Data) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
