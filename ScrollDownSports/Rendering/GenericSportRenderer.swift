import SwiftUI

struct GenericSportRenderer: SportRenderer {
    let leagueCode: String
    let sportLabel: String

    init(leagueCode: String, sportLabel: String? = nil) {
        self.leagueCode = leagueCode
        self.sportLabel = sportLabel ?? Sport(leagueCode: leagueCode).displayName
    }

    var theme: SportRenderingTheme {
        SportRenderingTheme(
            leagueCode: normalizedLeagueCode,
            sportLabel: sportLabel,
            accentColor: accentColor(for: normalizedLeagueCode),
            liveColor: SportsTheme.Tone.live.accent,
            scoreRevealColor: SportsTheme.Tone.scoreboard.accent,
            primarySystemImage: "sportscourt"
        )
    }

    func gameCardPresentation(for game: Game) -> GameCardPresentation {
        GameCardPresentation(
            leagueLabel: theme.leagueCode,
            sportLabel: theme.sportLabel,
            accentColor: theme.accentColor,
            statusText: statusText(for: game),
            headline: topRegionText(game.presentation?.headline ?? game.presentation?.shortHeadline, for: game),
            matchupLabel: ScoreSpoilerFilter.matchupText(for: game),
            secondaryText: topRegionText(game.presentation?.secondaryLabel ?? game.presentation?.subheadline, for: game),
            accessibilityLabel: topRegionText(game.presentation?.accessibilityLabel, for: game)
        )
    }

    func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation {
        GameHeaderPresentation(
            leagueLabel: theme.leagueCode,
            sportLabel: theme.sportLabel,
            accentColor: theme.accentColor,
            statusText: statusText(for: game),
            playCountText: game.progress.eventCount.map { "\($0) plays" },
            headline: topRegionText(game.presentation?.headline ?? game.presentation?.shortHeadline, for: game),
            matchupLabel: ScoreSpoilerFilter.matchupText(for: game),
            secondaryText: topRegionText(game.presentation?.secondaryLabel ?? game.presentation?.subheadline, for: game),
            accessibilityLabel: topRegionText(game.presentation?.accessibilityLabel, for: game)
        )
    }

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(event: event)
    }

    func periodGroupLabel(for event: GameEvent) -> String {
        periodOutput(for: event).groupLabel ?? "Game"
    }

    func periodGroupKey(for event: GameEvent) -> String {
        periodOutput(for: event).groupKey
    }

    func rowClockText(for event: GameEvent, periodGroupLabel: String?) -> String {
        periodOutput(for: event).rowClockText
    }

    func scoreboardPresentation(for game: Game) -> ScoreboardPresentation {
        let layout = scoreboardLayout(for: game)
        return ScoreboardPresentation(
            layout: layout,
            title: "Box Score",
            systemImage: "number.square",
            revealTitle: "Score hidden",
            revealDescription: "Reveal only when you are ready to see the current or final box score.",
            revealButtonTitle: "Reveal box score",
            hideButtonTitle: "Hide",
            rows: scoreboardRows(for: game),
            segments: scoreboardSegments(for: game),
            totalHeader: totalHeader(for: game),
            stateText: game.scoreboard?.scoreline ?? game.scoreboard?.statusLabel ?? scoreboardStateText(for: game),
            stateColor: game.status.isLive ? theme.liveColor : SportsTheme.Colors.secondaryInk,
            accentColor: theme.scoreRevealColor
        )
    }

    func statsPresentation(for detail: GameDetail) -> GameStatsPresentation {
        GameStatsPresentation(
            playerSections: genericPlayerSections(for: detail),
            teamSection: teamStatSection(for: detail)
        )
    }

    func periodClockText(periodOrdinal: Int?, periodLabel: String?, clockLabel: String?) -> String {
        PeriodLabelFormatter.output(
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            periodOrdinal: periodOrdinal,
            periodLabel: periodLabel,
            clockLabel: clockLabel
        ).combinedText ?? ""
    }

    func teamStatSection(for detail: GameDetail) -> StatSectionPresentation {
        StatPresentationBuilder.teamStatSection(for: detail)
    }

    func genericPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        StatPresentationBuilder.genericPlayerSections(for: detail)
    }

    func statusText(for game: Game) -> String {
        if let label = topRegionText(game.presentation?.statusLabel ?? game.presentation?.primaryLabel, for: game) {
            return label
        }
        if game.status.isLive {
            return periodClockText(
                periodOrdinal: game.progress.periodOrdinal,
                periodLabel: game.progress.periodLabel,
                clockLabel: game.progress.clockLabel
            ).nilIfEmpty ?? "In progress"
        }
        if game.status.isPregame {
            return "Scheduled"
        }
        if game.status.isFinal {
            return "Final"
        }
        return "Catch up"
    }

    func scoreboardRows(for game: Game) -> [ScoreboardRowPresentation] {
        if let competitors = game.scoreboard?.competitors, !competitors.isEmpty {
            return competitors.map { competitor in
                ScoreboardRowPresentation(
                    id: competitor.id,
                    title: competitor.teamName,
                    abbreviation: competitor.teamAbbreviation,
                    side: competitor.side,
                    totalText: scoreboardTotalText(for: competitor, scoreboard: game.scoreboard),
                    recordText: competitor.recordText,
                    isWinner: competitor.isWinner == true
                )
            }
        }
        return game.participants.map { participant in
            ScoreboardRowPresentation(
                id: participant.id,
                title: participant.name,
                abbreviation: participant.abbreviation,
                side: participant.role,
                totalText: game.scoreState.score(for: participant.role).map(String.init) ?? "-",
                recordText: nil,
                isWinner: false
            )
        }
    }

    func scoreboardSegments(for game: Game) -> [ScoreboardSegmentPresentation] {
        guard let segments = game.scoreboard?.segments, !segments.isEmpty else {
            return []
        }
        return segments.enumerated().map { index, segment in
            ScoreboardSegmentPresentation(
                id: "\(index)-\(segment.label)",
                label: segment.label,
                values: [
                    "away": segment.away ?? "-",
                    "home": segment.home ?? "-"
                ]
            )
        }
    }

    private var normalizedLeagueCode: String {
        let trimmed = leagueCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "SPORT" : trimmed.uppercased()
    }

    private func periodOutput(for event: GameEvent) -> PeriodLabelOutput {
        PeriodLabelFormatter.output(
            sport: Sport(leagueCode: leagueCode),
            leagueCode: leagueCode,
            periodOrdinal: event.periodOrdinal,
            periodLabel: event.periodLabel,
            clockLabel: event.clockLabel,
            presentationTimeLabel: event.presentation?.timeLabel
        )
    }

    private func scoreboardStateText(for game: Game) -> String? {
        if game.status.isLive {
            return statusText(for: game)
        }
        if game.status.isFinal {
            return "Final"
        }
        if game.status.isPregame {
            return "Scheduled"
        }
        return nil
    }

    private func scoreboardLayout(for game: Game) -> ScoreboardLayout {
        let rawLayout = game.scoreboard?.layout?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch rawLayout {
        case "leaderboard", "leaderboard_result", "leaderboard_results":
            return .leaderboard
        case "soccer", "soccer_summary", "goals_summary":
            return .soccerSummary
        case "period_table", "segment_table", "inning_table", "line_score", "quarter_table":
            return game.scoreboard?.segments.isEmpty == false ? .segmentTable : .simpleTotal
        default:
            return game.scoreboard?.segments.isEmpty == false ? .segmentTable : .simpleTotal
        }
    }

    private func totalHeader(for game: Game) -> String {
        switch game.sport {
        case .mlb:
            return "R"
        case .golf:
            return "Score"
        default:
            return "T"
        }
    }

    private func scoreboardTotalText(for competitor: ScoreboardCompetitorData, scoreboard: GameScoreboardData?) -> String {
        let totals = scoreboard?.totals
        let sideTotal: String?
        switch competitor.side {
        case .away:
            sideTotal = totals?.away
        case .home:
            sideTotal = totals?.home
        case .other:
            sideTotal = nil
        }
        return sideTotal ?? competitor.scoreText ?? competitor.score.map(String.init) ?? "-"
    }

    private func topRegionText(_ value: String?, for game: Game) -> String? {
        ScoreSpoilerFilter.topRegionText(value, for: game)
    }

    private func accentColor(for leagueCode: String) -> Color {
        switch leagueCode {
        case "MLB":
            return Color(red: 0.376, green: 0.463, blue: 0.224)
        case "NBA", "WNBA":
            return Color(red: 0.741, green: 0.318, blue: 0.125)
        case "NHL":
            return Color(red: 0.148, green: 0.390, blue: 0.511)
        case "NFL":
            return Color(red: 0.178, green: 0.246, blue: 0.514)
        case "NCAAB":
            return Color(red: 0.475, green: 0.251, blue: 0.541)
        case "NCAAF":
            return Color(red: 0.560, green: 0.310, blue: 0.153)
        default:
            return Color(red: 0.200, green: 0.358, blue: 0.494)
        }
    }
}
