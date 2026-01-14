import Foundation

/// DEPRECATED: Compact timeline moment as defined in the OpenAPI spec (CompactMoment schema)
/// Timeline is now rendered via UnifiedTimelineEvent from timeline_json
/// This model is kept for reference but should be deleted when cleanup is complete
@available(*, deprecated, message: "Use UnifiedTimelineEvent from timeline_json")
struct CompactMoment: Codable, Identifiable, Equatable {
    let id: StringOrInt
    let period: Int?
    let gameClock: String?
    let title: String?
    let description: String?
    let teamAbbreviation: String?
    let playerName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case period
        case gameClock = "game_clock"
        case title
        case description
        case teamAbbreviation = "team_abbreviation"
        case playerName = "player_name"
    }
}

extension CompactMoment {
    init(play: PlayEntry) {
        id = .int(play.playIndex)
        period = play.quarter
        gameClock = play.gameClock
        title = play.description
        description = nil
        teamAbbreviation = play.teamAbbreviation
        playerName = play.playerName
    }

    var displayTitle: String {
        title ?? description ?? "Play update"
    }

    var timeLabel: String? {
        var parts: [String] = []
        if let period {
            parts.append("Q\(period)")
        }
        if let gameClock {
            parts.append(gameClock)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}
