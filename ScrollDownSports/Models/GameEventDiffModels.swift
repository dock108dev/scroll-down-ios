import Foundation

struct GameEventDiffKey: Codable, Hashable, Sendable {
    enum Kind: String, Codable, Sendable {
        case sourceEventID
        case sequence
    }

    let kind: Kind
    let value: String
    let sequence: Int
}

struct GameEventIdentityBaseline: Codable, Equatable, Sendable {
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

enum GameEventListChangeKind: String, Equatable, Sendable {
    case unchanged
    case appended
    case prepended
    case inserted
    case modified
    case reset
}

struct GameEventListDiff: Equatable, Sendable {
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
            return GameEventListDiff(
                kind: .appended,
                insertedEvents: current,
                modifiedEvents: [],
                countDelta: current.count
            )
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
