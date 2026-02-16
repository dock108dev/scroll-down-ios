import Foundation

/// Reactive wrapper around UserDefaults for game read state.
/// Publishes changes so SwiftUI views re-render immediately when read state changes.
final class ReadStateStore: ObservableObject {
    static let shared = ReadStateStore()

    private let defaults = UserDefaults.standard
    private let prefix = "game.read."

    private init() {}

    func isRead(gameId: Int) -> Bool {
        defaults.bool(forKey: prefix + "\(gameId)")
    }

    func markRead(gameId: Int) {
        objectWillChange.send()
        defaults.set(true, forKey: prefix + "\(gameId)")
    }

    func markUnread(gameId: Int) {
        objectWillChange.send()
        defaults.removeObject(forKey: prefix + "\(gameId)")
    }

    func markAllRead(gameIds: [Int]) {
        objectWillChange.send()
        for id in gameIds {
            defaults.set(true, forKey: prefix + "\(id)")
        }
    }

    func markAllUnread(gameIds: [Int]) {
        objectWillChange.send()
        for id in gameIds {
            defaults.removeObject(forKey: prefix + "\(id)")
        }
    }

    func readCount(for gameIds: [Int]) -> Int {
        gameIds.filter { defaults.bool(forKey: prefix + "\($0)") }.count
    }
}
