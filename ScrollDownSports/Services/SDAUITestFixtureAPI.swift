#if DEBUG
import Foundation

enum SDAUITestFixtureAPI {
    static func makeClient() -> SDAApiClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SDAUITestFixtureURLProtocol.self]
        return SDAApiClient(
            baseURL: URL(string: "https://scroll-down-sports-ui-test.local")!,
            apiKey: "",
            session: URLSession(configuration: configuration)
        )
    }
}

private final class SDAUITestFixtureURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "scroll-down-sports-ui-test.local"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            finish(statusCode: 400, data: Data())
            return
        }

        guard let data = SDAUITestFixturePayload.data(for: url) else {
            finish(statusCode: 404, data: Data())
            return
        }

        finish(statusCode: 200, data: data)
    }

    override func stopLoading() {}

    private func finish(statusCode: Int, data: Data) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://scroll-down-sports-ui-test.local")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

private enum SDAUITestFixturePayload {
    static func data(for url: URL) -> Data? {
        if AppEnvironment.uiTestFixtureName == "performance-long-stream" {
            return SDAUIPerformanceFixturePayload.data(for: url)
        }
        guard AppEnvironment.uiTestFixtureName == "critical-final-game" else { return nil }
        let path = url.path
        if path == "/api/admin/sports/games" {
            return jsonData(["games": gameSummaries(), "total": gameSummaries().count])
        }

        guard path.hasPrefix("/api/admin/sports/games/"),
              let id = path.split(separator: "/").last.flatMap({ Int($0) }) else {
            return nil
        }
        return detailData(gameID: id)
    }

    private static func detailData(gameID: Int) -> Data? {
        guard let game = gameSummaries().first(where: { ($0["id"] as? Int) == gameID }) else { return nil }
        return jsonData([
            "detailContractVersion": 2,
            "game": game,
            "teamStats": teamStats(),
            "playerStats": playerStats(),
            "plays": plays(for: gameID),
            "mlbBatters": batterStats(),
            "mlbPitchers": pitcherStats(),
            "nhlSkaters": [],
            "nhlGoalies": []
        ])
    }

    private static func gameSummaries() -> [[String: Any]] {
        let now = Date()
        return [
            game(
                id: 9001,
                league: "MLB",
                date: relativeDate(days: 0, hour: 13, now: now),
                status: "final",
                away: "Harbor Pilots",
                awayAbbr: "HBP",
                home: "Canyon Owls",
                homeAbbr: "COW",
                awayScore: 5,
                homeScore: 3,
                playCount: 10
            ),
            game(
                id: 9002,
                league: "MLB",
                date: relativeDate(days: -1, hour: 19, now: now),
                status: "final",
                away: "Metro Lynx",
                awayAbbr: "MLX",
                home: "River Comets",
                homeAbbr: "RVC",
                awayScore: 2,
                homeScore: 1,
                playCount: 6
            ),
            game(
                id: 9003,
                league: "NBA",
                date: relativeDate(days: 0, hour: 15, now: now),
                status: "final",
                away: "Prairie Jets",
                awayAbbr: "PRJ",
                home: "Summit Bears",
                homeAbbr: "SMB",
                awayScore: 108,
                homeScore: 101,
                playCount: 8
            ),
            game(
                id: 9004,
                league: "NHL",
                date: relativeDate(days: 0, hour: 18, now: now),
                status: "in_progress",
                away: "Northline Foxes",
                awayAbbr: "NLF",
                home: "Bay Wolves",
                homeAbbr: "BYW",
                awayScore: 1,
                homeScore: 1,
                playCount: 5,
                isLive: true,
                isFinal: false
            ),
            game(
                id: 9005,
                league: "NFL",
                date: relativeDate(days: 1, hour: 20, now: now),
                status: "scheduled",
                away: "Copper Hawks",
                awayAbbr: "CPH",
                home: "Atlas Bulls",
                homeAbbr: "ATB",
                awayScore: nil,
                homeScore: nil,
                playCount: 0,
                isLive: false,
                isFinal: false,
                hasTimeline: false
            ),
            game(
                id: 9099,
                league: "MLB",
                date: relativeDate(days: 0, hour: 21, now: now),
                status: "scheduled",
                away: "TBD",
                awayAbbr: "TBD",
                home: "Team TBD",
                homeAbbr: "TBD",
                awayScore: nil,
                homeScore: nil,
                playCount: 0,
                isLive: false,
                isFinal: false,
                hasTimeline: false,
                hasScoreboard: false,
                previewCopy: false
            )
        ]
    }

    private static func game(
        id: Int,
        league: String,
        date: Date,
        status: String,
        away: String,
        awayAbbr: String,
        home: String,
        homeAbbr: String,
        awayScore: Int?,
        homeScore: Int?,
        playCount: Int,
        isLive: Bool = false,
        isFinal: Bool = true,
        hasTimeline: Bool = true,
        hasScoreboard: Bool = true,
        previewCopy: Bool = true
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "id": id,
            "leagueCode": league,
            "gameDate": apiDate(date),
            "localGameDate": DateFormatters.daySubtitle.string(from: date),
            "status": status,
            "homeTeam": home,
            "awayTeam": away,
            "homeTeamAbbr": homeAbbr,
            "awayTeamAbbr": awayAbbr,
            "currentPeriod": isFinal ? 9 : 3,
            "currentPeriodLabel": isFinal ? "Final" : "3rd",
            "gameClock": isFinal ? "Final" : "12:44",
            "hasPbp": hasTimeline,
            "playCount": playCount,
            "isLive": isLive,
            "isFinal": isFinal,
            "eligibility": eligibility(hasTimeline: hasTimeline, hasScoreboard: hasScoreboard),
            "presentation": presentation(
                headline: "\(away) at \(home)",
                action: isFinal ? "Catch up" : "Preview",
                displayState: isFinal ? "final" : (isLive ? "live" : "scheduled"),
                playCount: playCount,
                includePreviewCopy: previewCopy
            )
        ]
        if let awayScore, let homeScore {
            payload["score"] = ["away": awayScore, "home": homeScore]
            payload["awayScore"] = awayScore
            payload["homeScore"] = homeScore
            payload["scoreboard"] = scoreboard(
                away: away,
                awayAbbr: awayAbbr,
                home: home,
                homeAbbr: homeAbbr,
                awayScore: awayScore,
                homeScore: homeScore,
                status: isFinal ? "Final" : "Live"
            )
        }
        return payload
    }

    private static func plays(for gameID: Int) -> [[String: Any]] {
        guard gameID == 9001 else {
            return [
                play(index: 1, eventID: "evt-\(gameID)-001", period: "1st", headline: "The game opens with a settled first possession.", away: 0, home: 0)
            ]
        }

        return [
            play(index: 1, eventID: "evt-9001-001", period: "1st", headline: "Canyon Owls open with a clean single to center.", away: 0, home: 0),
            play(index: 2, eventID: "evt-9001-002", period: "1st", headline: "Harbor Pilots turn two to quiet the inning.", away: 0, home: 0, level: "secondary"),
            play(index: 3, eventID: "evt-9001-003", period: "2nd", headline: "Harbor Pilots score on a sacrifice fly.", away: 1, home: 0, scoring: true, team: "HBP"),
            play(index: 4, eventID: "evt-9001-004", period: "3rd", headline: "Canyon Owls answer with a two-run double.", away: 1, home: 2, scoring: true, team: "COW"),
            play(index: 5, eventID: "evt-9001-005", period: "4th", headline: "A diving stop saves a run for the Owls.", away: 1, home: 2, level: "secondary"),
            play(index: 6, eventID: "evt-9001-006", period: "5th", headline: "Pilots tie it with a line-drive single.", away: 2, home: 2, scoring: true, team: "HBP"),
            play(index: 7, eventID: "evt-9001-007", period: "6th", headline: "Harbor takes the lead on a deep drive.", away: 4, home: 2, scoring: true, team: "HBP"),
            play(index: 8, eventID: "evt-9001-008", period: "7th", headline: "Canyon cuts the gap with a sharp grounder.", away: 4, home: 3, scoring: true, team: "COW"),
            play(index: 9, eventID: "evt-9001-009", period: "8th", headline: "Pilots add insurance after a leadoff walk.", away: 5, home: 3, scoring: true, team: "HBP"),
            play(index: 10, eventID: "evt-9001-010", period: "9th", headline: "Final out lands softly in left field.", away: 5, home: 3)
        ]
    }

    private static func play(
        index: Int,
        eventID: String,
        period: String,
        headline: String,
        away: Int,
        home: Int,
        scoring: Bool = false,
        team: String? = nil,
        level: String = "primary"
    ) -> [String: Any] {
        let beforeAway = max(0, away - (scoring && team == "HBP" ? 1 : 0))
        let beforeHome = max(0, home - (scoring && team == "COW" ? 1 : 0))
        var payload: [String: Any] = [
            "eventId": eventID,
            "playIndex": index,
            "quarter": index,
            "gameClock": period,
            "playType": scoring ? "scoring_play" : "play",
            "displayType": scoring ? "Scoring play" : "Play",
            "playerName": "",
            "description": headline,
            "homeScore": home,
            "awayScore": away,
            "score": ["away": away, "home": home],
            "periodLabel": period,
            "clockLabel": period,
            "timeLabel": period,
            "tier": scoring ? 1 : 2,
            "scoreChanged": scoring,
            "scoreDisplay": "\(away)-\(home)",
            "presentation": [
                "headline": headline,
                "body": scoring ? "Score moves to \(away)-\(home)." : "",
                "timeLabel": period,
                "teamLabel": team ?? "",
                "scoreLabel": scoring ? "\(away)-\(home)" : "",
                "eventTypeLabel": scoring ? "Scoring" : "Play",
                "accessibilityLabel": "\(period). \(headline)"
            ],
            "importance": importance(level: level, scoring: scoring),
            "rawFeedText": "",
            "rawFeedSource": "",
            "rawFeedUpdatedAt": "",
            "rawDescription": "",
            "modeEligibility": ["important": true, "standard": true, "all": true],
            "belongsToModes": ["important": true, "standard": true, "all": true],
            "scoreBefore": ["away": beforeAway, "home": beforeHome],
            "scoreAfter": ["away": away, "home": home],
            "sportMetadata": [:],
            "metadata": [:]
        ]
        if let team {
            payload["teamAbbreviation"] = team
        }
        if scoring {
            let delta = [
                "side": team == "COW" ? "home" : "away",
                "participantRole": team == "COW" ? "home" : "away",
                "before": team == "COW" ? beforeHome : beforeAway,
                "after": team == "COW" ? home : away,
                "change": 1,
                "scoreText": "\(away)-\(home)"
            ] as [String: Any]
            payload["scoreDelta"] = delta
            payload["scoreboard"] = [
                "scoreBefore": ["away": beforeAway, "home": beforeHome],
                "scoreAfter": ["away": away, "home": home],
                "scoreDelta": delta
            ]
        }
        return payload
    }

    private static func eligibility(hasTimeline: Bool, hasScoreboard: Bool) -> [String: Any] {
        [
            "schemaVersion": 1,
            "catchUp": ["isEligible": hasTimeline],
            "playByPlay": ["isEligible": hasTimeline],
            "keyMoments": ["isEligible": hasTimeline],
            "boxScore": ["isEligible": hasScoreboard],
            "teamStats": ["isEligible": true],
            "playerStats": ["isEligible": true],
            "liveTracker": ["isEligible": hasTimeline],
            "recap": ["isEligible": hasTimeline]
        ]
    }

    private static func presentation(
        headline: String,
        action: String,
        displayState: String,
        playCount: Int,
        includePreviewCopy: Bool
    ) -> [String: Any] {
        [
            "schemaVersion": 1,
            "headline": includePreviewCopy ? headline : "",
            "shortHeadline": includePreviewCopy ? headline : "",
            "body": "",
            "subheadline": includePreviewCopy ? "Critical flow fixture" : "",
            "matchupLabel": includePreviewCopy ? headline : "",
            "primaryLabel": action,
            "secondaryLabel": "",
            "tertiaryLabel": "",
            "accessibilityLabel": includePreviewCopy ? headline : "",
            "displayState": displayState,
            "visualPriority": 1,
            "sortBucket": "fixture",
            "theme": ["accentRole": "scoreboard", "statusTone": displayState],
            "eventCounts": ["key": playCount, "flow": playCount, "full": playCount],
            "displayLabels": ["status": displayState == "final" ? "Final" : action, "primaryAction": action, "secondaryContext": ""],
            "scoreboardPlacement": "bottom"
        ]
    }

    private static func scoreboard(
        away: String,
        awayAbbr: String,
        home: String,
        homeAbbr: String,
        awayScore: Int,
        homeScore: Int,
        status: String
    ) -> [String: Any] {
        [
            "schemaVersion": 1,
            "layout": "line_score",
            "statusLabel": status,
            "scoreline": "\(away) \(awayScore), \(home) \(homeScore)",
            "competitors": [
                ["side": "away", "teamName": away, "teamAbbreviation": awayAbbr, "score": awayScore, "scoreText": "\(awayScore)", "isWinner": awayScore > homeScore],
                ["side": "home", "teamName": home, "teamAbbreviation": homeAbbr, "score": homeScore, "scoreText": "\(homeScore)", "isWinner": homeScore > awayScore]
            ],
            "segments": [
                ["label": "1", "away": "0", "home": "0"],
                ["label": "2", "away": "1", "home": "0"],
                ["label": "3", "away": "0", "home": "2"],
                ["label": "4", "away": "0", "home": "0"],
                ["label": "5", "away": "1", "home": "0"],
                ["label": "6", "away": "2", "home": "0"],
                ["label": "7", "away": "0", "home": "1"],
                ["label": "8", "away": "1", "home": "0"],
                ["label": "9", "away": "0", "home": "0"]
            ],
            "totals": ["away": "\(awayScore)", "home": "\(homeScore)"]
        ]
    }

    private static func importance(level: String, scoring: Bool) -> [String: Any] {
        [
            "schemaVersion": 1,
            "level": level,
            "rank": scoring ? 1 : 2,
            "bucket": scoring ? "scoring" : "flow",
            "reasons": scoring ? ["scoring"] : ["flow"],
            "isKeyMoment": true,
            "isScoringPlay": scoring,
            "isLeadChange": false,
            "isTyingPlay": false,
            "isLateGame": false,
            "isFinalPlay": false,
            "isRunEnding": false
        ]
    }

    private static func teamStats() -> [[String: Any]] {
        [
            ["team": "Harbor Pilots", "isHome": false, "stats": ["hits": 9, "errors": 0], "normalizedStats": []],
            ["team": "Canyon Owls", "isHome": true, "stats": ["hits": 7, "errors": 1], "normalizedStats": []]
        ]
    }

    private static func playerStats() -> [[String: Any]] {
        [
            ["team": "Harbor Pilots", "playerName": "Mason Reed", "minutes": 0, "points": 0, "rebounds": 0, "assists": 0, "yards": 0, "touchdowns": 0, "rawStats": ["hits": 3]],
            ["team": "Canyon Owls", "playerName": "Theo Vale", "minutes": 0, "points": 0, "rebounds": 0, "assists": 0, "yards": 0, "touchdowns": 0, "rawStats": ["rbi": 2]]
        ]
    }

    private static func batterStats() -> [[String: Any]] {
        [
            ["team": "Harbor Pilots", "playerName": "Mason Reed", "position": "RF", "atBats": 4, "hits": 3, "runs": 1, "rbi": 2, "homeRuns": 0, "baseOnBalls": 1, "strikeOuts": 0],
            ["team": "Canyon Owls", "playerName": "Theo Vale", "position": "2B", "atBats": 4, "hits": 2, "runs": 1, "rbi": 2, "homeRuns": 0, "baseOnBalls": 0, "strikeOuts": 1]
        ]
    }

    private static func pitcherStats() -> [[String: Any]] {
        [
            ["team": "Harbor Pilots", "playerName": "Ari Stone", "inningsPitched": "6.0", "hits": 5, "runs": 2, "earnedRuns": 2, "baseOnBalls": 1, "strikeOuts": 7, "homeRuns": 0],
            ["team": "Canyon Owls", "playerName": "Lane Frost", "inningsPitched": "5.2", "hits": 7, "runs": 4, "earnedRuns": 4, "baseOnBalls": 2, "strikeOuts": 5, "homeRuns": 0]
        ]
    }

    private static func relativeDate(days: Int, hour: Int, now: Date) -> Date {
        var calendar = Calendar.sda
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let start = calendar.startOfDay(for: now)
        var components = DateComponents()
        components.day = days
        components.hour = hour
        return calendar.date(byAdding: components, to: start) ?? now
    }

    private static func apiDate(_ date: Date) -> String {
        ISO8601DateFormatter.sda.string(from: date)
    }

    private static func jsonData(_ object: Any) -> Data? {
        try? JSONSerialization.data(withJSONObject: object, options: [])
    }
}
#endif
