import Combine
import Foundation

@MainActor
final class InMemoryGameStateStore: GameStateStore {
    private let now: () -> Date
    private let subject: CurrentValueSubject<LocalGameStateSnapshot, Never>

    var snapshot: LocalGameStateSnapshot {
        subject.value
    }

    var snapshots: AnyPublisher<LocalGameStateSnapshot, Never> {
        subject.eraseToAnyPublisher()
    }

    init(
        initial: LocalGameStateSnapshot? = nil,
        now: @escaping () -> Date = Date.init
    ) {
        self.now = now
        self.subject = CurrentValueSubject(initial ?? .empty(now: now()))
    }

    func pin(_ game: Game) {
        mutate { state in
            state.pin(game, now: now, preserveMirroredProgressFields: false)
        }
    }

    func unpin(gameId: Int) {
        mutate { state in
            state.pinnedGamesById.removeValue(forKey: gameId)
        }
    }

    func updatePinnedGame(_ game: Game) {
        guard isPinned(gameId: game.id) else { return }
        mutate { state in
            state.updatePinnedGame(game, now: now)
        }
    }

    func saveHomeSnapshot(games: [Game], windowKey: String, fetchedAt: Date) {
        mutate { state in
            state.saveHomeSnapshot(games: games, windowKey: windowKey, fetchedAt: fetchedAt)
        }
    }

    func updatePinnedGameDetail(_ detail: GameDetail, fetchedAt: Date) {
        guard isPinned(gameId: detail.game.id) else { return }
        mutate { state in
            state.updatePinnedGameDetail(detail, fetchedAt: fetchedAt)
        }
    }

    func recordPinnedGameRefreshFailure(gameId: Int, message: String, at: Date) {
        mutate { state in
            state.recordPinnedGameRefreshFailure(gameId: gameId, message: message, at: at)
        }
    }

    func recordBackgroundRefresh(_ record: BackgroundRefreshRecord) {
        mutate { state in
            state.recordBackgroundRefresh(record)
        }
    }

    func markViewed(gameId: Int) {
        mutate { state in
            state.markViewed(gameId: gameId, now: now)
        }
    }

    func recordKnownEventCount(gameId: Int, count: Int) {
        mutate { state in
            state.recordKnownEventCount(gameId: gameId, count: count, now: now)
        }
        updatePinnedProgressMirror(gameId: gameId)
    }

    func recordEventRefresh(gameId: Int, events: [GameEvent], diff: GameEventListDiff) {
        mutate { state in
            state.recordEventRefresh(gameId: gameId, events: events, diff: diff, now: now)
        }
        updatePinnedProgressMirror(gameId: gameId)
    }

    func recordReadEvent(gameId: Int, eventID: String?, eventIndex: Int?, knownEventCount: Int?) {
        mutate { state in
            state.recordReadEvent(
                gameId: gameId,
                eventID: eventID,
                eventIndex: eventIndex,
                knownEventCount: knownEventCount,
                now: now
            )
        }
        updatePinnedProgressMirror(gameId: gameId)
    }

    func clearReadPosition(gameId: Int) {
        mutate { state in
            state.clearReadPosition(gameId: gameId, now: now)
        }
        updatePinnedProgressMirror(gameId: gameId)
    }

    func setSelectedMode(gameId: Int, mode: GameMode) {
        mutate { state in
            state.setSelectedMode(gameId: gameId, mode: mode, now: now)
        }
    }

    func setScrollFallback(gameId: Int, fallback: GameScrollFallbackRecord?) {
        mutate { state in
            state.setScrollFallback(gameId: gameId, fallback: fallback, now: now)
        }
    }

    func setExpandedSectionIDs(gameId: Int, sectionIDs: Set<String>) {
        mutate { state in
            state.setExpandedSectionIDs(gameId: gameId, sectionIDs: sectionIDs, now: now)
        }
    }

    func setRawFeedExpanded(gameId: Int, key: String, isExpanded: Bool) {
        mutate { state in
            state.setRawFeedExpanded(gameId: gameId, key: key, isExpanded: isExpanded, now: now)
        }
    }

    func setReachedScoreboard(gameId: Int, reached: Bool) {
        mutate { state in
            state.setReachedScoreboard(gameId: gameId, reached: reached, now: now)
        }
    }

    func setFollowLivePreference(gameId: Int, preference: FollowLivePreference) {
        mutate { state in
            state.setFollowLivePreference(gameId: gameId, preference: preference, now: now)
        }
    }

    func prune(now: Date) {
        mutate { state in
            state.pruneProgress(now: now)
        }
    }

    private func mutate(update: (inout LocalGameStateSnapshot) -> Void) {
        var next = snapshot
        update(&next)
        next.schemaVersion = LocalGameStateSnapshot.currentSchemaVersion
        next.updatedAt = now()
        subject.send(next)
    }

    private func updatePinnedProgressMirror(gameId: Int) {
        guard snapshot.progressByGameId[gameId] != nil else { return }
        mutate { state in
            state.mirrorProgressToPinnedGame(gameId: gameId)
        }
    }
}
