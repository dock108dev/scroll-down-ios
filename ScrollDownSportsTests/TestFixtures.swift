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
        awayAbbreviation: String = "NYY",
        homeName: String = "Seattle Mariners",
        homeAbbreviation: String = "SEA",
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
        eligibleModes: Set<GameMode> = [.timeline, .flow, .stream],
        usesBackendModeEligibility: Bool = false,
        presentation: EventPresentationData? = nil,
        importanceMetadata: EventImportanceData? = nil,
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
            eventType: "play",
            importance: importance,
            eligibleModes: eligibleModes,
            usesBackendModeEligibility: usesBackendModeEligibility,
            presentation: presentation,
            importanceMetadata: importanceMetadata,
            headline: headline ?? "Game update \(sequence)",
            detail: detail,
            rawText: nil,
            rawFeedSource: nil,
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
        let games = ids.map { sdaGameSummaryJSON(id: $0) }.joined(separator: ",")
        return Data("""
        {"games":[\(games)],"total":\(ids.count),"lastUpdatedAt":null}
        """.utf8)
    }

    static func sdaGameSummaryJSON(id: Int, playCount: Int = 2) -> String {
        """
        {
          "id": \(id),
          "leagueCode": "mlb",
          "gameDate": "2026-05-22T23:10:00.000Z",
          "localGameDate": "2026-05-22",
          "status": "in_progress",
          "homeTeam": "Seattle Mariners",
          "awayTeam": "New York Yankees",
          "homeTeamAbbr": "SEA",
          "awayTeamAbbr": "NYY",
          "currentPeriod": 1,
          "currentPeriodLabel": "Q1",
          "gameClock": "10:00",
          "score": {"home": 0, "away": 0},
          "homeScore": 0,
          "awayScore": 0,
          "hasPbp": true,
          "playCount": \(playCount),
          "isLive": true,
          "isFinal": false
        }
        """
    }

    static func sdaGameDetailJSON(gameId: Int = 504, playIDs: [String]) -> Data {
        let plays = playIDs.enumerated().map { index, id in
            """
            {
              "eventId": "\(id)",
              "playIndex": \(index + 1),
              "quarter": 1,
              "gameClock": "10:0\(index)",
              "playType": "play",
              "teamAbbreviation": "SEA",
              "playerName": null,
              "description": "Game update \(index + 1)",
              "homeScore": \(index),
              "awayScore": 0,
              "score": {"home": \(index), "away": 0},
              "periodLabel": "Q1",
              "timeLabel": "10:0\(index)",
              "tier": 3,
              "scoreChanged": false
            }
            """
        }.joined(separator: ",")

        return Data(
            """
            {
              "game": \(sdaGameSummaryJSON(id: gameId, playCount: playIDs.count)),
              "teamStats": [],
              "playerStats": [],
              "plays": [\(plays)],
              "mlbBatters": null,
              "mlbPitchers": null,
              "nhlSkaters": null,
              "nhlGoalies": null
            }
            """.utf8
        )
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

    static func setResponses(_ responses: [MockHTTPResponse], for protocolClass: MockHTTPURLProtocol.Type) {
        responseQueues[ObjectIdentifier(protocolClass)] = responses
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
