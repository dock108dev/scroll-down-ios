import Foundation

@MainActor
protocol BackgroundRefreshAPIClient {
    func fetchGames(window: GameWindow, limit: Int) async throws -> [Game]
    func fetchGame(id: Int) async throws -> GameDetail
}

@MainActor
private final class SDABackgroundRefreshAPIClient: BackgroundRefreshAPIClient {
    private let apiClient: SDAApiClient

    init(apiClient: SDAApiClient) {
        self.apiClient = apiClient
    }

    func fetchGames(window: GameWindow, limit: Int) async throws -> [Game] {
        try await apiClient.fetchGames(window: window, limit: limit)
    }

    func fetchGame(id: Int) async throws -> GameDetail {
        try await apiClient.fetchGame(id: id)
    }
}

@MainActor
final class BackgroundRefreshService {
    static let shared = BackgroundRefreshService(
        apiClient: .shared,
        gameStateStore: UserDefaultsGameStateStore()
    )

    private let apiClient: any BackgroundRefreshAPIClient
    private let gameStateStore: any GameStateStore
    private let now: () -> Date
    private let maxPinnedDetailFetches: Int

    init(
        apiClient: SDAApiClient,
        gameStateStore: any GameStateStore,
        now: @escaping () -> Date = Date.init,
        maxPinnedDetailFetches: Int = 8
    ) {
        self.apiClient = SDABackgroundRefreshAPIClient(apiClient: apiClient)
        self.gameStateStore = gameStateStore
        self.now = now
        self.maxPinnedDetailFetches = max(0, maxPinnedDetailFetches)
    }

    init(
        apiClient: any BackgroundRefreshAPIClient,
        gameStateStore: any GameStateStore,
        now: @escaping () -> Date = Date.init,
        maxPinnedDetailFetches: Int = 8
    ) {
        self.apiClient = apiClient
        self.gameStateStore = gameStateStore
        self.now = now
        self.maxPinnedDetailFetches = max(0, maxPinnedDetailFetches)
    }

    func refreshForBackground() async throws {
        let startedAt = now()
        let window = GameWindow.home(now: startedAt)
        var record = BackgroundRefreshRecord(
            startedAt: startedAt,
            completedAt: nil,
            success: false,
            homeWindowKey: window.stableKey,
            refreshedGameIds: [],
            failedGameIds: [],
            skippedPinnedGameIds: [],
            errorMessage: nil
        )

        do {
            let games = try await apiClient.fetchGames(window: window, limit: 200)
            gameStateStore.saveHomeSnapshot(games: games, windowKey: window.stableKey, fetchedAt: now())
            games.forEach { gameStateStore.updatePinnedGame($0) }

            let pinnedRecords = prioritizedPinnedRecords(now: startedAt)
            record.skippedPinnedGameIds = Array(pinnedRecords.dropFirst(maxPinnedDetailFetches).map(\.gameId))

            for pinnedRecord in pinnedRecords.prefix(maxPinnedDetailFetches) {
                try Task.checkCancellation()
                guard gameStateStore.isPinned(gameId: pinnedRecord.gameId) else { continue }

                do {
                    let detail = try await apiClient.fetchGame(id: pinnedRecord.gameId)
                    guard gameStateStore.isPinned(gameId: pinnedRecord.gameId) else { continue }
                    gameStateStore.updatePinnedGameDetail(detail, fetchedAt: now())
                    record.refreshedGameIds.append(pinnedRecord.gameId)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    record.failedGameIds.append(pinnedRecord.gameId)
                    gameStateStore.recordPinnedGameRefreshFailure(
                        gameId: pinnedRecord.gameId,
                        message: error.localizedDescription,
                        at: now()
                    )
                }
            }

            record.completedAt = now()
            record.success = record.failedGameIds.isEmpty
            gameStateStore.recordBackgroundRefresh(record)
        } catch is CancellationError {
            record.completedAt = now()
            record.errorMessage = CancellationError().localizedDescription
            gameStateStore.recordBackgroundRefresh(record)
            throw CancellationError()
        } catch {
            record.completedAt = now()
            record.errorMessage = error.localizedDescription
            gameStateStore.recordBackgroundRefresh(record)
            throw error
        }
    }

    private func prioritizedPinnedRecords(now: Date) -> [PinnedGameRecord] {
        let records = gameStateStore.snapshot.pinnedGamesById.values.filter(\.isPinned)
        return records.sorted { left, right in
            let leftScore = priorityScore(for: left, now: now)
            let rightScore = priorityScore(for: right, now: now)
            if leftScore != rightScore {
                return leftScore > rightScore
            }
            return left.gameId < right.gameId
        }
    }

    private func priorityScore(for record: PinnedGameRecord, now: Date) -> Double {
        let calendar = Calendar.sda
        let liveBoost = GameStatus(rawValue: record.statusRawValue).isLive ? 1_000.0 : 0.0
        let todayBoost = calendar.isDate(record.gameDate, inSameDayAs: now) ? 300.0 : 0.0
        let hoursSinceStart = now.timeIntervalSince(record.gameDate) / 3_600
        let recentCompletionBoost = hoursSinceStart >= 0 && hoursSinceStart <= 2 ? 150.0 : 0.0
        let soonBoost = record.gameDate >= now && record.gameDate.timeIntervalSince(now) <= 12 * 3_600 ? 100.0 : 0.0
        let stalePenalty = record.lastBackgroundRefreshAt.map { now.timeIntervalSince($0) / 600 } ?? 0.0
        return liveBoost + todayBoost + recentCompletionBoost + soonBoost - stalePenalty
    }
}
