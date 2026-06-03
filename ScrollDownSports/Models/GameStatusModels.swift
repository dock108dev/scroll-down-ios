import Foundation

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

enum EventContentDepth: String, Codable, Hashable, Sendable {
    case brief
    case standard
    case extended

    init(cardFeedValue: String?) {
        switch cardFeedValue?.nilIfBlank?.lowercased() {
        case "brief", "low", "routine", "compact":
            self = .brief
        case "extended", "rich", "deep":
            self = .extended
        default:
            self = .standard
        }
    }
}

enum GameEventDisplayDensity: Hashable, Sendable {
    case rich
    case standard
    case compact
}
