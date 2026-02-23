import Foundation

/// Persists reading positions locally using UserDefaults, keyed by game ID.
/// No server sync — local-only until auth exists.
final class ReadingPositionStore {
    static let shared = ReadingPositionStore()

    private let defaults = UserDefaults.standard
    private let prefix = "game.position."
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // In-memory cache to avoid repeated UserDefaults reads
    private var scoreCache: [Int: (away: Int, home: Int)?] = [:]

    private init() {}

    func save(gameId: Int, position: ReadingPosition) {
        guard let data = try? encoder.encode(position) else { return }
        defaults.set(data, forKey: prefix + "\(gameId)")
        // Invalidate cache so next read picks up the new position
        scoreCache.removeValue(forKey: gameId)
    }

    func load(gameId: Int) -> ReadingPosition? {
        guard let data = defaults.data(forKey: prefix + "\(gameId)") else { return nil }
        return try? decoder.decode(ReadingPosition.self, from: data)
    }

    func clear(gameId: Int) {
        defaults.removeObject(forKey: prefix + "\(gameId)")
        scoreCache.removeValue(forKey: gameId)
    }

    /// Returns saved scores for a game, if both home and away are present.
    func savedScores(for gameId: Int) -> (away: Int, home: Int)? {
        if let cached = scoreCache[gameId] { return cached }
        guard let position = load(gameId: gameId),
              let away = position.awayScore,
              let home = position.homeScore else {
            scoreCache[gameId] = nil
            return nil
        }
        let result = (away: away, home: home)
        scoreCache[gameId] = result
        return result
    }

    /// Updates (or creates) a reading position with new scores and a fresh timestamp.
    /// When `period`/`gameClock`/`periodLabel`/`timeLabel` are supplied they overwrite
    /// the stored values; otherwise existing position data is preserved.
    func updateScores(
        for gameId: Int,
        awayScore: Int,
        homeScore: Int,
        period: Int? = nil,
        gameClock: String? = nil,
        periodLabel: String? = nil,
        timeLabel: String? = nil
    ) {
        let existing = load(gameId: gameId)
        let position = ReadingPosition(
            playIndex: existing?.playIndex ?? 0,
            period: period ?? existing?.period,
            gameClock: gameClock ?? existing?.gameClock,
            periodLabel: periodLabel ?? existing?.periodLabel,
            timeLabel: timeLabel ?? existing?.timeLabel,
            savedAt: Date(),
            homeScore: homeScore,
            awayScore: awayScore
        )
        save(gameId: gameId, position: position)
        scoreCache[gameId] = (away: awayScore, home: homeScore)
    }

    /// Preload caches for a batch of game IDs to avoid individual UserDefaults reads.
    func preload(gameIds: [Int]) {
        for gameId in gameIds {
            guard scoreCache[gameId] == nil else { continue }
            _ = savedScores(for: gameId)
        }
    }

    /// Game time label only (e.g. "@ Q3 5:42"), no relative time. SSOT for game position display.
    func gameTimeLabel(for gameId: Int) -> String? {
        guard let position = load(gameId: gameId),
              position.awayScore != nil, position.homeScore != nil else {
            return nil
        }
        if let timeLabel = position.timeLabel {
            return "@ \(timeLabel)"
        }
        if let periodLabel = position.periodLabel {
            return "@ \(periodLabel)"
        }
        return nil
    }
}
