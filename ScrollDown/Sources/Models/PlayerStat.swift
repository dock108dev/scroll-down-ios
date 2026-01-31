import Foundation

/// Player boxscore statistics
struct PlayerStat: Codable, Identifiable {
    let team: String
    let playerName: String
    let minutes: Double?
    let points: Int?
    let rebounds: Int?
    let assists: Int?
    let yards: Int?
    let touchdowns: Int?
    let rawStats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?

    var id: String { "\(team)-\(playerName)" }

    init(
        team: String,
        playerName: String,
        minutes: Double? = nil,
        points: Int? = nil,
        rebounds: Int? = nil,
        assists: Int? = nil,
        yards: Int? = nil,
        touchdowns: Int? = nil,
        rawStats: [String: AnyCodable] = [:],
        source: String? = nil,
        updatedAt: String? = nil
    ) {
        self.team = team
        self.playerName = playerName
        self.minutes = minutes
        self.points = points
        self.rebounds = rebounds
        self.assists = assists
        self.yards = yards
        self.touchdowns = touchdowns
        self.rawStats = rawStats
        self.source = source
        self.updatedAt = updatedAt
    }
}
