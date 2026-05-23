import Foundation

enum Sport: Codable, Hashable {
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

struct Game: Codable, Identifiable, Hashable {
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
    var matchupText: String { presentation?.matchupLabel ?? "\(awayParticipant?.name ?? "Away") at \(homeParticipant?.name ?? "Home")" }
}

struct GameParticipant: Codable, Identifiable, Hashable {
    let id: String
    let role: GameParticipantRole
    let name: String
    let abbreviation: String?
}

enum GameParticipantRole: Codable, Hashable {
    case home
    case away
    case other(String)
}

struct ScoreState: Codable, Hashable {
    let participantScores: [ParticipantScore]

    var home: Int? { score(for: .home) }
    var away: Int? { score(for: .away) }
    var hasAnyScore: Bool { participantScores.contains { $0.score != nil } }

    func score(for role: GameParticipantRole) -> Int? {
        participantScores.first { $0.participantRole == role }?.score
    }
}

struct ParticipantScore: Codable, Hashable {
    let participantID: String
    let participantRole: GameParticipantRole
    let score: Int?
}

struct ScoreDelta: Codable, Hashable {
    let participantID: String?
    let participantRole: GameParticipantRole?
    let before: Int?
    let after: Int?
    let change: Int?
}

struct GameStatus: Codable, Hashable {
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

enum GameStatusPhase: Codable, Hashable {
    case pregame
    case live
    case final
    case unknown(String)
}

struct GameAvailableFeatures: Codable, Hashable {
    let hasTimeline: Bool
    let hasStats: Bool
    let hasScoreboard: Bool
}

enum GameMode: String, Codable, Hashable {
    case timeline
    case flow
    case stream
    case stats
    case scoreboard
}

struct GameProgress: Codable, Hashable {
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

struct ScrollFallback: Codable, Hashable {
    let eventSequence: Int?
    let approximateOffset: Double?
}

struct GameProgressPersistence: Codable, Hashable {
    let storageKey: String
}

struct GameEvent: Codable, Identifiable, Hashable {
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
    let sportMetadata: [String: JSONValue]

    var clockText: String {
        if let timeLabel = presentation?.timeLabel?.nilIfBlank {
            return timeLabel
        }
        return normalizedPeriodClockText(periodLabel: periodLabel, clockLabel: clockLabel) ?? ""
    }

    var normalizedSourceEventID: String? {
        guard let sourceEventID else { return nil }
        let trimmed = sourceEventID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var diffKey: GameEventDiffKey {
        if let normalizedSourceEventID {
            return GameEventDiffKey(kind: .sourceEventID, value: normalizedSourceEventID, sequence: sequence)
        }
        return GameEventDiffKey(kind: .sequence, value: String(sequence), sequence: sequence)
    }
}

struct GameEventDiffKey: Codable, Hashable {
    enum Kind: String, Codable {
        case sourceEventID
        case sequence
    }

    let kind: Kind
    let value: String
    let sequence: Int
}

struct GameEventIdentityBaseline: Codable, Equatable {
    var sourceEventIDs: Set<String>
    var sequences: Set<Int>
    var maxSequence: Int?

    init(sourceEventIDs: Set<String> = [], sequences: Set<Int> = [], maxSequence: Int? = nil) {
        self.sourceEventIDs = sourceEventIDs
        self.sequences = sequences
        self.maxSequence = maxSequence
    }

    init(events: [GameEvent]) {
        self.init()
        formUnion(events)
    }

    func contains(_ event: GameEvent, duplicateSourceEventIDs: Set<String> = []) -> Bool {
        if let sourceEventID = event.normalizedSourceEventID,
           !duplicateSourceEventIDs.contains(sourceEventID),
           sourceEventIDs.contains(sourceEventID) {
            return true
        }
        return sequences.contains(event.sequence)
    }

    mutating func formUnion(_ events: [GameEvent]) {
        for event in events {
            if let sourceEventID = event.normalizedSourceEventID {
                sourceEventIDs.insert(sourceEventID)
            }
            sequences.insert(event.sequence)
            maxSequence = max(maxSequence ?? event.sequence, event.sequence)
        }
    }

    static func duplicateSourceEventIDs(in events: [GameEvent]) -> Set<String> {
        let counts = Dictionary(grouping: events.compactMap(\.normalizedSourceEventID), by: { $0 })
            .mapValues(\.count)
        return Set(counts.compactMap { sourceEventID, count in
            count > 1 ? sourceEventID : nil
        })
    }
}

enum GameEventListChangeKind: String, Equatable {
    case unchanged
    case appended
    case prepended
    case inserted
    case modified
    case reset
}

struct GameEventListDiff: Equatable {
    let kind: GameEventListChangeKind
    let insertedEvents: [GameEvent]
    let modifiedEvents: [GameEvent]
    let countDelta: Int

    static var unchanged: GameEventListDiff {
        GameEventListDiff(
            kind: .unchanged,
            insertedEvents: [],
            modifiedEvents: [],
            countDelta: 0
        )
    }
}

enum GameEventListDiffer {
    static func diff(
        previous: [GameEvent],
        current: [GameEvent],
        baseline: GameEventIdentityBaseline? = nil
    ) -> GameEventListDiff {
        guard !previous.isEmpty || !current.isEmpty else { return .unchanged }
        guard !previous.isEmpty else {
            return GameEventListDiff(kind: .appended, insertedEvents: current, modifiedEvents: [], countDelta: current.count)
        }
        guard !current.isEmpty else {
            return GameEventListDiff(kind: .reset, insertedEvents: [], modifiedEvents: [], countDelta: -previous.count)
        }

        let previousIdentities = identities(for: previous)
        let currentIdentities = identities(for: current)
        let previousSet = Set(previousIdentities)
        let currentSet = Set(currentIdentities)
        let duplicateSourceEventIDs = GameEventIdentityBaseline.duplicateSourceEventIDs(in: current)
        let activeBaseline = baseline ?? GameEventIdentityBaseline(events: previous)
        let baselineInserted = current
            .filter { !activeBaseline.contains($0, duplicateSourceEventIDs: duplicateSourceEventIDs) }
            .sorted { left, right in
                if left.sequence != right.sequence {
                    return left.sequence < right.sequence
                }
                return left.id < right.id
            }
        let modified = modifiedEvents(previous: previous, current: current)
        let kind: GameEventListChangeKind

        if previousIdentities == currentIdentities {
            kind = modified.isEmpty ? .unchanged : .modified
        } else if current.count < previous.count {
            kind = .reset
        } else if !previousSet.isSubset(of: currentSet) {
            if baselineInserted.isEmpty {
                kind = .modified
            } else if baselineInserted.count == current.count - previous.count {
                kind = .inserted
            } else {
                kind = .reset
            }
        } else if Array(currentIdentities.prefix(previousIdentities.count)) == previousIdentities {
            kind = .appended
        } else if Array(currentIdentities.suffix(previousIdentities.count)) == previousIdentities {
            kind = .prepended
        } else if previousSet == currentSet {
            kind = .modified
        } else {
            kind = .inserted
        }

        let inserted: [GameEvent]
        if kind == .reset {
            inserted = []
        } else {
            inserted = baselineInserted
        }

        return GameEventListDiff(
            kind: kind,
            insertedEvents: inserted,
            modifiedEvents: modified,
            countDelta: current.count - previous.count
        )
    }

    private static func identities(for events: [GameEvent]) -> [String] {
        let duplicateSourceEventIDs = GameEventIdentityBaseline.duplicateSourceEventIDs(in: events)
        return events.map { event in
            if let sourceEventID = event.normalizedSourceEventID,
               !duplicateSourceEventIDs.contains(sourceEventID) {
                return "event:\(sourceEventID)"
            }
            return "sequence:\(event.sequence)"
        }
    }

    private static func modifiedEvents(previous: [GameEvent], current: [GameEvent]) -> [GameEvent] {
        let previousBySequence = Dictionary(uniqueKeysWithValues: previous.map { ($0.sequence, $0) })
        return current.filter { event in
            guard let prior = previousBySequence[event.sequence] else { return false }
            return event.diffFingerprint != prior.diffFingerprint
        }
    }
}

private extension GameEvent {
    var diffFingerprint: String {
        let parts: [String] = [
            normalizedSourceEventID ?? "",
            String(sequence),
            periodOrdinal.map(String.init) ?? "",
            periodLabel ?? "",
            clockLabel ?? "",
            teamAbbreviation ?? "",
            eventType ?? "",
            headline,
            detail ?? "",
            rawText ?? "",
            rawFeedSource ?? "",
            rawFeedUpdatedAt ?? "",
            String(scoreAfter.home ?? Int.min),
            String(scoreAfter.away ?? Int.min)
        ]
        return parts.joined(separator: "|")
    }
}

enum GameEventImportance: Codable, Hashable {
    case primary
    case secondary
    case contextual
}

struct GameDetail: Codable, Hashable {
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
