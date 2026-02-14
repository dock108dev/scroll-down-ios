import Foundation
import OSLog

/// Disk-based cache for home screen game sections.
/// Persists game data to the Caches directory so the home screen can show
/// cached data instantly on app open (stale-while-revalidate pattern).
final class HomeGameCache {
    static let shared = HomeGameCache()
    private let logger = Logger(subsystem: "com.scrolldown.app", category: "cache")

    struct CachedSection: Codable {
        let games: [GameSummary]
        let lastUpdatedAt: String?
        let cachedAt: Date
    }

    private let cacheDir: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = base.appendingPathComponent("HomeGames", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create cache directory: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Save a section's games to disk cache.
    func save(games: [GameSummary], lastUpdatedAt: String?, range: GameRange, league: LeagueCode?) {
        let section = CachedSection(games: games, lastUpdatedAt: lastUpdatedAt, cachedAt: Date())
        let url = fileURL(for: range, league: league)
        do {
            let data = try encoder.encode(section)
            try data.write(to: url, options: .atomic)
        } catch {
            logger.error("Save failed for \(range.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Load a cached section from disk. Returns nil if no cache exists.
    func load(range: GameRange, league: LeagueCode?) -> CachedSection? {
        let url = fileURL(for: range, league: league)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(CachedSection.self, from: data)
        } catch {
            logger.error("Decode failed for \(range.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Remove all cached game data.
    func clearAll() {
        do {
            try FileManager.default.removeItem(at: cacheDir)
        } catch {
            logger.error("Failed to remove cache directory: \(error.localizedDescription, privacy: .public)")
        }
        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to recreate cache directory: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Whether the cached section was written on the same calendar day (US/Eastern).
    /// If the day rolled over, time-relative sections like "today" are stale.
    func isSameCalendarDay(range: GameRange, league: LeagueCode?) -> Bool {
        guard let cached = load(range: range, league: league) else { return false }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "US/Eastern") ?? .current
        return cal.isDateInToday(cached.cachedAt)
    }

    /// Whether the cached section is younger than `maxAge` seconds.
    func isFresh(range: GameRange, league: LeagueCode?, maxAge: TimeInterval = 900) -> Bool {
        guard let cached = load(range: range, league: league) else { return false }
        return Date().timeIntervalSince(cached.cachedAt) < maxAge
    }

    private func fileURL(for range: GameRange, league: LeagueCode?) -> URL {
        let key = "\(range.rawValue)-\(league?.rawValue ?? "all")"
        return cacheDir.appendingPathComponent("\(key).json")
    }
}
