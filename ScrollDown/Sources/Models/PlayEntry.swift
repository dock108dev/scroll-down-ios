import Foundation

/// Play-by-play event as defined in the OpenAPI spec (PlayEntry schema)
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
        case playerName = "player_name"
        case description
        case homeScore = "home_score"
        case awayScore = "away_score"
    }
}



