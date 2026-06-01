import Foundation

enum Sport: Codable, Hashable, Sendable {
    case mlb
    case nfl
    case nba
    case nhl
    case soccer
    case golf
    case tennis
    case other(String)

    init(leagueCode: String) {
        switch leagueCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "mlb":
            self = .mlb
        case "nfl":
            self = .nfl
        case "nba":
            self = .nba
        case "nhl":
            self = .nhl
        case "soccer", "mls", "epl", "premier_league":
            self = .soccer
        case "golf", "pga", "lpga":
            self = .golf
        case "tennis", "atp", "wta":
            self = .tennis
        case let value where !value.isEmpty:
            self = .other(value)
        default:
            self = .other("unknown")
        }
    }
}

struct Game: Codable, Identifiable, Hashable, Sendable {
    typealias ID = Int

    let id: ID
    let sport: Sport
    let leagueCode: String
    let scheduledStart: Date
    let localDateLabel: String?
    let status: GameStatus
    let participants: [GameParticipant]
    let scoreState: ScoreState
    let presentation: GamePresentationData?
    let scoreboard: GameScoreboardData?
    let progress: GameProgress
    let availableFeatures: GameAvailableFeatures

    var homeParticipant: GameParticipant? { participants.first { $0.role == .home } }
    var awayParticipant: GameParticipant? { participants.first { $0.role == .away } }
    var matchupText: String {
        presentation?.matchupLabel ?? "\(awayParticipant?.name ?? "Away") at \(homeParticipant?.name ?? "Home")"
    }
}

struct GameParticipant: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: GameParticipantRole
    let name: String
    let abbreviation: String?

    var favoriteTeamID: String? {
        let value = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value != "home", value != "away" else { return nil }
        return value
    }
}

enum GameParticipantRole: Codable, Hashable, Sendable {
    case home
    case away
    case other(String)
}

struct ScoreState: Codable, Hashable, Sendable {
    let participantScores: [ParticipantScore]

    var home: Int? { score(for: .home) }
    var away: Int? { score(for: .away) }
    var hasAnyScore: Bool { participantScores.contains { $0.score != nil } }

    func score(for role: GameParticipantRole) -> Int? {
        participantScores.first { $0.participantRole == role }?.score
    }
}

struct ParticipantScore: Codable, Hashable, Sendable {
    let participantID: String
    let participantRole: GameParticipantRole
    let score: Int?
}

struct ScoreDelta: Codable, Hashable, Sendable {
    let participantID: String?
    let participantRole: GameParticipantRole?
    let before: Int?
    let after: Int?
    let change: Int?
}

struct NormalizedPlayCard: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let cardID: String?
    let visualImportance: NormalizedPlayCardImportance
    let accent: NormalizedPlayCardAccent?
    let clock: NormalizedPlayCardText?
    let leadIn: NormalizedPlayCardText?
    let headline: NormalizedPlayCardText
    let body: NormalizedPlayCardText?
    let contextItems: [NormalizedPlayCardContextItem]
    let resultItems: [NormalizedPlayCardResultItem]
    let score: NormalizedPlayCardScore?
    let team: NormalizedPlayCardTeam?
    let situation: NormalizedPlayCardSituation?
    let rawFeed: NormalizedPlayCardRawFeed?
    let accessibility: NormalizedPlayCardAccessibility

    init(
        schemaVersion: Int,
        cardID: String?,
        visualImportance: NormalizedPlayCardImportance,
        accent: NormalizedPlayCardAccent?,
        clock: NormalizedPlayCardText?,
        leadIn: NormalizedPlayCardText? = nil,
        headline: NormalizedPlayCardText,
        body: NormalizedPlayCardText?,
        contextItems: [NormalizedPlayCardContextItem],
        resultItems: [NormalizedPlayCardResultItem],
        score: NormalizedPlayCardScore?,
        team: NormalizedPlayCardTeam?,
        situation: NormalizedPlayCardSituation?,
        rawFeed: NormalizedPlayCardRawFeed?,
        accessibility: NormalizedPlayCardAccessibility
    ) {
        self.schemaVersion = schemaVersion
        self.cardID = cardID
        self.visualImportance = visualImportance
        self.accent = accent
        self.clock = clock
        self.leadIn = leadIn
        self.headline = headline
        self.body = body
        self.contextItems = contextItems
        self.resultItems = resultItems
        self.score = score
        self.team = team
        self.situation = situation
        self.rawFeed = rawFeed
        self.accessibility = accessibility
    }
}

enum NormalizedPlayCardImportance: String, Codable, Hashable, Sendable {
    case critical
    case high
    case medium
    case low
}

enum NormalizedPlayCardTone: String, Codable, Hashable, Sendable {
    case neutral
    case secondary
    case scoring
    case critical
    case possession
    case context
    case muted
}

struct NormalizedPlayCardAccent: Codable, Hashable, Sendable {
    let tone: NormalizedPlayCardTone?
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
}

struct NormalizedPlayCardText: Codable, Hashable, Sendable {
    let text: String
    let tone: NormalizedPlayCardTone?
    let maxLines: Int?
}

struct NormalizedPlayCardContextItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let kind: NormalizedPlayCardContextKind
    let text: String
    let tone: NormalizedPlayCardTone?
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
}

enum NormalizedPlayCardContextKind: String, Codable, Hashable, Sendable {
    case clock
    case teamBadge
    case eventLabel
    case status
    case metadata
}

struct NormalizedPlayCardResultItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let text: String
    let tone: NormalizedPlayCardTone?
    let priority: Int
}

struct NormalizedPlayCardScore: Codable, Hashable, Sendable {
    let label: String?
    let value: String?
    let isScoringPlay: Bool
    let spoilerPolicy: NormalizedPlayCardSpoilerPolicy
}

enum NormalizedPlayCardSpoilerPolicy: String, Codable, Hashable, Sendable {
    case alwaysShow
    case hideUntilReveal
    case finalOnly
}

struct NormalizedPlayCardTeam: Codable, Hashable, Sendable {
    let participantRole: GameParticipantRole?
    let abbreviation: String?
    let displayName: String?
    let label: String?
}

struct NormalizedPlayCardSituation: Codable, Hashable, Sendable {
    let title: String
    let periodText: String?
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: String
    let layout: String
    let ownership: NormalizedPlayCardSituationOwnership?
    let accent: NormalizedPlayCardAccent?
    let dataConfidence: String
}

struct NormalizedPlayCardSituationOwnership: Codable, Hashable, Sendable {
    let role: String
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?
    let confidence: String
}

struct NormalizedPlayCardRawFeed: Codable, Hashable, Sendable {
    let text: String?
    let source: String?
    let updatedAt: String?
    let disclosureTitle: String?
}

struct NormalizedPlayCardAccessibility: Codable, Hashable, Sendable {
    let label: String
    let value: String?
    let hint: String?
    let situationSummary: String?
}

struct GameStatus: Codable, Hashable, Sendable {
    let rawValue: String
    let displayStateOverride: String?

    init(rawValue: String, displayStateOverride: String? = nil) {
        self.rawValue = rawValue
        self.displayStateOverride = displayStateOverride
    }

    var phase: GameStatusPhase {
        if let displayStatePhase {
            return displayStatePhase
        }
        if isLive { return .live }
        if isFinal { return .final }
        if ["scheduled", "pregame"].contains(normalized) { return .pregame }
        return .unknown(rawValue)
    }

    var isLive: Bool {
        if let displayState = normalizedDisplayState {
            return ["live", "halftime", "intermission"].contains(displayState)
        }
        return ["in_progress", "live"].contains(normalized)
    }

    var isFinal: Bool {
        if let displayState = normalizedDisplayState {
            return displayState == "final"
        }
        return ["completed", "final"].contains(normalized)
    }

    var isPregame: Bool {
        if let displayState = normalizedDisplayState {
            return ["scheduled", "pregame"].contains(displayState)
        }
        return ["scheduled", "pregame"].contains(normalized)
    }

    private var normalized: String { rawValue.lowercased() }
    private var normalizedDisplayState: String? { displayStateOverride?.lowercased().nilIfBlank }

    private var displayStatePhase: GameStatusPhase? {
        guard let normalizedDisplayState else { return nil }
        if ["scheduled", "pregame"].contains(normalizedDisplayState) {
            return .pregame
        }
        if ["live", "halftime", "intermission"].contains(normalizedDisplayState) {
            return .live
        }
        if normalizedDisplayState == "final" {
            return .final
        }
        return .unknown(displayStateOverride ?? rawValue)
    }
}

enum GameStatusPhase: Codable, Hashable, Sendable {
    case pregame
    case live
    case final
    case unknown(String)
}

struct GameAvailableFeatures: Codable, Hashable, Sendable {
    let hasTimeline: Bool
    let hasStats: Bool
    let hasScoreboard: Bool
}

enum GameMode: String, Codable, Hashable, Sendable {
    case timeline
    case flow
    case stream
    case stats
    case scoreboard
}

struct GameProgress: Codable, Hashable, Sendable {
    let selectedMode: GameMode
    let periodOrdinal: Int?
    let periodLabel: String?
    let clockLabel: String?
    let eventCount: Int?
    let lastReadEventID: String?
    let scrollFallback: ScrollFallback?
    let reachedScoreboard: Bool
    let updatedAt: Date?
    let restoredAt: Date?
    let persistence: GameProgressPersistence?

    var displayText: String {
        normalizedPeriodClockText(periodLabel: periodLabel, clockLabel: clockLabel) ?? ""
    }
}

struct ScrollFallback: Codable, Hashable, Sendable {
    let eventSequence: Int?
    let approximateOffset: Double?
}

struct GameProgressPersistence: Codable, Hashable, Sendable {
    let storageKey: String
}

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
    let revealAvailable: Bool
    let revealRequiredForScores: Bool

    static let normalizedFeed = GameDetailFeedMetadata(
        source: .normalizedFeed,
        generationStatus: .unknown,
        fallbackState: .none,
        revealAvailable: false,
        revealRequiredForScores: true
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
