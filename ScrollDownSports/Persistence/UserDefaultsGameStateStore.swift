import Combine
import Foundation
import OSLog

@MainActor
final class UserDefaultsGameStateStore: GameStateStore {
    private enum Constants {
        static let defaultKey = "com.dock108.scrolldownsports.localGameState.v1"
        static let corruptBackupKey = "com.dock108.scrolldownsports.localGameState.corrupt.v1"
    }

    private let defaults: UserDefaults
    private let key: String
    private let now: () -> Date
    private let subject: CurrentValueSubject<LocalGameStateSnapshot, Never>
    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "UserDefaultsGameStateStore"
    )

    var snapshot: LocalGameStateSnapshot {
        subject.value
    }

    var snapshots: AnyPublisher<LocalGameStateSnapshot, Never> {
        subject.eraseToAnyPublisher()
    }

    init(
        defaults: UserDefaults = .standard,
        key: String = Constants.defaultKey,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.key = key
        self.now = now
        self.subject = CurrentValueSubject(
            Self.loadSnapshot(defaults: defaults, key: key, now: now)
        )
    }

    func pin(_ game: Game) {
        mutate { state in
            state.pin(game, now: now, preserveMirroredProgressFields: true)
        }
    }

    func unpin(gameId: Int) {
        mutate { state in
            state.pinnedGamesById.removeValue(forKey: gameId)
        }
    }

    func setFavoriteTeam(teamId: String, isFavorite: Bool) {
        mutate { state in
            state.setFavoriteTeam(teamId, isFavorite: isFavorite)
        }
    }

    func recordFavoriteNotificationKeys(_ keys: Set<String>) {
        mutate { state in
            state.recordFavoriteNotificationKeys(keys)
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
        next.pruneFixtureState()
        subject.send(next)
        persist(next)
    }

    private func updatePinnedProgressMirror(gameId: Int) {
        guard snapshot.progressByGameId[gameId] != nil else { return }
        mutate { state in
            state.mirrorProgressToPinnedGame(gameId: gameId)
        }
    }

    private func persist(_ snapshot: LocalGameStateSnapshot) {
        do {
            defaults.set(try Self.encoder.encode(snapshot), forKey: key)
        } catch {
            Self.logger.error(
                "Failed to persist local game state: \(error.localizedDescription, privacy: .private)"
            )
            return
        }
    }

    private static func loadSnapshot(
        defaults: UserDefaults,
        key: String,
        now: () -> Date
    ) -> LocalGameStateSnapshot {
        guard let data = defaults.data(forKey: key) else {
            return .empty(now: now())
        }

        do {
            let decoded = try decoder.decode(LocalGameStateSnapshot.self, from: data)
            var snapshot = migrate(decoded, now: now())
            snapshot.pruneFixtureState()
            if snapshot != decoded,
               let sanitizedData = try? encoder.encode(snapshot) {
                defaults.set(sanitizedData, forKey: key)
            }
            return snapshot
        } catch {
            defaults.set(data, forKey: Constants.corruptBackupKey)
            defaults.removeObject(forKey: key)
            Self.logger.error(
                "Local game state decode failed; corrupt snapshot backed up: \(error.localizedDescription, privacy: .private)"
            )
            return .empty(now: now())
        }
    }

    private static func migrate(
        _ snapshot: LocalGameStateSnapshot,
        now: Date
    ) -> LocalGameStateSnapshot {
        guard snapshot.schemaVersion == LocalGameStateSnapshot.currentSchemaVersion else {
            return .empty(now: now)
        }
        return snapshot
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
