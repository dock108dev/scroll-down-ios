#if DEBUG
import Foundation

enum SDAUIPerformanceFixturePayload {
    nonisolated(unsafe) private static var detailRequestCounts: [Int: Int] = [:]

    static func data(for url: URL) -> Data? {
        let path = url.path
        if path == "/api/admin/sports/games" {
            let games = gameSummaries()
            return SDAUIFixturePayload.jsonData(["games": games, "total": games.count])
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
        let playCount = gameID == 9101 && requestCount > 1 ? 105 : ((game["playCount"] as? Int) ?? 1)

        return SDAUIFixturePayload.jsonData([
            "detailContractVersion": 2,
            "game": gameWithPlayCount(game, playCount: playCount),
            "teamStats": SDAUIFixturePayload.teamStats(away: "Harbor Club 0", home: "Metro Club 0"),
            "playerStats": SDAUIFixturePayload.playerStats(away: "Harbor Club 0", home: "Metro Club 0"),
            "plays": plays(gameID: gameID, count: playCount),
            "mlbBatters": SDAUIFixturePayload.batterStats(away: "Harbor Club 0", home: "Metro Club 0"),
            "mlbPitchers": SDAUIFixturePayload.pitcherStats(away: "Harbor Club 0", home: "Metro Club 0"),
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
            let playCount = id == 9101 ? 90 : 24 + (index % 12)
            return game(
                id: id,
                league: league,
                date: SDAUIFixturePayload.relativeDate(days: index % 2 == 0 ? 0 : -1, hour: 12 + (index % 10), now: now),
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
            "gameDate": SDAUIFixturePayload.apiDate(date),
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
            "score": ["away": awayScore, "home": homeScore],
            "eligibility": eligibility(),
            "presentation": presentation(
                headline: "\(away) at \(home)",
                displayState: isLive ? "live" : "final",
                playCount: playCount
            ),
            "scoreboard": SDAUIFixturePayload.lineScoreboard(
                away: away,
                awayAbbr: awayAbbr,
                home: home,
                homeAbbr: homeAbbr,
                awayScore: awayScore,
                homeScore: homeScore,
                status: isFinal ? "Final" : "Live",
                segments: [["label": "T", "away": "\(awayScore)", "home": "\(homeScore)"]]
            )
        ]
    }

    private static func gameWithPlayCount(_ game: [String: Any], playCount: Int) -> [String: Any] {
        var copy = game
        copy["playCount"] = playCount
        copy["presentation"] = presentation(
            headline: "\(copy["awayTeam"] ?? "Away") at \(copy["homeTeam"] ?? "Home")",
            displayState: (copy["status"] as? String) == "in_progress" ? "live" : "final",
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
            "score": ["away": away, "home": home],
            "periodLabel": period,
            "clockLabel": period,
            "timeLabel": period,
            "tier": scoring ? 1 : 2,
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
            "importance": SDAUIFixturePayload.importance(level: level, scoring: scoring),
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
            "displayLabels": [
                "status": displayState == "live" ? "Live" : "Final",
                "primaryAction": displayState == "live" ? "Watch live" : "Catch up",
                "secondaryContext": ""
            ],
            "scoreboardPlacement": "bottom"
        ]
    }
}
#endif
