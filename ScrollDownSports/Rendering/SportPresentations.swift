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
    let headline: String
    let detail: String?
    let eventLabel: String?
    let teamAbbreviation: String?
    let teamLabel: String?
    let scoringLabel: String?
    let scoreLabel: String?
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
        self.init(
            clockText: clockText ?? event.clockText,
            headline: event.headline,
            detail: detail ?? event.detail,
            eventLabel: event.presentation?.eventTypeLabel ?? event.presentation?.primaryLabel ?? event.eventType,
            teamAbbreviation: event.teamAbbreviation,
            teamLabel: event.presentation?.teamLabel,
            scoringLabel: isScoring ? event.presentation?.primaryLabel ?? scoringFallbackLabel : nil,
            scoreLabel: event.presentation?.scoreLabel,
            rawFeedText: event.displayRawFeedText,
            rawFeedSource: event.rawFeedSource,
            accessibilityLabel: event.presentation?.accessibilityLabel
        )
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
