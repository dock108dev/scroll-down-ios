import Foundation

/// Play-by-play event
struct PlayEntry: Codable, Identifiable, Equatable {
    let playIndex: Int
    let quarter: Int?
    let gameClock: String?
    let playType: PlayType?
    let teamAbbreviation: String?
    let playerName: String?
    let description: String?
    let homeScore: Int?
    let awayScore: Int?

    // Server-provided labels (Phase 3)
    let periodLabel: String?
    let timeLabel: String?

    // Server-provided tier (Phase 4)
    let tier: Int?

    var id: Int { playIndex }

    init(
        playIndex: Int,
        quarter: Int? = nil,
        gameClock: String? = nil,
        playType: PlayType? = nil,
        teamAbbreviation: String? = nil,
        playerName: String? = nil,
        description: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        periodLabel: String? = nil,
        timeLabel: String? = nil,
        tier: Int? = nil
    ) {
        self.playIndex = playIndex
        self.quarter = quarter
        self.gameClock = gameClock
        self.playType = playType
        self.teamAbbreviation = teamAbbreviation
        self.playerName = playerName
        self.description = description
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.periodLabel = periodLabel
        self.timeLabel = timeLabel
        self.tier = tier
    }
}
