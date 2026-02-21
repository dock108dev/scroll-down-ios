import Foundation

/// Captures a user's reading position within a game's play-by-play timeline.
/// Stored locally in UserDefaults, keyed by game ID.
struct ReadingPosition: Codable {
    let playIndex: Int
    let period: Int?
    let gameClock: String?
    let periodLabel: String?  // "Q3", "P2", "H1"
    let timeLabel: String?    // "Q3 4:32"
    let savedAt: Date
    let homeScore: Int?
    let awayScore: Int?

    init(playIndex: Int, period: Int?, gameClock: String?, periodLabel: String?, timeLabel: String?, savedAt: Date, homeScore: Int? = nil, awayScore: Int? = nil) {
        self.playIndex = playIndex
        self.period = period
        self.gameClock = gameClock
        self.periodLabel = periodLabel
        self.timeLabel = timeLabel
        self.savedAt = savedAt
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}
