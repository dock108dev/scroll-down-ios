#if DEBUG
import Foundation

enum SDAUITestHomeFixturePayloads {
    static func gameSummaries(for fixtureName: String) -> [[String: Any]] {
        switch fixtureName {
        case "critical-final-game":
            return criticalGameSummaries()
        case "blank-home":
            return []
        case "future-game":
            return futureGameSummaries()
        default:
            return []
        }
    }

    private static func criticalGameSummaries() -> [[String: Any]] {
        let now = Date()
        return [
            game(
                id: 9001,
                league: "MLB",
                date: SDAUIFixturePayload.relativeDate(days: 0, hour: 13, now: now),
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
                date: SDAUIFixturePayload.relativeDate(days: -1, hour: 19, now: now),
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
                date: SDAUIFixturePayload.relativeDate(days: 0, hour: 15, now: now),
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
                date: SDAUIFixturePayload.relativeDate(days: 0, hour: 18, now: now),
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
                date: SDAUIFixturePayload.relativeDate(days: 1, hour: 20, now: now),
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
                date: SDAUIFixturePayload.relativeDate(days: 0, hour: 21, now: now),
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

    private static func futureGameSummaries() -> [[String: Any]] {
        let now = Date()
        return [
            game(
                id: 9101,
                league: "MLB",
                date: SDAUIFixturePayload.relativeDate(days: 1, hour: 19, now: now),
                status: "scheduled",
                away: "Prairie Junction Rails",
                awayAbbr: "PJR",
                home: "Harbor City Tides",
                homeAbbr: "HCT",
                awayScore: nil,
                homeScore: nil,
                playCount: 0,
                isLive: false,
                isFinal: false,
                hasTimeline: false,
                hasScoreboard: false
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
            "gameDate": SDAUIFixturePayload.apiDate(date),
            "localGameDate": DateFormatters.daySubtitle.string(from: date),
            "status": status,
            "homeTeam": home,
            "awayTeam": away,
            "homeTeamAbbr": homeAbbr,
            "awayTeamAbbr": awayAbbr,
            "hasPbp": hasTimeline,
            "playCount": playCount,
            "eligibility": eligibility(hasTimeline: hasTimeline, hasScoreboard: hasScoreboard),
            "presentation": presentation(
                headline: "\(away) at \(home)",
                action: isFinal ? "Catch up" : "Preview",
                displayState: isFinal ? "final" : (isLive ? "live" : "scheduled"),
                playCount: playCount,
                includePreviewCopy: previewCopy
            )
        ]
        if isFinal {
            payload["currentPeriod"] = 9
            payload["currentPeriodLabel"] = "Final"
            payload["gameClock"] = "Final"
        } else if isLive {
            payload["currentPeriod"] = 3
            payload["currentPeriodLabel"] = "3rd"
            payload["gameClock"] = "12:44"
        }
        if let awayScore, let homeScore {
            payload["score"] = ["away": awayScore, "home": homeScore]
            payload["scoreboard"] = SDAUIFixturePayload.lineScoreboard(
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
            "displayLabels": [
                "status": displayState == "final" ? "Final" : action,
                "primaryAction": action,
                "secondaryContext": ""
            ],
            "scoreboardPlacement": "bottom"
        ]
    }
}
#endif
