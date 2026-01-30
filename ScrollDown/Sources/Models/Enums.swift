import Foundation

// MARK: - League Code
/// League codes as defined in the OpenAPI spec
enum LeagueCode: String, Codable, CaseIterable {
    case nba = "NBA"
    case ncaab = "NCAAB"
    case nfl = "NFL"
    case ncaaf = "NCAAF"
    case mlb = "MLB"
    case nhl = "NHL"
}

// MARK: - Game Status
/// Game status as defined in the OpenAPI spec
enum GameStatus: String, Codable {
    case scheduled
    case inProgress = "in_progress"
    case completed
    case final = "final"  // API returns "final" for completed games
    case postponed
    case canceled
    
    /// Normalize to canonical status
    var isCompleted: Bool {
        self == .completed || self == .final
    }
}

// MARK: - Market Type
/// Betting market type as defined in the OpenAPI spec
enum MarketType: String, Codable {
    case spread
    case moneyline
    case total
}

// MARK: - Media Type
/// Type of media in social post as defined in the OpenAPI spec
enum MediaType: String, Codable {
    case video
    case image
    case none
}

// MARK: - Play Type
/// Play-by-play event type classification
/// Supports NBA, NHL, and other leagues
enum PlayType: RawRepresentable, Codable, Equatable {
    // Basketball (NBA/NCAAB)
    case shot
    case madeShot
    case missedShot
    case rebound
    case turnover
    case steal
    case block
    case foul
    case freeThrow
    case jumpBall

    // Hockey (NHL)
    case goal
    case save
    case penalty
    case faceoff
    case hit
    case giveaway
    case takeaway
    case blockedShot
    case miss           // Missed shot (NHL)
    case stoppage       // Play stoppage (NHL)

    // Basketball additional types
    case tip            // Tip-off / jump ball
    case threePointer   // 3-point shot (3pt)

    // General (all sports)
    case assist
    case timeout
    case substitution
    case periodStart
    case periodEnd
    case gameEnd
    case highlight
    case play

    case unknown(String)

    var rawValue: String {
        switch self {
        case .shot: return "shot"
        case .madeShot: return "made_shot"
        case .missedShot: return "missed_shot"
        case .rebound: return "rebound"
        case .turnover: return "turnover"
        case .steal: return "steal"
        case .block: return "block"
        case .foul: return "foul"
        case .freeThrow: return "free_throw"
        case .jumpBall: return "jump_ball"
        case .goal: return "goal"
        case .save: return "save"
        case .penalty: return "penalty"
        case .faceoff: return "faceoff"
        case .hit: return "hit"
        case .giveaway: return "giveaway"
        case .takeaway: return "takeaway"
        case .blockedShot: return "blocked_shot"
        case .miss: return "miss"
        case .stoppage: return "stoppage"
        case .tip: return "tip"
        case .threePointer: return "3pt"
        case .assist: return "assist"
        case .timeout: return "timeout"
        case .substitution: return "substitution"
        case .periodStart: return "period_start"
        case .periodEnd: return "period_end"
        case .gameEnd: return "game_end"
        case .highlight: return "highlight"
        case .play: return "play"
        case .unknown(let value): return value
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "shot": self = .shot
        case "made_shot": self = .madeShot
        case "missed_shot": self = .missedShot
        case "rebound": self = .rebound
        case "turnover": self = .turnover
        case "steal": self = .steal
        case "block": self = .block
        case "foul": self = .foul
        case "free_throw": self = .freeThrow
        case "jump_ball": self = .jumpBall
        case "goal": self = .goal
        case "save": self = .save
        case "penalty": self = .penalty
        case "faceoff": self = .faceoff
        case "hit": self = .hit
        case "giveaway": self = .giveaway
        case "takeaway": self = .takeaway
        case "blocked_shot": self = .blockedShot
        case "miss": self = .miss
        case "stoppage": self = .stoppage
        case "tip": self = .tip
        case "3pt": self = .threePointer
        case "three_pointer": self = .threePointer
        case "assist": self = .assist
        case "timeout": self = .timeout
        case "substitution": self = .substitution
        case "period_start": self = .periodStart
        case "period_end": self = .periodEnd
        case "game_end": self = .gameEnd
        case "highlight": self = .highlight
        case "play": self = .play
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = PlayType(rawValue: rawValue) ?? .unknown(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func == (lhs: PlayType, rhs: PlayType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}


