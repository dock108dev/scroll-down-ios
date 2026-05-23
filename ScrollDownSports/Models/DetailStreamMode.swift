import Foundation

enum DetailStreamMode: String, CaseIterable, Codable, Identifiable {
    case key
    case flow
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .key:
            return "Key"
        case .flow:
            return "Flow"
        case .full:
            return "Full"
        }
    }

    var sectionTitle: String {
        switch self {
        case .key:
            return "Key Moments"
        case .flow:
            return "Game Flow"
        case .full:
            return "Full Play-by-Play"
        }
    }

    var emptyStateMessage: String {
        switch self {
        case .key:
            return "No key moments are available in this view. Full Play-by-Play still shows every logged event."
        case .flow:
            return "No flow plays are available in this view. Full Play-by-Play still shows every logged event."
        case .full:
            return "No logged plays are available yet."
        }
    }

    var summary: String {
        switch self {
        case .key:
            return "Fastest view"
        case .flow:
            return "Momentum view"
        case .full:
            return "Every logged play"
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
        if events.contains(where: \.usesBackendModeEligibility) {
            let eligible = events.filter { $0.isEligible(for: self) }
            if !eligible.isEmpty || events.allSatisfy(\.usesBackendModeEligibility) {
                return eligible
            }
        }
        let bands = includedBands(in: events)
        return events.filter { bands.contains($0.detailBand) }
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
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank }

        if parts.isEmpty {
            return "sequence:\(event.sequence):\(event.id)"
        }
        return parts.joined(separator: "|")
    }

    private func includedBands(in events: [GameEvent]) -> Set<DetailEventBand> {
        switch self {
        case .key:
            if events.contains(where: { $0.detailBand == .key }) {
                return [.key]
            }
            if events.contains(where: { $0.detailBand == .flow }) {
                return [.flow]
            }
            return [.play]
        case .flow:
            if events.contains(where: { $0.detailBand == .key || $0.detailBand == .flow }) {
                return [.key, .flow]
            }
            return [.play]
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
           let exact = sortedEvents.first(where: { $0.normalizedSourceEventID == eventID || $0.id == eventID || $0.detailAnchorID == eventID }) {
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
            if let previous = sortedEvents.last(where: { $0.sequence < fallbackSequence }) {
                return previous
            }
            return sortedEvents.first(where: { $0.sequence > fallbackSequence })
        }

        return mode.visibleDedupedEvents(sortedEvents).first
    }

    static func streamModeToReveal(target: GameEvent, currentMode: DetailStreamMode, events: [GameEvent]) -> DetailStreamMode {
        if currentMode.visibleEvents(in: events).contains(where: { $0.id == target.id }) {
            return currentMode
        }
        return .full
    }

    static func resumeDescription(target: GameEvent, newPlayCount: Int) -> String {
        let position = target.clockText.isEmpty ? "your saved play" : target.clockText
        if newPlayCount == 1 {
            return "Saved at \(position). 1 new play is waiting."
        }
        if newPlayCount > 1 {
            return "Saved at \(position). \(newPlayCount) new plays are waiting."
        }
        return "Saved at \(position)."
    }
}

enum DetailEventBand: Hashable {
    case key
    case flow
    case play

    var title: String {
        switch self {
        case .key:
            return "Key"
        case .flow:
            return "Flow"
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
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
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
        guard raw.normalizedForDisplayComparison != visibleCopy.normalizedForDisplayComparison,
              raw.normalizedForDisplayComparison != headline.normalizedForDisplayComparison
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
        if usesBackendModeEligibility {
            return eligibleModes.contains(.timeline)
        }
        return scoreDelta != nil || importance == .primary
    }

    func isEligible(for mode: DetailStreamMode) -> Bool {
        guard usesBackendModeEligibility else { return true }
        return eligibleModes.contains(mode.storageMode)
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
        if scoreDelta != nil || importance == .primary {
            return .high
        }
        if importance == .secondary {
            return .medium
        }
        return .low
    }
}

private extension EventImportanceData {
    var visualImportance: EventVisualImportance? {
        if isLeadChange == true || isTyingPlay == true {
            return .critical
        }
        switch level?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "critical":
            return .critical
        case "high", "major":
            return .high
        case "medium", "notable":
            return .medium
        case "low", "routine":
            return .low
        default:
            break
        }
        if isScoringPlay == true {
            return .high
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

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var normalizedForDisplayComparison: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    var stableDisplayHash: String {
        normalizedForDisplayComparison.unicodeScalars.reduce(UInt32(2_166_136_261)) { hash, scalar in
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
