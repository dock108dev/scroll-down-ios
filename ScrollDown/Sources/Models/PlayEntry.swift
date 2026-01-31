import Foundation

/// Play-by-play event as defined in the OpenAPI spec (PlayEntry schema)
/// Handles snake_case (app endpoint), camelCase (admin endpoint), and story API formats
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
        // snake_case keys
        case playIndexSnake = "play_index"
        case gameClockSnake = "game_clock"
        case playTypeSnake = "play_type"
        case teamAbbreviationSnake = "team_abbreviation"
        case playerNameSnake = "player_name"
        case homeScoreSnake = "home_score"
        case awayScoreSnake = "away_score"
        // camelCase keys (admin endpoint)
        case playIndexCamel = "playIndex"
        case gameClockCamel = "gameClock"
        case playTypeCamel = "playType"
        case teamAbbreviationCamel = "teamAbbreviation"
        case playerNameCamel = "playerName"
        case homeScoreCamel = "homeScore"
        case awayScoreCamel = "awayScore"
        // Common keys
        case quarter
        case description
        case team  // Story API uses "team" instead of "team_abbreviation"
        case scoreHome = "score_home"  // Story API uses "score_home"
        case scoreAway = "score_away"  // Story API uses "score_away"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle both snake_case and camelCase for playIndex
        playIndex = (try? container.decode(Int.self, forKey: .playIndexSnake))
            ?? (try? container.decode(Int.self, forKey: .playIndexCamel))
            ?? 0

        quarter = try container.decodeIfPresent(Int.self, forKey: .quarter)

        gameClock = (try? container.decode(String.self, forKey: .gameClockSnake))
            ?? (try? container.decode(String.self, forKey: .gameClockCamel))

        playType = (try? container.decode(PlayType.self, forKey: .playTypeSnake))
            ?? (try? container.decode(PlayType.self, forKey: .playTypeCamel))

        playerName = (try? container.decode(String.self, forKey: .playerNameSnake))
            ?? (try? container.decode(String.self, forKey: .playerNameCamel))

        description = try container.decodeIfPresent(String.self, forKey: .description)

        // Handle team_abbreviation, teamAbbreviation, and team keys
        teamAbbreviation = (try? container.decode(String.self, forKey: .teamAbbreviationSnake))
            ?? (try? container.decode(String.self, forKey: .teamAbbreviationCamel))
            ?? (try? container.decode(String.self, forKey: .team))

        // Handle home_score, homeScore, and score_home keys
        homeScore = (try? container.decode(Int.self, forKey: .homeScoreSnake))
            ?? (try? container.decode(Int.self, forKey: .homeScoreCamel))
            ?? (try? container.decode(Int.self, forKey: .scoreHome))

        awayScore = (try? container.decode(Int.self, forKey: .awayScoreSnake))
            ?? (try? container.decode(Int.self, forKey: .awayScoreCamel))
            ?? (try? container.decode(Int.self, forKey: .scoreAway))
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
        try container.encode(playIndex, forKey: .playIndexSnake)
        try container.encodeIfPresent(quarter, forKey: .quarter)
        try container.encodeIfPresent(gameClock, forKey: .gameClockSnake)
        try container.encodeIfPresent(playType, forKey: .playTypeSnake)
        try container.encodeIfPresent(teamAbbreviation, forKey: .teamAbbreviationSnake)
        try container.encodeIfPresent(playerName, forKey: .playerNameSnake)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(homeScore, forKey: .homeScoreSnake)
        try container.encodeIfPresent(awayScore, forKey: .awayScoreSnake)
    }
}



