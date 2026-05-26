import Foundation
import SwiftUI
@testable import ScrollDownSports

enum ComponentSnapshotFixtures {
    static let now = TestFixtures.fixedDate("2026-05-23T16:00:00Z")

    static func game(
        id: Int,
        leagueCode: String = "mlb",
        scheduledStart: Date = TestFixtures.fixedDate("2026-05-23T18:10:00Z"),
        status: String = "scheduled",
        isLive: Bool = false,
        isFinal: Bool = false,
        awayName: String = "North Arc Riders",
        awayAbbreviation: String? = "NAR",
        homeName: String = "Bay Harbor Lights",
        homeAbbreviation: String? = "BAY",
        awayScore: Int? = nil,
        homeScore: Int? = nil,
        eventCount: Int? = nil,
        periodOrdinal: Int? = nil,
        periodLabel: String? = nil,
        clockLabel: String? = nil,
        hasTimeline: Bool = true,
        hasStats: Bool = true,
        hasScoreboard: Bool = true,
        presentation: GamePresentationData? = nil,
        scoreboard: GameScoreboardData? = nil
    ) -> Game {
        TestFixtures.makeGame(
            id: id,
            leagueCode: leagueCode,
            scheduledStart: scheduledStart,
            status: status,
            isLive: isLive,
            isFinal: isFinal,
            awayName: awayName,
            awayAbbreviation: awayAbbreviation,
            homeName: homeName,
            homeAbbreviation: homeAbbreviation,
            awayScore: awayScore,
            homeScore: homeScore,
            eventCount: eventCount,
            periodOrdinal: periodOrdinal,
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            hasTimeline: hasTimeline,
            hasStats: hasStats,
            hasScoreboard: hasScoreboard,
            presentation: presentation,
            scoreboard: scoreboard
        )
    }

    static func homeItem(
        game: Game,
        isPinned: Bool = false,
        progress: GameProgressRecord? = nil
    ) -> HomeGameItem {
        let pinnedRecord = isPinned ? PinnedGameRecord(game: game, now: now) : nil
        return HomeGameItem(game: game, isPinned: isPinned, pinnedRecord: pinnedRecord, progress: progress)
    }

    static func scheduledHomeItem() -> HomeGameItem {
        homeItem(
            game: game(
                id: 4_001,
                status: "scheduled",
                isLive: false,
                isFinal: false,
                eventCount: nil,
                hasTimeline: false,
                hasScoreboard: false,
                presentation: previewPresentation()
            )
        )
    }

    static func liveHomeItem(isPinned: Bool = false) -> HomeGameItem {
        homeItem(
            game: game(
                id: 4_002,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T15:10:00Z"),
                status: "in_progress",
                isLive: true,
                awayScore: 4,
                homeScore: 5,
                eventCount: 31,
                periodOrdinal: 7,
                periodLabel: "B7",
                clockLabel: "2 outs"
            ),
            isPinned: isPinned
        )
    }

    static func finalUnreadHomeItem() -> HomeGameItem {
        homeItem(
            game: game(
                id: 4_003,
                scheduledStart: TestFixtures.fixedDate("2026-05-22T23:10:00Z"),
                status: "final",
                isLive: false,
                isFinal: true,
                awayScore: 7,
                homeScore: 6,
                eventCount: 44,
                periodLabel: "Final"
            )
        )
    }

    static func finalReadHomeItem() -> HomeGameItem {
        let final = game(
            id: 4_004,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T21:10:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 3,
            homeScore: 8,
            eventCount: 38,
            periodLabel: "Final"
        )
        var progress = progressRecord(gameId: final.id, lastReadIndex: 37, knownEventCount: 38)
        progress.reachedScoreboard = true
        return homeItem(game: final, progress: progress)
    }

    static func resumeHomeItem() -> HomeGameItem {
        let final = game(
            id: 4_005,
            scheduledStart: TestFixtures.fixedDate("2026-05-22T20:10:00Z"),
            status: "final",
            isLive: false,
            isFinal: true,
            awayScore: 5,
            homeScore: 4,
            eventCount: 29,
            periodOrdinal: 6,
            periodLabel: "T6",
            clockLabel: "1 out"
        )
        return homeItem(game: final, progress: progressRecord(gameId: final.id, lastReadIndex: 12, knownEventCount: 29, newCount: 6))
    }

    static func longNameHomeItem() -> HomeGameItem {
        homeItem(
            game: game(
                id: 4_006,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T19:30:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false,
                awayName: "Northern International Riverfront Athletics Club",
                awayAbbreviation: "NIR",
                homeName: "Bay Harbor Metropolitan Lights Association",
                homeAbbreviation: "BHM",
                hasTimeline: false,
                hasScoreboard: false,
                presentation: previewPresentation()
            )
        )
    }

    static func missingAbbreviationHomeItem() -> HomeGameItem {
        homeItem(
            game: game(
                id: 4_007,
                scheduledStart: TestFixtures.fixedDate("2026-05-23T21:00:00Z"),
                status: "scheduled",
                isLive: false,
                isFinal: false,
                awayName: "Lakeside United",
                awayAbbreviation: nil,
                homeName: "Harbor City",
                homeAbbreviation: nil,
                hasTimeline: false,
                hasScoreboard: false,
                presentation: previewPresentation()
            )
        )
    }

    static func progressRecord(
        gameId: Int,
        lastReadIndex: Int,
        knownEventCount: Int,
        newCount: Int = 0
    ) -> GameProgressRecord {
        var progress = GameProgressRecord.empty(gameId: gameId, now: now)
        progress.firstViewedAt = TestFixtures.fixedDate("2026-05-23T14:00:00Z")
        progress.lastViewedAt = TestFixtures.fixedDate("2026-05-23T15:00:00Z")
        progress.lastReadEventIndex = lastReadIndex
        progress.lastKnownEventCount = knownEventCount
        progress.newEventCount = newCount
        return progress
    }

    static func previewPresentation() -> GamePresentationData {
        TestFixtures.previewPresentation(headline: "Preview notes available")
    }

    static func timelineSection(
        id: String,
        title: String,
        subtitle: String,
        role: HomeTimelineAnchorRole,
        games: [HomeGameItem],
        date: Date = now
    ) -> HomeTimelineSection {
        HomeTimelineSection(
            id: id,
            date: date,
            title: title,
            subtitle: subtitle,
            anchorRole: role,
            isToday: role == .today || role == .live || role == .laterToday,
            games: games
        )
    }

    static func scoringPlayPresentation(
        rawFeedText: String? = "rush middle for 3 yards, touchdown confirmed by review",
        scoreLabel: String? = "BAY 27, NAR 24"
    ) -> GameEventPresentation {
        GameEventPresentation(
            clockText: "Q4 01:18",
            headline: "Bay Harbor finishes the drive with a short scoring run",
            detail: "The Lights convert after a sustained possession inside the red zone.",
            eventLabel: "Touchdown",
            teamAbbreviation: "BAY",
            teamLabel: "Bay Harbor Lights",
            scoringLabel: "Scoring play",
            scoreLabel: scoreLabel,
            rawFeedText: rawFeedText,
            rawFeedSource: "component-feed",
            accessibilityLabel: "Bay Harbor touchdown. Bay Harbor leads 27 to 24."
        )
    }

    static func eventPresentation(
        clockText: String = "Q2 06:45",
        headline: String,
        detail: String? = "A steady possession creates field position without changing the score.",
        eventLabel: String? = "Drive",
        teamAbbreviation: String? = "NAR",
        teamLabel: String? = "North Arc Riders",
        scoringLabel: String? = nil,
        scoreLabel: String? = nil
    ) -> GameEventPresentation {
        GameEventPresentation(
            clockText: clockText,
            headline: headline,
            detail: detail,
            eventLabel: eventLabel,
            teamAbbreviation: teamAbbreviation,
            teamLabel: teamLabel,
            scoringLabel: scoringLabel,
            scoreLabel: scoreLabel,
            rawFeedText: nil,
            rawFeedSource: nil,
            accessibilityLabel: headline
        )
    }

    static func event(
        sequence: Int,
        importance: GameEventImportance = .primary,
        headline: String = "Bay Harbor creates a late scoring chance",
        detail: String? = "The attack moves quickly through the middle third.",
        eventType: String = "shot_on_goal"
    ) -> GameEvent {
        TestFixtures.makeEvent(
            sequence: sequence,
            importance: importance,
            headline: headline,
            detail: detail,
            periodLabel: "Q4",
            clockLabel: "02:\(String(format: "%02d", sequence))",
            eventType: eventType,
            rawFeedSource: nil
        )
    }

    static func segmentScoreboard(periodCount: Int) -> ScoreboardPresentation {
        let labels = (1...periodCount).map(String.init)
        let segments = labels.map { label in
            ScoreboardSegmentPresentation(id: label, label: label, values: ["away": label == "1" ? "2" : "0", "home": label == "2" ? "3" : "0"])
        }
        return scoreboard(layout: .segmentTable, rows: standardScoreboardRows(), segments: segments, totalHeader: "R")
    }

    static func simpleTotalScoreboard() -> ScoreboardPresentation {
        scoreboard(layout: .simpleTotal, rows: standardScoreboardRows(), segments: [], totalHeader: "T")
    }

    static func soccerScoreboard() -> ScoreboardPresentation {
        scoreboard(
            layout: .soccerSummary,
            rows: [
                ScoreboardRowPresentation(id: "away", title: "North Arc FC", abbreviation: "NAR", side: .away, totalText: "1", recordText: "6-3-2", isWinner: false),
                ScoreboardRowPresentation(id: "home", title: "Bay Harbor FC", abbreviation: "BAY", side: .home, totalText: "2", recordText: "7-2-2", isWinner: true)
            ],
            segments: [],
            totalHeader: "G"
        )
    }

    static func leaderboardScoreboard() -> ScoreboardPresentation {
        scoreboard(
            layout: .leaderboard,
            rows: [
                ScoreboardRowPresentation(id: "one", title: "Mira Vale", abbreviation: nil, side: .other("leader"), totalText: "-12", recordText: "F", isWinner: true),
                ScoreboardRowPresentation(id: "two", title: "Joss Reed", abbreviation: nil, side: .other("contender"), totalText: "-10", recordText: "F", isWinner: false),
                ScoreboardRowPresentation(id: "three", title: "Talen Orr", abbreviation: nil, side: .other("contender"), totalText: "-8", recordText: "17", isWinner: false),
                ScoreboardRowPresentation(id: "four", title: "Niko Park", abbreviation: nil, side: .other("contender"), totalText: "-7", recordText: "16", isWinner: false)
            ],
            segments: [],
            totalHeader: "Score"
        )
    }

    static func scoreboard(
        layout: ScoreboardLayout,
        rows: [ScoreboardRowPresentation],
        segments: [ScoreboardSegmentPresentation],
        totalHeader: String
    ) -> ScoreboardPresentation {
        ScoreboardPresentation(
            layout: layout,
            title: "Box Score",
            systemImage: "number.square",
            revealTitle: "Score hidden",
            revealDescription: "Reveal when ready for the score.",
            revealButtonTitle: "Reveal score",
            hideButtonTitle: "Hide",
            rows: rows,
            segments: segments,
            totalHeader: totalHeader,
            stateText: "Final",
            stateColor: SportsTheme.Colors.secondaryInk,
            accentColor: SportsTheme.Tone.scoreboard.accent
        )
    }

    static func standardScoreboardRows() -> [ScoreboardRowPresentation] {
        [
            ScoreboardRowPresentation(id: "away", title: "North Arc Riders", abbreviation: "NAR", side: .away, totalText: "7", recordText: "12-8", isWinner: true),
            ScoreboardRowPresentation(id: "home", title: "Bay Harbor Lights", abbreviation: "BAY", side: .home, totalText: "6", recordText: "10-10", isWinner: false)
        ]
    }

    static func emptyStatSection() -> StatSectionPresentation {
        StatSectionPresentation(id: "empty-stats", title: "Player pulse", cards: [], emptyMessage: "No player stats available yet.")
    }

    static func mixedStatSection() -> StatSectionPresentation {
        StatSectionPresentation(
            id: "mixed-stats",
            title: "Team pulse",
            highlights: [
                StatHighlightPresentation(id: "mira", rank: 1, title: "Mira Vale", subtitle: "Guard", headline: "Created late possessions and finished through contact.", stats: statPills([("PTS", "24"), ("AST", "8"), ("REB", "6")]), accentTone: .scoring),
                StatHighlightPresentation(id: "joss", rank: 2, title: "Joss Reed", subtitle: "Forward", headline: "Controlled the glass during the deciding stretch.", stats: statPills([("PTS", "15"), ("REB", "12"), ("BLK", "3")]), accentTone: .defensivePitching),
                StatHighlightPresentation(id: "talen", rank: 3, title: "Talen Orr", subtitle: "Wing", headline: "Added pressure without forcing poor looks.", stats: statPills([("PTS", "9"), ("STL", "2")]), accentTone: .newPlay)
            ],
            cards: [
                StatCardPresentation(id: "team-card", title: "Bay Harbor Lights", subtitle: "Team totals", items: statPills([("AST", "23"), ("REB", "44"), ("TO", "9")]))
            ],
            tables: [compactStatTable()],
            emptyMessage: nil
        )
    }

    static func wideStatSection() -> StatSectionPresentation {
        var section = mixedStatSection()
        section.highlights = Array(section.highlights.prefix(1))
        section.tables = [wideStatTable()]
        return section
    }

    static func compactStatTable() -> StatTablePresentation {
        StatTablePresentation(
            id: "compact-table",
            title: "Rotation",
            columns: [
                StatTableColumnPresentation(id: "player", label: "Player", width: 108, alignment: .leading),
                StatTableColumnPresentation(id: "min", label: "MIN", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "pts", label: "PTS", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "plus", label: "+/-", width: 46, alignment: .trailing)
            ],
            rows: [
                StatTableRowPresentation(id: "mira", values: ["player": "Mira Vale", "min": "34", "pts": "24", "plus": "+11"]),
                StatTableRowPresentation(id: "joss", values: ["player": "Joss Reed", "min": "31", "pts": "15", "plus": "+8"]),
                StatTableRowPresentation(id: "talen", values: ["player": "Talen Orr", "min": "22", "pts": "9"])
            ]
        )
    }

    static func wideStatTable() -> StatTablePresentation {
        StatTablePresentation(
            id: "wide-table",
            title: "Full table",
            columns: [
                StatTableColumnPresentation(id: "player", label: "Player", width: 116, alignment: .leading),
                StatTableColumnPresentation(id: "min", label: "MIN", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "pts", label: "PTS", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "reb", label: "REB", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "ast", label: "AST", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "stl", label: "STL", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "blk", label: "BLK", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "to", label: "TO", width: 46, alignment: .trailing),
                StatTableColumnPresentation(id: "plus", label: "+/-", width: 46, alignment: .trailing)
            ],
            rows: [
                StatTableRowPresentation(id: "mira", values: ["player": "Mira Vale", "min": "34", "pts": "24", "reb": "6", "ast": "8", "stl": "2", "blk": "1", "to": "3", "plus": "+11"]),
                StatTableRowPresentation(id: "joss", values: ["player": "Joss Reed", "min": "31", "pts": "15", "reb": "12", "ast": "3", "stl": "1", "blk": "3", "to": "1", "plus": "+8"])
            ]
        )
    }

    static func statPills(_ values: [(String, String)]) -> [StatPillPresentation] {
        values.map { StatPillPresentation(label: $0.0, value: $0.1) }
    }

    static func statDetail() -> GameDetail {
        let game = game(id: 4_900, status: "final", isFinal: true, awayScore: 91, homeScore: 98)
        return GameDetail(
            game: game,
            teamStats: [
                TeamStat(team: "North Arc Riders", isHome: false, stats: ["rebounds": .number(38), "assists": .number(19), "turnovers": .number(14)], normalizedStats: [
                    NormalizedStat(key: "rebounds", displayLabel: "REB", group: nil, value: .number(38)),
                    NormalizedStat(key: "assists", displayLabel: "AST", group: nil, value: .number(19))
                ]),
                TeamStat(team: "Bay Harbor Lights", isHome: true, stats: ["rebounds": .number(44), "assists": .number(23), "turnovers": .number(9)], normalizedStats: [
                    NormalizedStat(key: "rebounds", displayLabel: "REB", group: nil, value: .number(44)),
                    NormalizedStat(key: "assists", displayLabel: "AST", group: nil, value: .number(23))
                ])
            ],
            playerStats: [
                PlayerStat(team: "BAY", playerName: "Mira Vale", minutes: 34, points: 24, rebounds: 6, assists: 8, yards: nil, touchdowns: nil, rawStats: [:]),
                PlayerStat(team: "BAY", playerName: "Joss Reed", minutes: 31, points: 15, rebounds: 12, assists: 3, yards: nil, touchdowns: nil, rawStats: [:]),
                PlayerStat(team: "NAR", playerName: "Talen Orr", minutes: 22, points: 9, rebounds: 4, assists: nil, yards: nil, touchdowns: nil, rawStats: [:])
            ],
            events: [],
            mlbBatters: nil,
            mlbPitchers: nil,
            nhlSkaters: nil,
            nhlGoalies: nil
        )
    }
}
