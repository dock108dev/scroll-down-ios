import Foundation

/// Play-by-play event as defined in the OpenAPI spec (PlayEntry schema)
/// Handles both game detail format and story API format
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

    /// Use playIndex as ID for Identifiable
    var id: Int { playIndex }

    enum CodingKeys: String, CodingKey {
        case playIndex = "play_index"
        case quarter
        case gameClock = "game_clock"
        case playType = "play_type"
        case teamAbbreviation = "team_abbreviation"
        case team  // Story API uses "team" instead of "team_abbreviation"
        case playerName = "player_name"
        case description
        case homeScore = "home_score"
        case awayScore = "away_score"
        case scoreHome = "score_home"  // Story API uses "score_home"
        case scoreAway = "score_away"  // Story API uses "score_away"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playIndex = try container.decode(Int.self, forKey: .playIndex)
        quarter = try container.decodeIfPresent(Int.self, forKey: .quarter)
        gameClock = try container.decodeIfPresent(String.self, forKey: .gameClock)
        playType = try container.decodeIfPresent(PlayType.self, forKey: .playType)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName)
        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Handle both team_abbreviation and team keys
        teamAbbreviation = try container.decodeIfPresent(String.self, forKey: .teamAbbreviation)
            ?? container.decodeIfPresent(String.self, forKey: .team)

        // Handle both home_score/away_score and score_home/score_away keys
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreHome)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
            ?? container.decodeIfPresent(Int.self, forKey: .scoreAway)
    }

    init(
        playIndex: Int,
        quarter: Int? = nil,
        gameClock: String? = nil,
        playType: PlayType? = nil,
        teamAbbreviation: String? = nil,
        playerName: String? = nil,
        description: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil
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
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playIndex, forKey: .playIndex)
        try container.encodeIfPresent(quarter, forKey: .quarter)
        try container.encodeIfPresent(gameClock, forKey: .gameClock)
        try container.encodeIfPresent(playType, forKey: .playType)
        try container.encodeIfPresent(teamAbbreviation, forKey: .teamAbbreviation)
        try container.encodeIfPresent(playerName, forKey: .playerName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(homeScore, forKey: .homeScore)
        try container.encodeIfPresent(awayScore, forKey: .awayScore)
    }
}



