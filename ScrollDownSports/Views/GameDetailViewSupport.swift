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

    init(anchorID: String, readIndex: Int, sequence: Int, label: String) {
        self.anchorID = anchorID
        self.readIndex = readIndex
        self.sequence = sequence
        self.label = label.cleanDisplayLabel ?? "spot"
    }

    init(frame: DetailEventVisibilityFrame) {
        self.init(
            anchorID: frame.anchorID,
            readIndex: frame.readIndex,
            sequence: frame.sequence,
            label: frame.label
        )
    }
}

struct DetailResizeRestoreSnapshot: Equatable {
    let visibleEvent: DetailVisibleEventState
    let offsetFraction: CGFloat
    let wasFollowingLiveEdge: Bool
    let wasVisibilityTrackingSuppressed: Bool

    init(
        frame: DetailEventVisibilityFrame,
        readingTopY: CGFloat,
        wasFollowingLiveEdge: Bool,
        wasVisibilityTrackingSuppressed: Bool
    ) {
        self.visibleEvent = DetailVisibleEventState(frame: frame)
        self.offsetFraction = GameDetailScrollLogic.eventOffsetFraction(frame: frame, readingTopY: readingTopY)
        self.wasFollowingLiveEdge = wasFollowingLiveEdge
        self.wasVisibilityTrackingSuppressed = wasVisibilityTrackingSuppressed
    }

    init(
        visibleEvent: DetailVisibleEventState,
        offsetFraction: CGFloat = 0,
        wasFollowingLiveEdge: Bool,
        wasVisibilityTrackingSuppressed: Bool
    ) {
        self.visibleEvent = visibleEvent
        self.offsetFraction = max(0, min(offsetFraction, 1))
        self.wasFollowingLiveEdge = wasFollowingLiveEdge
        self.wasVisibilityTrackingSuppressed = wasVisibilityTrackingSuppressed
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
        viewportHeight: CGFloat,
        readingTopY: CGFloat = 0,
        obscuredBottomHeight: CGFloat = 0
    ) -> DetailEventVisibilityFrame? {
        visibleCandidates(
            from: frames,
            viewportHeight: viewportHeight,
            readingTopY: readingTopY,
            obscuredBottomHeight: obscuredBottomHeight
        )
        .min { left, right in
            let readableMinY = max(0, readingTopY)
            let leftDistance = abs(left.frame.minY - readableMinY)
            let rightDistance = abs(right.frame.minY - readableMinY)
            if leftDistance != rightDistance {
                return leftDistance < rightDistance
            }
            return left.sequence < right.sequence
        }
    }

    static func readCandidate(
        from frames: [DetailEventVisibilityFrame],
        viewportHeight: CGFloat,
        readingTopY: CGFloat = 0,
        obscuredBottomHeight: CGFloat = 0
    ) -> DetailEventVisibilityFrame? {
        visibleCandidates(
            from: frames,
            viewportHeight: viewportHeight,
            readingTopY: readingTopY,
            obscuredBottomHeight: obscuredBottomHeight
        )
        .max { left, right in
            if left.readIndex != right.readIndex {
                return left.readIndex < right.readIndex
            }
            return left.sequence < right.sequence
        }
    }

    private static func visibleCandidates(
        from frames: [DetailEventVisibilityFrame],
        viewportHeight: CGFloat,
        readingTopY: CGFloat,
        obscuredBottomHeight: CGFloat
    ) -> [DetailEventVisibilityFrame] {
        let readableMinY = max(0, readingTopY)
        let readableMaxY = max(readableMinY, viewportHeight - max(0, obscuredBottomHeight))
        return frames
            .filter { frame in
                guard frame.frame.height > 0 else { return false }
                let visibleHeight = min(frame.frame.maxY, readableMaxY) - max(frame.frame.minY, readableMinY)
                return visibleHeight >= min(48, frame.frame.height) || visibleHeight / frame.frame.height >= 0.4
            }
    }

    static func eventOffsetFraction(frame: DetailEventVisibilityFrame, readingTopY: CGFloat) -> CGFloat {
        guard frame.frame.height > 0 else { return 0 }
        let offsetFromReadingTop = readingTopY - frame.frame.minY
        return max(0, min(offsetFromReadingTop / frame.frame.height, 1))
    }

    static func isMeaningfulViewportChange(from oldSize: CGSize, to newSize: CGSize) -> Bool {
        guard oldSize != .zero else { return false }
        return abs(oldSize.width - newSize.width) >= 1 || abs(oldSize.height - newSize.height) >= 1
    }

    static func restoredVisibleAnchorID(
        currentAnchorID: String?,
        currentSequence: Int?,
        mode: DetailStreamMode,
        events: [GameEvent]
    ) -> String? {
        let dedupedEvents = DetailStreamMode.dedupedEvents(from: events)
        let visibleEvents = mode.visibleDedupedEvents(dedupedEvents)
        guard !visibleEvents.isEmpty else { return nil }

        if let currentAnchorID,
           visibleEvents.contains(where: { $0.detailAnchorID == currentAnchorID }) {
            return currentAnchorID
        }

        let sequence = currentSequence ?? currentAnchorID.flatMap { anchorID in
            dedupedEvents.first { $0.detailAnchorID == anchorID }?.sequence
        }
        guard let sequence else {
            return visibleEvents.first?.detailAnchorID
        }

        return visibleEvents.min { lhs, rhs in
            let lhsDistance = abs(lhs.sequence - sequence)
            let rhsDistance = abs(rhs.sequence - sequence)
            if lhsDistance != rhsDistance {
                return lhsDistance < rhsDistance
            }
            return lhs.sequence < rhs.sequence
        }?.detailAnchorID
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
