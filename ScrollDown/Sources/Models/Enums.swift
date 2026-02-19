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
enum GameStatus: RawRepresentable, Codable, Equatable {
    case scheduled
    case inProgress
    case completed
    case `final`
    case postponed
    case canceled
    case unknown(String)

    var rawValue: String {
        switch self {
        case .scheduled: return "scheduled"
        case .inProgress: return "in_progress"
        case .completed: return "completed"
        case .final: return "final"
        case .postponed: return "postponed"
        case .canceled: return "canceled"
        case .unknown(let value): return value
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "scheduled": self = .scheduled
        case "in_progress": self = .inProgress
        case "completed": self = .completed
        case "final": self = .final
        case "postponed": self = .postponed
        case "canceled": self = .canceled
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = GameStatus(rawValue: rawValue) ?? .unknown(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func == (lhs: GameStatus, rhs: GameStatus) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    var isCompleted: Bool {
        self == .completed || self == .final
    }
}

// MARK: - Market Type
/// Betting market type as defined in the OpenAPI spec
/// Uses RawRepresentable with unknown(String) fallback so new API values never crash decoding.
enum MarketType: RawRepresentable, Codable, Equatable, Hashable {
    case spread
    case moneyline
    case total
    case alternateSpread
    case alternateTotal
    case playerPoints
    case playerRebounds
    case playerAssists
    case playerThrees
    case playerBlocks
    case playerSteals
    case playerGoals
    case playerShotsOnGoal
    case playerTotalSaves
    case playerPRA
    case teamTotal
    case unknown(String)

    var rawValue: String {
        switch self {
        case .spread: return "spread"
        case .moneyline: return "moneyline"
        case .total: return "total"
        case .alternateSpread: return "alternate_spreads"
        case .alternateTotal: return "alternate_totals"
        case .playerPoints: return "player_points"
        case .playerRebounds: return "player_rebounds"
        case .playerAssists: return "player_assists"
        case .playerThrees: return "player_threes"
        case .playerBlocks: return "player_blocks"
        case .playerSteals: return "player_steals"
        case .playerGoals: return "player_goals"
        case .playerShotsOnGoal: return "player_shots_on_goal"
        case .playerTotalSaves: return "player_total_saves"
        case .playerPRA: return "player_points_rebounds_assists"
        case .teamTotal: return "team_totals"
        case .unknown(let value): return value
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "spread": self = .spread
        case "moneyline": self = .moneyline
        case "total": self = .total
        case "alternate_spreads": self = .alternateSpread
        case "alternate_totals": self = .alternateTotal
        case "player_points": self = .playerPoints
        case "player_rebounds": self = .playerRebounds
        case "player_assists": self = .playerAssists
        case "player_threes": self = .playerThrees
        case "player_blocks": self = .playerBlocks
        case "player_steals": self = .playerSteals
        case "player_goals": self = .playerGoals
        case "player_shots_on_goal": self = .playerShotsOnGoal
        case "player_total_saves": self = .playerTotalSaves
        case "player_points_rebounds_assists": self = .playerPRA
        case "team_totals": self = .teamTotal
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = MarketType(rawValue: rawValue) ?? .unknown(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func == (lhs: MarketType, rhs: MarketType) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    /// Human-readable stat type name for display labels
    var displayName: String {
        switch self {
        case .spread: return "Spread"
        case .moneyline: return "Moneyline"
        case .total: return "Total"
        case .alternateSpread: return "Alt Spread"
        case .alternateTotal: return "Alt Total"
        case .playerPoints: return "Points"
        case .playerRebounds: return "Rebounds"
        case .playerAssists: return "Assists"
        case .playerThrees: return "Threes"
        case .playerBlocks: return "Blocks"
        case .playerSteals: return "Steals"
        case .playerGoals: return "Goals"
        case .playerShotsOnGoal: return "Shots on Goal"
        case .playerTotalSaves: return "Total Saves"
        case .playerPRA: return "Pts+Reb+Ast"
        case .teamTotal: return "Team Total"
        case .unknown(let value): return value
        }
    }

    /// Whether this market type is a player prop
    var isPlayerProp: Bool {
        switch self {
        case .playerPoints, .playerRebounds, .playerAssists, .playerThrees,
             .playerBlocks, .playerSteals, .playerGoals, .playerShotsOnGoal,
             .playerTotalSaves, .playerPRA:
            return true
        default:
            return false
        }
    }
}

// MARK: - Market Category

/// Market category for grouping odds in the game detail view
enum MarketCategory: String, CaseIterable, Identifiable, Equatable {
    case mainline
    case playerProp = "player_prop"
    case teamProp = "team_prop"
    case alternate
    case period
    case gameProp = "game_prop"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .mainline: return "Main"
        case .playerProp: return "Player Props"
        case .teamProp: return "Team Props"
        case .alternate: return "Alternates"
        case .period: return "Period"
        case .gameProp: return "Game Props"
        }
    }
}

extension OddsEntry {
    /// Resolves the market category — prefers API-provided value, falls back to inference from marketType.
    var resolvedCategory: MarketCategory {
        if let cat = marketCategory, let resolved = MarketCategory(rawValue: cat) {
            return resolved
        }
        // Infer from marketType
        switch marketType {
        case .spread, .moneyline, .total:
            return .mainline
        case .playerPoints, .playerRebounds, .playerAssists, .playerThrees,
             .playerBlocks, .playerSteals, .playerGoals, .playerShotsOnGoal,
             .playerTotalSaves, .playerPRA:
            return .playerProp
        case .teamTotal:
            return .teamProp
        case .alternateSpread, .alternateTotal:
            return .alternate
        case .unknown(let raw):
            assertionFailure("Unknown MarketType '\(raw)' — add a case or update API")
            return .mainline
        }
    }
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


