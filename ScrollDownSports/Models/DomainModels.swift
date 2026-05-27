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

struct GameStatus: Codable, Hashable, Sendable {
    let rawValue: String
    let isLiveOverride: Bool?
    let isFinalOverride: Bool?
    let displayStateOverride: String?

    init(rawValue: String, isLiveOverride: Bool?, isFinalOverride: Bool?, displayStateOverride: String? = nil) {
        self.rawValue = rawValue
        self.isLiveOverride = isLiveOverride
        self.isFinalOverride = isFinalOverride
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
        return isLiveOverride ?? ["in_progress", "live"].contains(normalized)
    }

    var isFinal: Bool {
        if let displayState = normalizedDisplayState {
            return displayState == "final"
        }
        return isFinalOverride ?? ["completed", "final", "recap_ready", "archived"].contains(normalized)
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

struct GameDetail: Codable, Hashable, Sendable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let events: [GameEvent]
    let mlbBatters: [MLBBatterStat]?
    let mlbPitchers: [MLBPitcherStat]?
    let nhlSkaters: [NHLPlayerStat]?
    let nhlGoalies: [NHLPlayerStat]?

    var leagueCode: String {
        game.leagueCode.lowercased()
    }
}
