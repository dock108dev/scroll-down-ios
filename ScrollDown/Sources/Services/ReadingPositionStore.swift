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
