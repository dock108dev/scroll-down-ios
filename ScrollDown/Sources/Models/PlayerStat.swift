import Foundation

/// Player boxscore statistics as defined in the OpenAPI spec (PlayerStat schema)
struct PlayerStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let minutes: Double?
    let points: Int?
    let rebounds: Int?
    let assists: Int?
    let yards: Int?          // Football only
    let touchdowns: Int?     // Football only
    let rawStats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?
    
    /// Computed ID for Identifiable conformance
    var id: String { "\(team)-\(playerName)" }
    
    enum CodingKeys: String, CodingKey {
        case team
        case playerName = "player_name"
        case minutes
        case points
        case rebounds
        case assists
        case yards
        case touchdowns
        case rawStats = "raw_stats"
        case source
        case updatedAt = "updated_at"
    }
}



