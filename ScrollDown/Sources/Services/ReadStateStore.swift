import Foundation

/// Reactive wrapper around UserDefaults for game read state.
/// Publishes changes so SwiftUI views re-render immediately when read state changes.
final class ReadStateStore: ObservableObject {
    static let shared = ReadStateStore()

    private let defaults = UserDefaults.standard
    private let prefix = "game.read."
    private var readIds: Set<Int>?

    private init() {}

    /// Bulk-load read state for all visible game IDs into the in-memory cache.
    /// Call once after sections are populated to avoid per-game UserDefaults hits.
    func preload(gameIds: [Int]) {
        var ids = Set<Int>()
        for id in gameIds where defaults.bool(forKey: prefix + "\(id)") {
            ids.insert(id)
        }
        readIds = ids
    }

    func isRead(gameId: Int) -> Bool {
        if let cached = readIds {
            return cached.contains(gameId)
        }
        return defaults.bool(forKey: prefix + "\(gameId)")
    }

    func markRead(gameId: Int) {
        objectWillChange.send()
        defaults.set(true, forKey: prefix + "\(gameId)")
        readIds?.insert(gameId)
    }

    func markUnread(gameId: Int) {
        objectWillChange.send()
        defaults.removeObject(forKey: prefix + "\(gameId)")
        readIds?.remove(gameId)
    }

    func markAllRead(gameIds: [Int]) {
        objectWillChange.send()
        for id in gameIds {
            defaults.set(true, forKey: prefix + "\(id)")
            readIds?.insert(id)
        }
    }

    func markAllUnread(gameIds: [Int]) {
        objectWillChange.send()
        for id in gameIds {
            defaults.removeObject(forKey: prefix + "\(id)")
            readIds?.remove(id)
        }
    }

    func readCount(for gameIds: [Int]) -> Int {
        if let cached = readIds {
            return gameIds.filter { cached.contains($0) }.count
        }
        return gameIds.filter { defaults.bool(forKey: prefix + "\($0)") }.count
    }
}
