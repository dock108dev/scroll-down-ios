import Foundation
import OSLog
import UserNotifications

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
