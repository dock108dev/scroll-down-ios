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

struct GameEventPresentation: Hashable {
    var clockText: String
    var leadIn: String? = nil
    var headline: String
    let detail: String?
    var contextItems: [PlayCardContextItemPresentation] = []
    var resultItems: [PlayCardResultItemPresentation] = []
    var eventLabel: String?
    let teamAbbreviation: String?
    let teamLabel: String?
    let scoringLabel: String?
    var scoreLabel: String?
    let rawFeedText: String?
    let rawFeedSource: String?
    var rawFeedDisclosureTitle: String? = nil
    let accessibilityLabel: String?
    var accessibilityValue: String? = nil
    var accessibilityHint: String? = nil
    var situation: GameEventSituationPresentation? = nil
    var situationAccessibilityText: String? = nil
    var isNormalizedCard: Bool = false
}

struct GameEventSituationPresentation: Hashable {
    let title: String
    let periodText: String?
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: GameEventSituationSport
    let layout: GameEventSituationLayout
    let ownership: GameEventSituationOwnership?
    let diagram: GameEventSituationDiagram?
    let accent: GameEventSituationAccent
    let dataConfidence: GameEventSituationDataConfidence

    var isEmpty: Bool {
        [
            periodText,
            setupText,
            contextLine,
            pressureLine,
            ownership?.displayLabel
        ].compactMap { $0?.nilIfBlank }.isEmpty
            && diagram == nil
    }
}

enum GameEventSituationSport: String, Hashable {
    case baseball
    case football
    case hockey
    case basketball
    case soccer
    case golf
    case tennis
    case generic
}

enum GameEventSituationLayout: String, Hashable {
    case baseball
    case football
    case hockey
    case basketball
    case soccer
    case golf
    case tennis
    case pressureBoardFallback
}

struct GameEventSituationOwnership: Hashable {
    let role: GameEventSituationOwnershipRole
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?
    let confidence: GameEventSituationOwnershipConfidence

    var claimsPossession: Bool {
        role == .possession
    }

    var displayLabel: String {
        [
            role.displayName,
            teamAbbreviation?.nilIfBlank ?? teamLabel?.nilIfBlank ?? participantRole?.displayName
        ].compactMap(\.self)
            .joined(separator: " ")
    }
}

enum GameEventSituationOwnershipRole: String, Hashable {
    case batting
    case possession
    case offense
    case defense
    case attackingSide
    case association

    var displayName: String {
        switch self {
        case .batting:
            return "Batting"
        case .possession:
            return "Possession"
        case .offense:
            return "Offense"
        case .defense:
            return "Defense"
        case .attackingSide:
            return "Attacking"
        case .association:
            return "Team"
        }
    }
}

enum GameEventSituationOwnershipConfidence: String, Hashable {
    case explicit
    case derivedFromPeriod
    case eventFallback
    case unknown
}

enum GameEventSituationDiagram: Hashable {
    case baseballDiamond(BaseballSituationDiagram)
    case footballFieldStrip(FootballFieldStripDiagram)
    case hockeyRinkStrip(HockeyRinkStripDiagram)
    case basketballHalfCourt(BasketballHalfCourtDiagram)
    case soccerPitchStrip(SoccerPitchStripDiagram)
    case pressureBoardFallback(PressureBoardSituationDiagram)
}

struct BaseballSituationDiagram: Hashable {
    let occupiedBases: Set<BaseballBase>
    let batting: GameEventSituationOwnership?
    let outs: Int?
    let count: String?
}

enum BaseballBase: String, CaseIterable, Hashable {
    case first
    case second
    case third

    var shortLabel: String {
        switch self {
        case .first:
            return "1B"
        case .second:
            return "2B"
        case .third:
            return "3B"
        }
    }

    var accessibilityName: String {
        switch self {
        case .first:
            return "first"
        case .second:
            return "second"
        case .third:
            return "third"
        }
    }
}

struct PressureBoardSituationDiagram: Hashable {
    let associations: [GameEventSituationOwnership]
    let metrics: [PressureBoardSituationMetric]

    init(
        associations: [GameEventSituationOwnership],
        metrics: [PressureBoardSituationMetric] = []
    ) {
        self.associations = associations
        self.metrics = metrics
    }
}

struct HockeyRinkStripDiagram: Hashable {
    let zone: HockeyRinkZone
    let puckLocation: HockeyPuckLocation?
    let attackingTeamAbbreviation: String?
}

enum HockeyRinkZone: String, Hashable, Sendable {
    case offensive
    case neutral
    case defensive

    var label: String {
        switch self {
        case .offensive:
            return "Offensive zone"
        case .neutral:
            return "Neutral zone"
        case .defensive:
            return "Defensive zone"
        }
    }
}

enum HockeyPuckLocation: String, Hashable, Sendable {
    case slot
    case highSlot
    case leftCircle
    case rightCircle
    case point
    case crease
    case behindNet

    var label: String {
        switch self {
        case .slot:
            return "Slot"
        case .highSlot:
            return "High slot"
        case .leftCircle:
            return "Left circle"
        case .rightCircle:
            return "Right circle"
        case .point:
            return "Point"
        case .crease:
            return "Crease"
        case .behindNet:
            return "Behind net"
        }
    }
}

struct PressureBoardSituationMetric: Hashable {
    let label: String
    let value: String
    let emphasis: PressureBoardSituationMetricEmphasis
}

enum PressureBoardSituationMetricEmphasis: Hashable {
    case primary
    case team
    case pressure
    case secondary
}

struct GameEventSituationAccent: Hashable {
    let ownership: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?
    let tone: SportsTheme.Tone

    var color: Color {
        SportsTheme.Team.accent(for: teamAbbreviation, fallback: tone.accent)
    }
}

enum GameEventSituationDataConfidence: String, Hashable {
    case explicitPreEvent
    case explicitGenericEventContext
    case derivedState
    case ambiguousMetadata
    case missingState
    case contract
    case feedProvided
    case inferred
    case fallback
}

extension GameEventPresentation {
    init(
        event: GameEvent,
        clockText: String? = nil,
        detail: String? = nil,
        situation: GameEventSituationPresentation? = nil,
        usesEventDetailFallback: Bool = true,
        scoringFallbackLabel: String = "Scoring"
    ) {
        let isScoring = event.importanceMetadata?.isScoringPlay == true || event.scoreDelta != nil
        let resolvedClockText = clockText ?? event.clockText
        let resolvedDetail = detail ?? (usesEventDetailFallback ? event.detail : nil)
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
            ),
            situation: situation,
            situationAccessibilityText: situation?.accessibilitySummary
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

extension GameEventSituationPresentation {
    var resultContextPieces: [String] {
        [
            pressureLine,
            contextLine
        ].compactMap { $0?.nilIfBlank }
    }

    var accessibilitySummary: String? {
        SituationAccessibilitySummary.make(for: self)
    }
}

private extension GameParticipantRole {
    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .away:
            return "Away"
        case .other(let value):
            return value
        }
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
