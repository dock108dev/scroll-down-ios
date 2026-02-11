import Foundation

/// Disk-based cache for home screen game sections.
/// Persists game data to the Caches directory so the home screen can show
/// cached data instantly on app open (stale-while-revalidate pattern).
final class HomeGameCache {
    static let shared = HomeGameCache()

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
            print("[HomeGameCache] Failed to create cache directory: \(error.localizedDescription)")
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
            print("[HomeGameCache] Save failed for \(range.rawValue): \(error.localizedDescription)")
        }
    }

    /// Load a cached section from disk. Returns nil if no cache exists.
    func load(range: GameRange, league: LeagueCode?) -> CachedSection? {
        let url = fileURL(for: range, league: league)
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try decoder.decode(CachedSection.self, from: data)
        } catch {
            print("[HomeGameCache] Decode failed for \(range.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    /// Remove all cached game data.
    func clearAll() {
        do {
            try FileManager.default.removeItem(at: cacheDir)
        } catch {
            print("[HomeGameCache] Failed to remove cache directory: \(error.localizedDescription)")
        }
        do {
            try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        } catch {
            print("[HomeGameCache] Failed to recreate cache directory: \(error.localizedDescription)")
        }
    }

    private func fileURL(for range: GameRange, league: LeagueCode?) -> URL {
        let key = "\(range.rawValue)-\(league?.rawValue ?? "all")"
        return cacheDir.appendingPathComponent("\(key).json")
    }
}
