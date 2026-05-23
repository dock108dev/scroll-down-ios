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
            headline: game.presentation?.headline ?? game.presentation?.shortHeadline,
            matchupLabel: game.matchupText,
            secondaryText: game.presentation?.secondaryLabel ?? game.presentation?.subheadline,
            accessibilityLabel: game.presentation?.accessibilityLabel
        )
    }

    func gameHeaderPresentation(for game: Game) -> GameHeaderPresentation {
        GameHeaderPresentation(
            leagueLabel: theme.leagueCode,
            sportLabel: theme.sportLabel,
            accentColor: theme.accentColor,
            statusText: statusText(for: game),
            playCountText: game.progress.eventCount.map { "\($0) plays" },
            headline: game.presentation?.headline ?? game.presentation?.shortHeadline,
            matchupLabel: game.matchupText,
            secondaryText: game.presentation?.secondaryLabel ?? game.presentation?.subheadline,
            accessibilityLabel: game.presentation?.accessibilityLabel
        )
    }

    func eventPresentation(for event: GameEvent) -> GameEventPresentation {
        GameEventPresentation(event: event)
    }

    func periodGroupLabel(for event: GameEvent) -> String {
        normalizedPeriodLabel(periodOrdinal: event.periodOrdinal, periodLabel: event.periodLabel) ?? "Game"
    }

    func periodGroupKey(for event: GameEvent) -> String {
        if let periodLabel = cleanedLabel(event.periodLabel) {
            return "period:\(periodLabel.normalizedPeriodKey)"
        }
        if let periodOrdinal = event.periodOrdinal {
            return "period:\(normalizedLeagueCode.lowercased()):\(periodOrdinal)"
        }
        return "period:game"
    }

    func rowClockText(for event: GameEvent, periodGroupLabel: String?) -> String {
        guard let rawClock = cleanedLabel(event.presentation?.timeLabel) ?? cleanedLabel(event.clockLabel) else {
            return ""
        }
        guard let periodGroupLabel = cleanedLabel(periodGroupLabel) else {
            return rawClock
        }
        return rawClock.removingPeriodPrefix(periodGroupLabel)
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
            hideButtonTitle: "Hide score",
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
        [
            normalizedPeriodLabel(periodOrdinal: periodOrdinal, periodLabel: periodLabel),
            clockLabel?.nilIfEmpty
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }

    func normalizedPeriodLabel(periodOrdinal: Int?, periodLabel: String?) -> String? {
        if let periodLabel = cleanedLabel(periodLabel) {
            return periodLabel
        }
        return periodOrdinal.map { fallbackPeriodLabel(for: $0) }
    }

    func teamStatSection(for detail: GameDetail) -> StatSectionPresentation {
        StatPresentationBuilder.teamStatSection(for: detail)
    }

    func genericPlayerSections(for detail: GameDetail) -> [StatSectionPresentation] {
        StatPresentationBuilder.genericPlayerSections(for: detail)
    }

    func statusText(for game: Game) -> String {
        if let label = game.presentation?.statusLabel ?? game.presentation?.primaryLabel {
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

    private func fallbackPeriodLabel(for period: Int) -> String {
        switch normalizedLeagueCode {
        case "NBA", "WNBA", "NFL", "NCAAF", "NCAAFB", "NCAAB", "NCAAMB", "NCAAWB":
            if period <= 4 {
                return "Q\(period)"
            }
            if period == 5 {
                return "OT"
            }
            return "\(period - 4)OT"
        case "NHL":
            if period == 1 { return "1st" }
            if period == 2 { return "2nd" }
            if period == 3 { return "3rd" }
            if period == 4 { return "OT" }
            return "\(period - 3)OT"
        case "MLB":
            return ordinal(period)
        default:
            return "Period \(period)"
        }
    }

    private func ordinal(_ value: Int) -> String {
        let suffix: String
        if (11...13).contains(value % 100) {
            suffix = "th"
        } else {
            switch value % 10 {
            case 1:
                suffix = "st"
            case 2:
                suffix = "nd"
            case 3:
                suffix = "rd"
            default:
                suffix = "th"
            }
        }
        return "\(value)\(suffix)"
    }

    private func cleanedLabel(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty,
              trimmed != "-"
        else {
            return nil
        }
        return trimmed
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }

    var normalizedPeriodKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    func removingPeriodPrefix(_ period: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let periodTrimmed = period.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !periodTrimmed.isEmpty else { return trimmed }
        if trimmed == periodTrimmed {
            return ""
        }

        for separator in [" · ", " - ", ": ", " "] {
            let prefix = periodTrimmed + separator
            if trimmed.hasPrefix(prefix) {
                return String(trimmed.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return trimmed
    }
}
