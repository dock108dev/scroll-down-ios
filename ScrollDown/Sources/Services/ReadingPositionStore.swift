import Foundation

/// Persists reading positions locally using UserDefaults, keyed by game ID.
/// No server sync — local-only until auth exists.
final class ReadingPositionStore {
    static let shared = ReadingPositionStore()

    private let defaults = UserDefaults.standard
    private let prefix = "game.position."
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // In-memory caches to avoid repeated UserDefaults reads
    private var scoreCache: [Int: (away: Int, home: Int)?] = [:]
    private var contextCache: [Int: String?] = [:]

    private init() {}

    func save(gameId: Int, position: ReadingPosition) {
        guard let data = try? encoder.encode(position) else { return }
        defaults.set(data, forKey: prefix + "\(gameId)")
        // Invalidate caches so next read picks up the new position
        scoreCache.removeValue(forKey: gameId)
        contextCache.removeValue(forKey: gameId)
    }

    func load(gameId: Int) -> ReadingPosition? {
        guard let data = defaults.data(forKey: prefix + "\(gameId)") else { return nil }
        return try? decoder.decode(ReadingPosition.self, from: data)
    }

    func clear(gameId: Int) {
        defaults.removeObject(forKey: prefix + "\(gameId)")
        scoreCache.removeValue(forKey: gameId)
        contextCache.removeValue(forKey: gameId)
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
        contextCache.removeValue(forKey: gameId)
    }

    /// Preload caches for a batch of game IDs to avoid individual UserDefaults reads.
    func preload(gameIds: [Int]) {
        for gameId in gameIds {
            guard scoreCache[gameId] == nil else { continue }
            _ = savedScores(for: gameId)
        }
    }

    /// Context string for a saved score, e.g. "@ Q2 · 2m ago"
    func scoreContext(for gameId: Int) -> String? {
        if let cached = contextCache[gameId] { return cached }
        guard let position = load(gameId: gameId),
              position.awayScore != nil, position.homeScore != nil else {
            contextCache[gameId] = nil
            return nil
        }
        var parts: [String] = []
        if let timeLabel = position.timeLabel {
            parts.append("@ \(timeLabel)")
        } else if let periodLabel = position.periodLabel {
            parts.append("@ \(periodLabel)")
        }
        parts.append(relativeTimeString(from: position.savedAt))
        let result = parts.joined(separator: " · ")
        contextCache[gameId] = result
        return result
    }

    private func relativeTimeString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    /// Human-readable text for resume context, e.g. "Stopped at Q3 4:32"
    func resumeDisplayText(for gameId: Int) -> String? {
        guard let position = load(gameId: gameId) else { return nil }
        if let timeLabel = position.timeLabel {
            return "Stopped at \(timeLabel)"
        }
        if let periodLabel = position.periodLabel {
            return "Stopped at \(periodLabel)"
        }
        // No time info available — only show if user actually scrolled into the timeline
        guard position.playIndex > 0 else { return nil }
        return nil
    }
}
