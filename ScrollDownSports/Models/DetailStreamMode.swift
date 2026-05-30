import Foundation

enum DetailStreamMode: String, CaseIterable, Codable, Identifiable {
    case key
    case flow
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .key:
            return "Important"
        case .flow:
            return "Standard"
        case .full:
            return "All Plays"
        }
    }

    var sectionTitle: String {
        switch self {
        case .key:
            return "Important Plays"
        case .flow:
            return "Standard Stream"
        case .full:
            return "All Plays"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .key:
            return "No important plays in this view yet."
        case .flow:
            return "No standard stream plays in this view yet."
        case .full:
            return "No plays are available yet."
        }
    }

    var summary: String {
        switch self {
        case .key:
            return "Important"
        case .flow:
            return "Standard"
        case .full:
            return "All Plays"
        }
    }

    var storageMode: GameMode {
        switch self {
        case .key:
            return .timeline
        case .flow:
            return .flow
        case .full:
            return .stream
        }
    }

    init(storageMode: GameMode) {
        switch storageMode {
        case .flow:
            self = .flow
        case .stream:
            self = .full
        case .timeline, .stats, .scoreboard:
            self = .key
        }
    }

    func count(in events: [GameEvent]) -> Int {
        visibleEvents(in: events).count
    }

    func count(in events: [GameEvent], game: Game) -> Int {
        game.presentation?.eventCount(for: self) ?? count(in: events)
    }

    func visibleEvents(in events: [GameEvent]) -> [GameEvent] {
        visibleDedupedEvents(Self.dedupedEvents(from: events))
    }

    func visibleDedupedEvents(_ events: [GameEvent]) -> [GameEvent] {
        events.filter { $0.isEligible(for: self) }
    }

    static func dedupedEvents(from events: [GameEvent]) -> [GameEvent] {
        var uniqueEventsByKey: [String: GameEvent] = [:]
        for event in events {
            let key = dedupeKey(for: event)
            guard let current = uniqueEventsByKey[key] else {
                uniqueEventsByKey[key] = event
                continue
            }
            if event.sequence < current.sequence || (event.sequence == current.sequence && event.id < current.id) {
                uniqueEventsByKey[key] = event
            }
        }

        return uniqueEventsByKey.values.sorted {
            if $0.sequence != $1.sequence {
                return $0.sequence < $1.sequence
            }
            return $0.id < $1.id
        }
    }

    private static func dedupeKey(for event: GameEvent) -> String {
        if let sourceEventID = event.normalizedSourceEventID {
            return "event:\(sourceEventID)"
        }

        let parts = [
            event.periodLabel,
            event.presentation?.timeLabel,
            event.clockLabel,
            event.headline,
            event.eventType,
            event.teamAbbreviation
        ]
        .compactMap { $0?.nilIfBlank }

        if parts.isEmpty {
            return "sequence:\(event.sequence):\(event.id)"
        }
        return parts.joined(separator: "|")
    }

    private func includedBands(in events: [GameEvent]) -> Set<DetailEventBand> {
        switch self {
        case .key:
            return [.key]
        case .flow:
            return [.key, .flow]
        case .full:
            return [.key, .flow, .play]
        }
    }
}

struct GameDetailRestoreTargetResolver {
    static func targetEvent(
        progress: GameProgressRecord,
        events: [GameEvent],
        mode: DetailStreamMode
    ) -> GameEvent? {
        let sortedEvents = DetailStreamMode.dedupedEvents(from: events)
        guard !sortedEvents.isEmpty else { return nil }

        if let eventID = progress.lastReadEventID,
           let exact = sortedEvents.first(where: {
               $0.normalizedSourceEventID == eventID
                   || $0.id == eventID
                   || $0.detailAnchorID == eventID
           }) {
            return exact
        }

        if let eventIndex = progress.lastReadEventIndex,
           sortedEvents.indices.contains(eventIndex) {
            return sortedEvents[eventIndex]
        }

        if let fallbackSequence = progress.lastScrollFallback?.eventSequence,
           let sameSequence = sortedEvents.first(where: { $0.sequence == fallbackSequence }) {
            return sameSequence
        }

        if let fallbackSequence = progress.lastScrollFallback?.eventSequence {
            if let next = sortedEvents.first(where: { $0.sequence > fallbackSequence }) {
                return next
            }
            return sortedEvents.last(where: { $0.sequence < fallbackSequence })
        }

        return mode.visibleDedupedEvents(sortedEvents).first
    }

    static func streamModeToReveal(
        target: GameEvent,
        currentMode: DetailStreamMode,
        events: [GameEvent]
    ) -> DetailStreamMode {
        if currentMode.visibleEvents(in: events).contains(where: { $0.id == target.id }) {
            return currentMode
        }
        return .full
    }

    static func resumeDescription(target: GameEvent, newPlayCount: Int) -> String {
        let position = target.resumePositionText.cleanDisplayLabel ?? "your saved play"
        if newPlayCount == 1 {
            return "Resume from \(position) · 1 new"
        }
        if newPlayCount > 1 {
            return "Resume from \(position) · \(newPlayCount) new"
        }
        return "Resume from \(position)"
    }
}

enum DetailEventBand: Hashable {
    case key
    case flow
    case play

    var title: String {
        switch self {
        case .key:
            return "Important"
        case .flow:
            return "Standard"
        case .play:
            return "Play"
        }
    }
}

enum EventVisualImportance: Hashable {
    case low
    case medium
    case high
    case critical

    var title: String {
        switch self {
        case .low: return ""
        case .medium: return "Notable"
        case .high: return "Key play"
        case .critical: return "Big moment"
        }
    }
}

extension GameEvent {
    var detailAnchorID: String {
        "play-\(diffKey.kind.rawValue)-\(diffKey.value)"
    }

    var displayRawFeedText: String? {
        guard let raw = rawText?.nilIfBlank else { return nil }
        let visibleCopy = [headline, detail].compactMap(\.self).joined(separator: " ")
        guard raw.normalizedLabelKey != visibleCopy.normalizedLabelKey,
              raw.normalizedLabelKey != headline.normalizedLabelKey
        else {
            return nil
        }
        return raw
    }

    func rawFeedExpansionKey(game: Game) -> String? {
        guard let raw = displayRawFeedText else { return nil }
        let eventID = normalizedSourceEventID ?? diffKey.value
        return [
            "raw-feed",
            "v1",
            game.leagueCode.lowercased(),
            String(game.id),
            eventID,
            raw.stableDisplayHash
        ].joined(separator: ":")
    }

    var isKeyMoment: Bool {
        eligibleModes.contains(.timeline)
    }

    func isEligible(for mode: DetailStreamMode) -> Bool {
        eligibleModes.contains(mode.storageMode)
    }

    var detailBand: DetailEventBand {
        if isKeyMoment {
            return .key
        }
        if importance == .secondary {
            return .flow
        }
        return .play
    }

    var visualImportance: EventVisualImportance {
        if let metadataImportance = importanceMetadata?.visualImportance {
            return metadataImportance
        }
        if importance == .primary {
            return .high
        }
        if importance == .secondary {
            return .medium
        }
        return .low
    }

    var resumePositionText: String {
        let candidate = normalizedPeriodClockText(
            periodLabel: periodLabel,
            clockLabel: clockLabel,
            presentationTimeLabel: presentation?.timeLabel
        )
        return candidate ?? ""
    }
}

func normalizedPeriodClockText(
    periodLabel: String?,
    clockLabel: String?,
    presentationTimeLabel: String? = nil
) -> String? {
    PeriodLabelFormatter.output(
        sport: .other("generic"),
        leagueCode: "generic",
        periodOrdinal: nil,
        periodLabel: periodLabel,
        clockLabel: clockLabel,
        presentationTimeLabel: presentationTimeLabel
    ).resumeText
}

private extension EventImportanceData {
    var visualImportance: EventVisualImportance? {
        if isLeadChange == true || isTyingPlay == true {
            return .critical
        }
        switch level?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "primary":
            return .critical
        case "secondary":
            return .medium
        case "tertiary":
            return .low
        default:
            break
        }
        if let rank {
            if rank >= 90 { return .critical }
            if rank >= 50 { return .high }
            if rank >= 25 { return .medium }
            return .low
        }
        return nil
    }
}

extension String {
    var cleanDisplayLabel: String? {
        let trimmed = collapsedDisplayWhitespace
        guard !trimmed.isEmpty, trimmed != "-" else { return nil }

        let parts = trimmed.split(separator: " ")
        guard parts.count == 2, parts[0].lowercased() == parts[1].lowercased() else {
            return trimmed
        }
        return String(parts[0])
    }

    var normalizedLabelKey: String {
        collapsedDisplayWhitespace.lowercased()
    }

    private var collapsedDisplayWhitespace: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}

private extension String {
    var stableDisplayHash: String {
        normalizedLabelKey.unicodeScalars.reduce(UInt32(2_166_136_261)) { hash, scalar in
            (hash ^ UInt32(scalar.value)) &* 16_777_619
        }
        .description
    }
}

extension Sport {
    var displayName: String {
        switch self {
        case .mlb:
            return "Baseball"
        case .nfl:
            return "Football"
        case .nba:
            return "Basketball"
        case .nhl:
            return "Hockey"
        case .soccer:
            return "Soccer"
        case .golf:
            return "Golf"
        case .tennis:
            return "Tennis"
        case .other(let value):
            return value.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
