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
    }

    /// Context string for a saved score, e.g. "@ Q2 · 2m ago"
    func scoreContext(for gameId: Int) -> String? {
        guard let position = load(gameId: gameId),
              position.awayScore != nil, position.homeScore != nil else { return nil }
        var parts: [String] = []
        if let timeLabel = position.timeLabel {
            parts.append("@ \(timeLabel)")
        } else if let periodLabel = position.periodLabel {
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
        // No time info available — only show if user actually scrolled into the timeline
        guard position.playIndex > 0 else { return nil }
        return nil
    }
}
