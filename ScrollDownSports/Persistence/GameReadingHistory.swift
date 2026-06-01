import Foundation

struct GameReadingHistoryRecord: Codable, Equatable, Sendable {
    var cardsByID: [String: GameReadingHistoryCardRecord]
    var lastReadCardID: String?
    var lastResumedCardID: String?
    var completedAt: Date?
    var revealedAt: Date?
    var updatedAt: Date?

    static func empty() -> GameReadingHistoryRecord {
        GameReadingHistoryRecord(
            cardsByID: [:],
            lastReadCardID: nil,
            lastResumedCardID: nil,
            completedAt: nil,
            revealedAt: nil,
            updatedAt: nil
        )
    }

    static func migrated(
        lastReadEventID: String?,
        lastReadEventIndex: Int?,
        lastKnownEventCount: Int,
        reachedScoreboard: Bool,
        updatedAt: Date
    ) -> GameReadingHistoryRecord {
        var history = Self.empty()
        if let cardID = lastReadEventID?.nilIfBlank {
            history.cardsByID[cardID] = GameReadingHistoryCardRecord(
                cardID: cardID,
                sourceEventID: cardID,
                sequence: lastReadEventIndex,
                feedIndex: lastReadEventIndex,
                firstSeenAt: updatedAt,
                lastSeenAt: updatedAt,
                readAt: updatedAt
            )
            history.lastReadCardID = cardID
            history.lastResumedCardID = cardID
        }
        if reachedScoreboard {
            history.revealedAt = updatedAt
        }
        history.updateCompletion(readCount: lastReadEventIndex.map { max(0, $0 + 1) } ?? 0, knownCount: lastKnownEventCount, at: updatedAt)
        history.updatedAt = updatedAt
        return history
    }

    mutating func mergeEvents(_ events: [GameEvent], at date: Date) {
        for (feedIndex, event) in events.enumerated() {
            let cardID = event.readingHistoryCardID
            guard !cardID.isEmpty else { continue }
            var record = cardsByID[cardID] ?? GameReadingHistoryCardRecord(
                cardID: cardID,
                sourceEventID: event.normalizedSourceEventID,
                sequence: event.sequence,
                feedIndex: feedIndex,
                firstSeenAt: date,
                lastSeenAt: date,
                readAt: nil
            )
            record.sourceEventID = event.normalizedSourceEventID ?? record.sourceEventID
            record.sequence = event.sequence
            record.feedIndex = feedIndex
            record.lastSeenAt = date
            cardsByID[cardID] = record
        }
        updatedAt = date
    }

    mutating func markRead(cardID: String?, eventIndex: Int?, knownCount: Int, at date: Date) {
        let normalizedCardID = cardID?.nilIfBlank
        if let normalizedCardID {
            var record = cardsByID[normalizedCardID] ?? GameReadingHistoryCardRecord(
                cardID: normalizedCardID,
                sourceEventID: normalizedCardID,
                sequence: eventIndex,
                feedIndex: eventIndex,
                firstSeenAt: date,
                lastSeenAt: date,
                readAt: nil
            )
            record.feedIndex = eventIndex ?? record.feedIndex
            record.lastSeenAt = date
            record.readAt = record.readAt ?? date
            cardsByID[normalizedCardID] = record
            lastReadCardID = normalizedCardID
        }

        if let eventIndex {
            markKnownCardsRead(through: eventIndex, at: date)
        }
        updateCompletion(readCount: eventIndex.map { max(0, $0 + 1) } ?? readCardCount, knownCount: knownCount, at: date)
        updatedAt = date
    }

    mutating func recordResumed(cardID: String?, at date: Date) {
        guard let cardID = cardID?.nilIfBlank else { return }
        lastResumedCardID = cardID
        updatedAt = date
    }

    mutating func recordRevealed(at date: Date) {
        revealedAt = revealedAt ?? date
        updatedAt = date
    }

    mutating func clearReadState(knownCount: Int, at date: Date) {
        for cardID in cardsByID.keys {
            cardsByID[cardID]?.readAt = nil
        }
        lastReadCardID = nil
        lastResumedCardID = nil
        completedAt = nil
        updateCompletion(readCount: 0, knownCount: knownCount, at: date)
        updatedAt = date
    }

    var readCardCount: Int {
        cardsByID.values.filter(\.isRead).count
    }

    var unreadCardCount: Int {
        cardsByID.values.filter { !$0.isRead }.count
    }

    var isCompleted: Bool {
        completedAt != nil
    }

    var isRevealed: Bool {
        revealedAt != nil
    }

    func containsFixtureData() -> Bool {
        cardsByID.values.contains {
            Self.isFixtureSourceEventID($0.cardID) || Self.isFixtureSourceEventID($0.sourceEventID)
        }
    }

    private mutating func markKnownCardsRead(through eventIndex: Int, at date: Date) {
        for cardID in cardsByID.keys {
            guard var record = cardsByID[cardID],
                  let feedIndex = record.feedIndex,
                  feedIndex <= eventIndex else { continue }
            record.readAt = record.readAt ?? date
            cardsByID[cardID] = record
        }
    }

    private mutating func updateCompletion(readCount: Int, knownCount: Int, at date: Date) {
        guard knownCount > 0, readCount >= knownCount else { return }
        completedAt = completedAt ?? date
    }

    private static func isFixtureSourceEventID(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("fixture-") == true
    }
}

struct GameReadingHistoryCardRecord: Codable, Equatable, Sendable {
    let cardID: String
    var sourceEventID: String?
    var sequence: Int?
    var feedIndex: Int?
    var firstSeenAt: Date
    var lastSeenAt: Date
    var readAt: Date?

    var isRead: Bool {
        readAt != nil
    }
}
