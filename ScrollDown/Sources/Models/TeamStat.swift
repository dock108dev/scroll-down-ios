import Foundation

/// Team boxscore statistics
struct TeamStat: Codable, Identifiable {
    let team: String
    let isHome: Bool
    let stats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?

    var id: String { team }

    init(team: String, isHome: Bool, stats: [String: AnyCodable], source: String? = nil, updatedAt: String? = nil) {
        self.team = team
        self.isHome = isHome
        self.stats = stats
        self.source = source
        self.updatedAt = updatedAt
    }
}
