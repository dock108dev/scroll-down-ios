import SwiftUI

struct GameCardPresentation {
    let leagueLabel: String
    let sportLabel: String
    let accentColor: Color
    let statusText: String
    let headline: String?
    let matchupLabel: String?
    let secondaryText: String?
    let accessibilityLabel: String?
}

struct GameHeaderPresentation {
    let leagueLabel: String
    let sportLabel: String
    let accentColor: Color
    let statusText: String?
    let playCountText: String?
    let headline: String?
    let matchupLabel: String?
    let secondaryText: String?
    let accessibilityLabel: String?
}

struct GameEventPresentation {
    var clockText: String
    var headline: String
    let detail: String?
    var eventLabel: String?
    let teamAbbreviation: String?
    let teamLabel: String?
    let scoringLabel: String?
    var scoreLabel: String?
    let rawFeedText: String?
    let rawFeedSource: String?
    let accessibilityLabel: String?
}

extension GameEventPresentation {
    init(
        event: GameEvent,
        clockText: String? = nil,
        detail: String? = nil,
        scoringFallbackLabel: String = "Scoring"
    ) {
        let isScoring = event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil
        let resolvedClockText = clockText ?? event.clockText
        let resolvedDetail = detail ?? event.detail
        let resolvedScoreLabel = [event.presentation?.scoreLabel].firstNonBlank
            ?? Self.fallbackScoreAfterLabel(for: event, isScoring: isScoring)
        self.init(
            clockText: resolvedClockText,
            headline: event.headline,
            detail: resolvedDetail,
            eventLabel: [
                EventLabelResolver.customerLabel(from: event.presentation?.eventTypeLabel),
                EventLabelResolver.customerLabel(from: event.presentation?.primaryLabel),
                EventLabelResolver.customerLabel(from: event.eventType)
            ].firstNonBlank,
            teamAbbreviation: event.teamAbbreviation,
            teamLabel: event.presentation?.teamLabel,
            scoringLabel: isScoring ? scoringFallbackLabel : nil,
            scoreLabel: resolvedScoreLabel,
            rawFeedText: event.displayRawFeedText,
            rawFeedSource: event.rawFeedSource,
            accessibilityLabel: EventLabelResolver.customerAccessibilityText(
                preferred: event.presentation?.accessibilityLabel,
                fallbackPieces: [
                    resolvedClockText,
                    event.headline,
                    resolvedDetail,
                    event.presentation?.teamLabel,
                    resolvedScoreLabel
                ]
            )
        )
    }

    private static func fallbackScoreAfterLabel(for event: GameEvent, isScoring: Bool) -> String? {
        guard isScoring,
              let away = event.scoreAfter.away,
              let home = event.scoreAfter.home else {
            return nil
        }
        return "\(away)-\(home)"
    }
}

struct ScoreboardPresentation {
    var layout: ScoreboardLayout
    var title: String
    var systemImage: String
    var revealTitle: String
    var revealDescription: String
    var revealButtonTitle: String
    var hideButtonTitle: String
    let rows: [ScoreboardRowPresentation]
    let segments: [ScoreboardSegmentPresentation]
    var totalHeader: String
    let stateText: String?
    let stateColor: Color
    let accentColor: Color
}

enum ScoreboardLayout: Hashable {
    case simpleTotal
    case segmentTable
    case soccerSummary
    case leaderboard
}

struct ScoreboardRowPresentation: Identifiable, Hashable {
    let id: String
    let title: String
    let abbreviation: String?
    let side: GameParticipantRole
    let totalText: String
    let recordText: String?
    let isWinner: Bool
}

struct ScoreboardSegmentPresentation: Identifiable, Hashable {
    let id: String
    let label: String
    let values: [String: String]
}

struct GameStatsPresentation {
    let playerSections: [StatSectionPresentation]
    let teamSection: StatSectionPresentation
}

struct StatSectionPresentation: Identifiable, Hashable {
    let id: String
    let title: String?
    var highlights: [StatHighlightPresentation] = []
    var comparison: StatComparisonPresentation? = nil
    let cards: [StatCardPresentation]
    var tables: [StatTablePresentation] = []
    let emptyMessage: String?
}

struct StatCardPresentation: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let items: [StatPillPresentation]
}

struct StatPillPresentation: Identifiable, Hashable {
    var id: String { label }

    let label: String
    let value: String
}

struct StatHighlightPresentation: Identifiable, Hashable {
    let id: String
    let rank: Int?
    let title: String
    let subtitle: String
    let headline: String
    let stats: [StatPillPresentation]
    let accentTone: SportsTheme.Tone
}

struct StatComparisonPresentation: Identifiable, Hashable {
    let id: String
    let title: String
    let columns: [StatComparisonColumnPresentation]
    let rows: [StatComparisonRowPresentation]
}

struct StatComparisonColumnPresentation: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
}

struct StatComparisonRowPresentation: Identifiable, Hashable {
    let id: String
    let label: String
    let values: [String: String]
}

struct StatTablePresentation: Identifiable, Hashable {
    let id: String
    let title: String
    let columns: [StatTableColumnPresentation]
    let rows: [StatTableRowPresentation]
}

struct StatTableColumnPresentation: Identifiable, Hashable {
    let id: String
    let label: String
    let width: CGFloat
    let alignment: StatTableColumnAlignment
}

enum StatTableColumnAlignment: Hashable {
    case leading
    case trailing
}

struct StatTableRowPresentation: Identifiable, Hashable {
    let id: String
    let values: [String: String]
}
