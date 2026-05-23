import Foundation

extension LocalGameStateSnapshot {
    mutating func saveHomeSnapshot(games: [Game], windowKey: String, fetchedAt: Date) {
        homeSnapshot = PersistedHomeSnapshot(windowKey: windowKey, fetchedAt: fetchedAt, games: games)
    }

    mutating func updatePinnedGameDetail(_ detail: GameDetail, fetchedAt: Date) {
        let gameId = detail.game.id
        guard var record = pinnedGamesById[gameId], record.isPinned else { return }
        let fetchedCursor = PlayCursorExtractor.latestCursor(from: detail)
        let existingCursor = record.latestPlayCursor

        if let fetchedCursor,
           let existingCursor,
           fetchedCursor < existingCursor {
            record.lastBackgroundRefreshAt = fetchedAt
            record.lastBackgroundError = nil
            pinnedGamesById[gameId] = record
            return
        }

        record.mergeRefreshMetadata(from: detail.game, existing: record, now: fetchedAt)
        record.latestDetail = detail
        record.lastBackgroundRefreshAt = fetchedAt
        record.lastBackgroundError = nil

        if let fetchedCursor {
            if record.lastSeenPlayCursor == nil {
                record.lastSeenPlayCursor = fetchedCursor
                record.newEventCount = 0
            } else if let seenCursor = record.lastSeenPlayCursor,
                      fetchedCursor.isAfter(seenCursor) {
                record.newEventCount = unseenCount(from: seenCursor, to: fetchedCursor)
            }
            record.latestPlayCursor = fetchedCursor
        }

        pinnedGamesById[gameId] = record
        mirrorPinnedUnseenCountToProgress(gameId: gameId, count: record.newEventCount, now: fetchedAt)
    }

    mutating func recordPinnedGameRefreshFailure(gameId: Int, message: String, at date: Date) {
        guard var record = pinnedGamesById[gameId], record.isPinned else { return }
        record.lastBackgroundRefreshAt = date
        record.lastBackgroundError = message
        pinnedGamesById[gameId] = record
    }

    mutating func recordBackgroundRefresh(_ record: BackgroundRefreshRecord) {
        backgroundRefreshRecord = record
    }

    mutating func clearPinnedUnseenCount(gameId: Int) {
        guard var record = pinnedGamesById[gameId] else { return }
        record.newEventCount = 0
        record.lastSeenPlayCursor = record.latestPlayCursor
        pinnedGamesById[gameId] = record
    }

    private func unseenCount(from seenCursor: PlayCursor, to latestCursor: PlayCursor) -> Int {
        if let seenSequence = seenCursor.sequence,
           let latestSequence = latestCursor.sequence {
            return max(0, latestSequence - seenSequence)
        }
        return latestCursor.isAfter(seenCursor) ? 1 : 0
    }

    private mutating func mirrorPinnedUnseenCountToProgress(gameId: Int, count: Int, now: Date) {
        var progress = progressByGameId[gameId] ?? .empty(gameId: gameId, now: now)
        progress.lastKnownEventCount = max(progress.lastKnownEventCount, progress.readEventCount + count)
        progress.newEventCount = max(0, count)
        progress.updatedAt = now
        progressByGameId[gameId] = progress
    }
}
