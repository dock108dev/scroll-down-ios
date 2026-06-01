import Foundation
import OSLog
import UserNotifications

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
protocol FavoriteGameNotificationDelivering {
    func deliver(_ plans: [FavoriteGameNotificationPlan]) async throws -> Set<String>
}

@MainActor
final class LocalFavoriteGameNotificationDeliverer: FavoriteGameNotificationDelivering {
    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "FavoriteGameNotifications"
    )

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func deliver(_ plans: [FavoriteGameNotificationPlan]) async throws -> Set<String> {
        guard !plans.isEmpty else { return [] }
        guard try await notificationsAreAllowed() else { return [] }

        var deliveredKeys = Set<String>()
        for plan in plans {
            do {
                try await add(plan)
                deliveredKeys.insert(plan.key)
            } catch {
                Self.logger.warning(
                    "Favorite game notification skipped game=\(plan.payload.gameId, privacy: .public): \(error.localizedDescription, privacy: .private)"
                )
            }
        }
        return deliveredKeys
    }

    private func notificationsAreAllowed() async throws -> Bool {
        switch await notificationAuthorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await requestAuthorization()
        @unknown default:
            return false
        }
    }

    private func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func add(_ plan: FavoriteGameNotificationPlan) async throws {
        let content = UNMutableNotificationContent()
        content.title = plan.title
        content.body = plan.body
        content.sound = .default
        content.categoryIdentifier = FavoriteGameNotificationPayloadKeys.category
        content.userInfo = plan.payload.userInfo

        let request = UNNotificationRequest(
            identifier: plan.identifier,
            content: content,
            trigger: nil
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@MainActor
final class BackgroundRefreshService {
    static let shared = BackgroundRefreshService(
        apiClient: .shared,
        gameStateStore: UserDefaultsGameStateStore()
    )
    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "BackgroundRefreshService"
    )

    private let apiClient: any BackgroundRefreshAPIClient
    private let gameStateStore: any GameStateStore
    private let notificationDeliverer: any FavoriteGameNotificationDelivering
    private let now: () -> Date
    private let maxPinnedDetailFetches: Int

    init(
        apiClient: SDAApiClient,
        gameStateStore: any GameStateStore,
        notificationDeliverer: any FavoriteGameNotificationDelivering = LocalFavoriteGameNotificationDeliverer(),
        now: @escaping () -> Date = Date.init,
        maxPinnedDetailFetches: Int = 8
    ) {
        self.apiClient = SDABackgroundRefreshAPIClient(apiClient: apiClient)
        self.gameStateStore = gameStateStore
        self.notificationDeliverer = notificationDeliverer
        self.now = now
        self.maxPinnedDetailFetches = max(0, maxPinnedDetailFetches)
    }

    init(
        apiClient: any BackgroundRefreshAPIClient,
        gameStateStore: any GameStateStore,
        notificationDeliverer: any FavoriteGameNotificationDelivering = LocalFavoriteGameNotificationDeliverer(),
        now: @escaping () -> Date = Date.init,
        maxPinnedDetailFetches: Int = 8
    ) {
        self.apiClient = apiClient
        self.gameStateStore = gameStateStore
        self.notificationDeliverer = notificationDeliverer
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
                    Self.logger.warning(
                        "Pinned game background refresh failed id=\(pinnedRecord.gameId, privacy: .public): \(error.localizedDescription, privacy: .private)"
                    )
                    gameStateStore.recordPinnedGameRefreshFailure(
                        gameId: pinnedRecord.gameId,
                        message: error.localizedDescription,
                        at: now()
                    )
                }
            }

            await deliverFavoriteGameNotifications(games: games)
            record.completedAt = now()
            record.success = record.failedGameIds.isEmpty
            if record.success {
                Self.logger.info(
                    "Background refresh completed games=\(games.count, privacy: .public) pinned=\(record.refreshedGameIds.count, privacy: .public)"
                )
            } else {
                Self.logger.warning(
                    "Background refresh completed with pinned failures count=\(record.failedGameIds.count, privacy: .public)"
                )
            }
            gameStateStore.recordBackgroundRefresh(record)
        } catch is CancellationError {
            record.completedAt = now()
            record.errorMessage = CancellationError().localizedDescription
            Self.logger.info("Background refresh cancelled")
            gameStateStore.recordBackgroundRefresh(record)
            throw CancellationError()
        } catch {
            record.completedAt = now()
            record.errorMessage = error.localizedDescription
            Self.logger.error(
                "Background refresh failed: \(error.localizedDescription, privacy: .private)"
            )
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

    private func deliverFavoriteGameNotifications(games: [Game]) async {
        let plans = FavoriteGameNotificationPlanner.plans(
            games: games,
            snapshot: gameStateStore.snapshot,
            now: now()
        )
        guard !plans.isEmpty else { return }

        do {
            let deliveredKeys = try await notificationDeliverer.deliver(plans)
            if !deliveredKeys.isEmpty {
                gameStateStore.recordFavoriteNotificationKeys(deliveredKeys)
            }
        } catch {
            Self.logger.warning(
                "Favorite game notification delivery failed: \(error.localizedDescription, privacy: .private)"
            )
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
