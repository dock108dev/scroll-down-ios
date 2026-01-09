import Foundation

/// Team boxscore statistics as defined in the OpenAPI spec (TeamStat schema)
struct TeamStat: Codable, Identifiable {
    let team: String
    let isHome: Bool
    let stats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?
    
    /// Computed ID for Identifiable conformance
    var id: String { team }
    
    enum CodingKeys: String, CodingKey {
        case team
        case isHome = "is_home"
        case stats
        case source
        case updatedAt = "updated_at"
    }
}



