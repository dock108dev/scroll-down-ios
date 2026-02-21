import Foundation

/// Persists reading positions locally using UserDefaults, keyed by game ID.
/// No server sync — local-only until auth exists.
final class ReadingPositionStore {
    static let shared = ReadingPositionStore()

    private let defaults = UserDefaults.standard
    private let prefix = "game.position."
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func save(gameId: Int, position: ReadingPosition) {
        guard let data = try? encoder.encode(position) else { return }
        defaults.set(data, forKey: prefix + "\(gameId)")
    }

    func load(gameId: Int) -> ReadingPosition? {
        guard let data = defaults.data(forKey: prefix + "\(gameId)") else { return nil }
        return try? decoder.decode(ReadingPosition.self, from: data)
    }

    func clear(gameId: Int) {
        defaults.removeObject(forKey: prefix + "\(gameId)")
    }

    /// Returns saved scores for a game, if both home and away are present.
    func savedScores(for gameId: Int) -> (away: Int, home: Int)? {
        guard let position = load(gameId: gameId),
              let away = position.awayScore,
              let home = position.homeScore else { return nil }
        return (away: away, home: home)
    }

    /// Updates (or creates) a reading position with new scores and a fresh timestamp.
    func updateScores(for gameId: Int, awayScore: Int, homeScore: Int) {
        let existing = load(gameId: gameId)
        let position = ReadingPosition(
            playIndex: existing?.playIndex ?? 0,
            period: existing?.period,
            gameClock: existing?.gameClock,
            periodLabel: existing?.periodLabel,
            timeLabel: existing?.timeLabel,
            savedAt: Date(),
            homeScore: homeScore,
            awayScore: awayScore
        )
        save(gameId: gameId, position: position)
    }

    /// Context string for a saved score, e.g. "@ Q2 · 2m ago"
    func scoreContext(for gameId: Int) -> String? {
        guard let position = load(gameId: gameId),
              position.awayScore != nil, position.homeScore != nil else { return nil }
        var parts: [String] = []
        if let periodLabel = position.periodLabel {
            parts.append("@ \(periodLabel)")
        }
        parts.append(relativeTimeString(from: position.savedAt))
        return parts.joined(separator: " · ")
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
        return "Stopped at play \(position.playIndex)"
    }
}
