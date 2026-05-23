import SwiftUI

enum DetailLiveEdgeMode: Equatable {
    case following
    case reading
}

struct DetailVisibleEventState: Equatable {
    let anchorID: String
    let readIndex: Int
    let sequence: Int
    let label: String

    init(frame: DetailEventVisibilityFrame) {
        self.anchorID = frame.anchorID
        self.readIndex = frame.readIndex
        self.sequence = frame.sequence
        self.label = frame.label.cleanDisplayLabel ?? "spot"
    }
}

enum GameDetailScrollLogic {
    static func readSequence(progress: GameProgressRecord, events: [GameEvent]) -> Int? {
        let sortedEvents = DetailStreamMode.dedupedEvents(from: events)
        if let eventID = progress.lastReadEventID,
           let event = sortedEvents.first(where: { $0.normalizedSourceEventID == eventID || $0.id == eventID || $0.detailAnchorID == eventID }) {
            return event.sequence
        }
        if let eventIndex = progress.lastReadEventIndex,
           sortedEvents.indices.contains(eventIndex) {
            return sortedEvents[eventIndex].sequence
        }
        return progress.lastScrollFallback?.eventSequence
    }

    static func visibleCandidate(
        from frames: [DetailEventVisibilityFrame],
        viewportHeight: CGFloat
    ) -> DetailEventVisibilityFrame? {
        frames
            .filter { frame in
                guard frame.frame.height > 0 else { return false }
                let visibleHeight = min(frame.frame.maxY, viewportHeight) - max(frame.frame.minY, 0)
                return visibleHeight >= min(48, frame.frame.height) || visibleHeight / frame.frame.height >= 0.4
            }
            .min { left, right in
                let leftDistance = abs(left.frame.minY)
                let rightDistance = abs(right.frame.minY)
                if leftDistance != rightDistance {
                    return leftDistance < rightDistance
                }
                return left.sequence < right.sequence
            }
    }

    static func restoredStreamAnchorID(
        currentAnchorID: String?,
        from currentMode: DetailStreamMode,
        to nextMode: DetailStreamMode,
        events: [GameEvent]
    ) -> String? {
        let dedupedEvents = DetailStreamMode.dedupedEvents(from: events)
        let nextEvents = nextMode.visibleDedupedEvents(dedupedEvents)
        guard !nextEvents.isEmpty else { return nil }

        if let currentAnchorID,
           nextEvents.contains(where: { $0.detailAnchorID == currentAnchorID }) {
            return currentAnchorID
        }

        let currentEvents = currentMode.visibleDedupedEvents(dedupedEvents)
        guard
            let currentAnchorID,
            let currentEvent = currentEvents.first(where: { $0.detailAnchorID == currentAnchorID })
        else {
            return nextEvents.first?.detailAnchorID
        }

        return nextEvents.min { lhs, rhs in
            let lhsDistance = abs(lhs.sequence - currentEvent.sequence)
            let rhsDistance = abs(rhs.sequence - currentEvent.sequence)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
            return lhs.sequence < rhs.sequence
        }?.detailAnchorID
    }

    static func hasFinalScore(for game: Game) -> Bool {
        game.awayParticipant != nil
            && game.homeParticipant != nil
            && game.scoreState.away != nil
            && game.scoreState.home != nil
    }
}
