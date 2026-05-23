#if DEBUG
import Foundation

enum SDAUIPerformanceFixturePayload {
    nonisolated(unsafe) private static var detailRequestCounts: [Int: Int] = [:]

    static func data(for url: URL) -> Data? {
        let path = url.path
        if path == "/api/admin/sports/games" {
            let games = gameSummaries()
            return jsonData(["games": games, "total": games.count])
        }

        guard path.hasPrefix("/api/admin/sports/games/"),
              let id = path.split(separator: "/").last.flatMap({ Int($0) }) else {
            return nil
        }
        return detailData(gameID: id)
    }

    private static func detailData(gameID: Int) -> Data? {
        guard let game = gameSummaries().first(where: { ($0["id"] as? Int) == gameID }) else { return nil }
        let requestCount = (detailRequestCounts[gameID] ?? 0) + 1
        detailRequestCounts[gameID] = requestCount
        let playCount = gameID == 9101 && requestCount > 1 ? 165 : ((game["playCount"] as? Int) ?? 1)

        return jsonData([
            "detailContractVersion": 2,
            "game": gameWithPlayCount(game, playCount: playCount),
            "teamStats": teamStats(),
            "playerStats": playerStats(),
            "plays": plays(gameID: gameID, count: playCount),
            "mlbBatters": batterStats(),
            "mlbPitchers": pitcherStats(),
            "nhlSkaters": [],
            "nhlGoalies": []
        ])
    }

    private static func gameSummaries() -> [[String: Any]] {
        let now = Date()
        return (0..<200).map { index in
            let league = ["MLB", "NBA", "NHL", "NFL"][index % 4]
            let id = baseID(for: league) + (index / 4)
            let isLive = index.isMultiple(of: 5)
            let playCount = id == 9101 ? 150 : 24 + (index % 12)
            return game(
                id: id,
                league: league,
                date: relativeDate(days: index % 2 == 0 ? 0 : -1, hour: 12 + (index % 10), now: now),
                status: isLive ? "in_progress" : "final",
                away: index.isMultiple(of: 2) ? "Harbor Club \(index)" : "Canyon Club \(index)",
                awayAbbr: "A\(index)",
                home: "Metro Club \(index)",
                homeAbbr: "H\(index)",
                awayScore: index % 9,
                homeScore: (index + 3) % 11,
                playCount: playCount,
                isLive: isLive,
                isFinal: !isLive
            )
        }
    }

    private static func baseID(for league: String) -> Int {
        switch league {
        case "MLB": return 9101
        case "NBA": return 9201
        case "NHL": return 9301
        default: return 9401
        }
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
        awayScore: Int,
        homeScore: Int,
        playCount: Int,
        isLive: Bool,
        isFinal: Bool
    ) -> [String: Any] {
        [
            "id": id,
            "leagueCode": league,
            "gameDate": apiDate(date),
            "localGameDate": DateFormatters.daySubtitle.string(from: date),
            "status": status,
            "homeTeam": home,
            "awayTeam": away,
            "homeTeamAbbr": homeAbbr,
            "awayTeamAbbr": awayAbbr,
            "currentPeriod": isFinal ? 9 : 5,
            "currentPeriodLabel": isFinal ? "Final" : "5th",
            "gameClock": isFinal ? "Final" : "1 out",
            "hasPbp": true,
            "playCount": playCount,
            "isLive": isLive,
            "isFinal": isFinal,
            "score": ["away": awayScore, "home": homeScore],
            "awayScore": awayScore,
            "homeScore": homeScore,
            "eligibility": eligibility(),
            "presentation": presentation(headline: "\(away) at \(home)", displayState: isLive ? "live" : "final", playCount: playCount),
            "scoreboard": scoreboard(away: away, awayAbbr: awayAbbr, home: home, homeAbbr: homeAbbr, awayScore: awayScore, homeScore: homeScore, status: isFinal ? "Final" : "Live")
        ]
    }

    private static func gameWithPlayCount(_ game: [String: Any], playCount: Int) -> [String: Any] {
        var copy = game
        copy["playCount"] = playCount
        copy["presentation"] = presentation(
            headline: "\(copy["awayTeam"] ?? "Away") at \(copy["homeTeam"] ?? "Home")",
            displayState: (copy["isLive"] as? Bool) == true ? "live" : "final",
            playCount: playCount
        )
        return copy
    }

    private static func plays(gameID: Int, count: Int) -> [[String: Any]] {
        guard gameID == 9101 else {
            return [play(index: 1, eventID: "evt-\(gameID)-001", period: "1st", headline: "Opening possession settles in.", away: 0, home: 0)]
        }
        return (1...count).map { index in
            play(
                index: index,
                eventID: String(format: "evt-perf-%03d", index),
                period: "P\(((index - 1) / 30) + 1)",
                headline: "Long stream play \(index) keeps the live feed moving.",
                away: index / 15,
                home: index / 12,
                scoring: index.isMultiple(of: 10),
                team: index.isMultiple(of: 2) ? "H0" : "A0",
                level: index.isMultiple(of: 10) ? "primary" : "secondary"
            )
        }
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
        level: String = "secondary"
    ) -> [String: Any] {
        [
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
            "teamAbbreviation": team ?? "",
            "presentation": [
                "headline": headline,
                "body": scoring ? "Score moves to \(away)-\(home)." : "Sequence \(index).",
                "timeLabel": period,
                "teamLabel": team ?? "",
                "scoreLabel": scoring ? "\(away)-\(home)" : "",
                "eventTypeLabel": scoring ? "Scoring" : "Play",
                "accessibilityLabel": "\(period). \(headline)"
            ],
            "importance": importance(level: level, scoring: scoring),
            "rawFeedText": index.isMultiple(of: 4) ? "Provider row \(index)" : "",
            "rawFeedSource": index.isMultiple(of: 4) ? "provider" : "",
            "rawFeedUpdatedAt": "",
            "rawDescription": "",
            "modeEligibility": ["important": true, "standard": true, "all": true],
            "belongsToModes": ["important": true, "standard": true, "all": true],
            "scoreBefore": ["away": max(0, away - 1), "home": max(0, home - 1)],
            "scoreAfter": ["away": away, "home": home],
            "sportMetadata": [:],
            "metadata": [:]
        ]
    }

    private static func eligibility() -> [String: Any] {
        [
            "schemaVersion": 1,
            "catchUp": ["isEligible": true],
            "playByPlay": ["isEligible": true],
            "keyMoments": ["isEligible": true],
            "boxScore": ["isEligible": true],
            "teamStats": ["isEligible": true],
            "playerStats": ["isEligible": true],
            "liveTracker": ["isEligible": true],
            "recap": ["isEligible": true]
        ]
    }

    private static func presentation(headline: String, displayState: String, playCount: Int) -> [String: Any] {
        [
            "schemaVersion": 1,
            "headline": headline,
            "shortHeadline": headline,
            "body": "",
            "subheadline": "Long stream smoke fixture",
            "matchupLabel": headline,
            "primaryLabel": displayState == "live" ? "Watch live" : "Catch up",
            "secondaryLabel": "",
            "tertiaryLabel": "",
            "accessibilityLabel": headline,
            "displayState": displayState,
            "visualPriority": 1,
            "sortBucket": "fixture",
            "theme": ["accentRole": "scoreboard", "statusTone": displayState],
            "eventCounts": ["key": playCount, "flow": playCount, "full": playCount],
            "displayLabels": ["status": displayState == "live" ? "Live" : "Final", "primaryAction": displayState == "live" ? "Watch live" : "Catch up", "secondaryContext": ""],
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
            "segments": [["label": "T", "away": "\(awayScore)", "home": "\(homeScore)"]],
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
            ["team": "Harbor Club 0", "isHome": false, "stats": ["hits": 9, "errors": 0], "normalizedStats": []],
            ["team": "Metro Club 0", "isHome": true, "stats": ["hits": 7, "errors": 1], "normalizedStats": []]
        ]
    }

    private static func playerStats() -> [[String: Any]] {
        [
            ["team": "Harbor Club 0", "playerName": "Mason Reed", "minutes": 0, "points": 0, "rebounds": 0, "assists": 0, "yards": 0, "touchdowns": 0, "rawStats": ["hits": 3]],
            ["team": "Metro Club 0", "playerName": "Theo Vale", "minutes": 0, "points": 0, "rebounds": 0, "assists": 0, "yards": 0, "touchdowns": 0, "rawStats": ["rbi": 2]]
        ]
    }

    private static func batterStats() -> [[String: Any]] {
        [
            ["team": "Harbor Club 0", "playerName": "Mason Reed", "position": "RF", "atBats": 4, "hits": 3, "runs": 1, "rbi": 2, "homeRuns": 0, "baseOnBalls": 1, "strikeOuts": 0],
            ["team": "Metro Club 0", "playerName": "Theo Vale", "position": "2B", "atBats": 4, "hits": 2, "runs": 1, "rbi": 2, "homeRuns": 0, "baseOnBalls": 0, "strikeOuts": 1]
        ]
    }

    private static func pitcherStats() -> [[String: Any]] {
        [
            ["team": "Harbor Club 0", "playerName": "Ari Stone", "inningsPitched": "6.0", "hits": 5, "runs": 2, "earnedRuns": 2, "baseOnBalls": 1, "strikeOuts": 7, "homeRuns": 0],
            ["team": "Metro Club 0", "playerName": "Lane Frost", "inningsPitched": "5.2", "hits": 7, "runs": 4, "earnedRuns": 4, "baseOnBalls": 2, "strikeOuts": 5, "homeRuns": 0]
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
