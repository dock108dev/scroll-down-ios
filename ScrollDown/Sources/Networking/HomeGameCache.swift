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
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Save a section's games to disk cache.
    func save(games: [GameSummary], lastUpdatedAt: String?, range: GameRange, league: LeagueCode?) {
        let section = CachedSection(games: games, lastUpdatedAt: lastUpdatedAt, cachedAt: Date())
        let url = fileURL(for: range, league: league)
        do {
            let data = try encoder.encode(section)
            try data.write(to: url, options: .atomic)
        } catch {
            // Cache write failures are non-fatal — app continues working without cache
        }
    }

    /// Load a cached section from disk. Returns nil if no cache exists.
    func load(range: GameRange, league: LeagueCode?) -> CachedSection? {
        let url = fileURL(for: range, league: league)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(CachedSection.self, from: data)
    }

    /// Remove all cached game data.
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private func fileURL(for range: GameRange, league: LeagueCode?) -> URL {
        let key = "\(range.rawValue)-\(league?.rawValue ?? "all")"
        return cacheDir.appendingPathComponent("\(key).json")
    }
}
