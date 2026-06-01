import Foundation

extension GameProgressRecord {
    var hasReadCursor: Bool {
        lastReadEventID != nil || lastReadEventIndex != nil || lastScrollFallback != nil
    }

    mutating func recomputeUnreadCount(from events: [GameEvent]) {
        guard !events.isEmpty else {
            newEventCount = 0
            return
        }

        guard let readIndex = resolvedReadIndex(in: events) else {
            newEventCount = 0
            return
        }

        lastReadEventIndex = readIndex
        newEventCount = max(0, events.count - max(0, readIndex + 1))
    }

    private func resolvedReadIndex(in events: [GameEvent]) -> Int? {
        let duplicateSourceEventIDs = GameEventIdentityBaseline.duplicateSourceEventIDs(in: events)
        if let eventID = lastReadEventID,
           let index = events.firstIndex(where: {
               GameEventIdentityResolver.matches(
                   savedEventID: eventID,
                   event: $0,
                   duplicateSourceEventIDs: duplicateSourceEventIDs
               )
           }) {
            return index
        }

        if let lastReadEventIndex {
            return min(max(0, lastReadEventIndex), events.count - 1)
        }

        guard let fallbackSequence = lastScrollFallback?.eventSequence else {
            return nil
        }

        if let sameSequence = events.firstIndex(where: { $0.sequence == fallbackSequence }) {
            return sameSequence
        }
        if let previous = events.lastIndex(where: { $0.sequence < fallbackSequence }) {
            return previous
        }
        return events.firstIndex(where: { $0.sequence > fallbackSequence })
    }
}
