import Foundation

struct GameEvent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let sourceEventID: String?
    let sequence: Int
    let periodOrdinal: Int?
    let periodLabel: String?
    let clockLabel: String?
    let teamOwnership: GameParticipantRole?
    let teamAbbreviation: String?
    let eventType: String?
    let contentDepth: EventContentDepth?
    let importance: GameEventImportance
    let eligibleModes: Set<GameMode>
    let usesBackendModeEligibility: Bool
    let presentation: EventPresentationData?
    let normalizedCard: NormalizedPlayCard?
    let importanceMetadata: EventImportanceData?
    let headline: String
    let detail: String?
    let rawText: String?
    let rawFeedSource: String?
    let rawFeedUpdatedAt: String?
    let scoreBefore: ScoreState?
    let scoreAfter: ScoreState
    let scoreDelta: ScoreDelta?
    let situationBefore: GameEventSituationSnapshot?
    let situationAfter: GameEventSituationSnapshot?
    let sportMetadata: [String: JSONValue]

    init(
        id: String,
        sourceEventID: String?,
        sequence: Int,
        periodOrdinal: Int?,
        periodLabel: String?,
        clockLabel: String?,
        teamOwnership: GameParticipantRole?,
        teamAbbreviation: String?,
        eventType: String?,
        contentDepth: EventContentDepth? = nil,
        importance: GameEventImportance,
        eligibleModes: Set<GameMode>,
        usesBackendModeEligibility: Bool,
        presentation: EventPresentationData?,
        normalizedCard: NormalizedPlayCard? = nil,
        importanceMetadata: EventImportanceData?,
        headline: String,
        detail: String?,
        rawText: String?,
        rawFeedSource: String?,
        rawFeedUpdatedAt: String?,
        scoreBefore: ScoreState?,
        scoreAfter: ScoreState,
        scoreDelta: ScoreDelta?,
        situationBefore: GameEventSituationSnapshot? = nil,
        situationAfter: GameEventSituationSnapshot? = nil,
        sportMetadata: [String: JSONValue]
    ) {
        self.id = id
        self.sourceEventID = sourceEventID
        self.sequence = sequence
        self.periodOrdinal = periodOrdinal
        self.periodLabel = periodLabel
        self.clockLabel = clockLabel
        self.teamOwnership = teamOwnership
        self.teamAbbreviation = teamAbbreviation
        self.eventType = eventType
        self.contentDepth = contentDepth
        self.importance = importance
        self.eligibleModes = eligibleModes
        self.usesBackendModeEligibility = usesBackendModeEligibility
        self.presentation = presentation
        self.normalizedCard = normalizedCard
        self.importanceMetadata = importanceMetadata
        self.headline = headline
        self.detail = detail
        self.rawText = rawText
        self.rawFeedSource = rawFeedSource
        self.rawFeedUpdatedAt = rawFeedUpdatedAt
        self.scoreBefore = scoreBefore
        self.scoreAfter = scoreAfter
        self.scoreDelta = scoreDelta
        self.situationBefore = situationBefore
        self.situationAfter = situationAfter
        self.sportMetadata = sportMetadata
    }

    var clockText: String {
        if let timeLabel = presentation?.timeLabel?.nilIfBlank {
            return timeLabel
        }
        return normalizedPeriodClockText(periodLabel: periodLabel, clockLabel: clockLabel) ?? ""
    }

    var normalizedSourceEventID: String? {
        sourceEventID?.nilIfBlank
    }

    var normalizedCardID: String? {
        normalizedCard?.cardID?.nilIfBlank
    }

    var readingHistoryCardID: String {
        normalizedCardID ?? normalizedSourceEventID ?? id
    }

    var diffKey: GameEventDiffKey {
        if let normalizedSourceEventID {
            return GameEventDiffKey(kind: .sourceEventID, value: normalizedSourceEventID, sequence: sequence)
        }
        return GameEventDiffKey(kind: .sequence, value: String(sequence), sequence: sequence)
    }
}

enum GameEventImportance: Codable, Hashable, Sendable {
    case primary
    case secondary
    case contextual
}

enum GameDetailSource: String, Codable, Hashable, Sendable {
    case normalizedFeed
}

enum GameFeedGenerationStatus: String, Codable, Hashable, Sendable {
    case unknown
    case noPbpYet
    case unsupportedSport
    case generationPending
    case validationBlocked
    case staleRegenerating
    case ready
}

enum GameFeedFallbackState: String, Codable, Hashable, Sendable {
    case none
    case safeEmpty
}

struct GameDetailFeedMetadata: Codable, Hashable, Sendable {
    let source: GameDetailSource
    let generationStatus: GameFeedGenerationStatus
    let fallbackState: GameFeedFallbackState

    static let normalizedFeed = GameDetailFeedMetadata(
        source: .normalizedFeed,
        generationStatus: .unknown,
        fallbackState: .none
    )
}

struct GameDetail: Codable, Hashable, Sendable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let events: [GameEvent]
    let mlbBatters: [MLBBatterStat]?
    let mlbPitchers: [MLBPitcherStat]?
    let nhlSkaters: [NHLPlayerStat]?
    let nhlGoalies: [NHLPlayerStat]?
    var feedMetadata: GameDetailFeedMetadata = .normalizedFeed

    var leagueCode: String {
        game.leagueCode.lowercased()
    }

    func withFeedMetadata(_ metadata: GameDetailFeedMetadata) -> GameDetail {
        var detail = self
        detail.feedMetadata = metadata
        return detail
    }
}
