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
    case postponed
    case canceled
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
/// Play-by-play event type classification as defined in the OpenAPI spec
enum PlayType: String, Codable {
    case shot
    case madeShot = "made_shot"
    case missedShot = "missed_shot"
    case rebound
    case assist
    case turnover
    case steal
    case block
    case foul
    case freeThrow = "free_throw"
    case timeout
    case substitution
    case jumpBall = "jump_ball"
    case periodStart = "period_start"
    case periodEnd = "period_end"
    case gameEnd = "game_end"
    case highlight
    case play
}

