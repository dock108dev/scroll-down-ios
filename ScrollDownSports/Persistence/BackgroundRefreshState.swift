import Foundation

struct PersistedHomeSnapshot: Codable, Equatable {
    let windowKey: String
    let fetchedAt: Date
    let games: [Game]
}

struct PlayCursor: Codable, Comparable, Equatable {
    let sequence: Int?
    let eventID: String?

    static func < (left: PlayCursor, right: PlayCursor) -> Bool {
        if let leftSequence = left.sequence,
           let rightSequence = right.sequence {
            return leftSequence < rightSequence
        }
        return false
    }

    func isAfter(_ previous: PlayCursor) -> Bool {
        if let sequence,
           let previousSequence = previous.sequence {
            return sequence > previousSequence
        }
        if let eventID,
           let previousEventID = previous.eventID {
            return eventID != previousEventID
        }
        return false
    }
}

struct BackgroundRefreshRecord: Codable, Equatable {
    let startedAt: Date
    var completedAt: Date?
    var success: Bool
    var homeWindowKey: String?
    var refreshedGameIds: [Int]
    var failedGameIds: [Int]
    var skippedPinnedGameIds: [Int]
    var errorMessage: String?
}

enum PlayCursorExtractor {
    static func latestCursor(from detail: GameDetail) -> PlayCursor? {
        guard let event = detail.events.max(by: { left, right in
            if left.sequence != right.sequence {
                return left.sequence < right.sequence
            }
            return left.id < right.id
        }) else {
            return nil
        }
        return PlayCursor(sequence: event.sequence, eventID: event.normalizedSourceEventID ?? event.id)
    }
}
