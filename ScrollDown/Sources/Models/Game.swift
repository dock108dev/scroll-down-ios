import Foundation

/// Full game metadata
struct Game: Codable, Identifiable, Hashable {
    let id: Int
    let leagueCode: String
    let season: Int?
    let seasonType: String?
    let gameDate: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let status: GameStatus
    let scrapeVersion: Int?
    let lastScrapedAt: String?
    let hasBoxscore: Bool?
    let hasPlayerStats: Bool?
    let hasOdds: Bool?
    let hasSocial: Bool?
    let hasPbp: Bool?
    var hasFlow: Bool? = nil
    let playCount: Int?
    let socialPostCount: Int?
    let homeTeamXHandle: String?
    let awayTeamXHandle: String?
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let homeTeamColorLight: String?
    let homeTeamColorDark: String?
    let awayTeamColorLight: String?
    let awayTeamColorDark: String?
    var lastIngestedAt: String? = nil
    var lastPbpAt: String? = nil
    var lastSocialAt: String? = nil
    var lastOddsAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case leagueCode
        case season
        case seasonType
        case gameDate
        case homeTeam
        case awayTeam
        case homeScore
        case awayScore
        case status
        case scrapeVersion
        case lastScrapedAt
        case hasBoxscore
        case hasPlayerStats
        case hasOdds
        case hasSocial
        case hasPbp
        case hasFlow
        case playCount
        case socialPostCount
        case homeTeamXHandle
        case awayTeamXHandle
        case homeTeamAbbr
        case awayTeamAbbr
        case homeTeamColorLight
        case homeTeamColorDark
        case awayTeamColorLight
        case awayTeamColorDark
        case lastIngestedAt
        case lastPbpAt
        case lastSocialAt
        case lastOddsAt
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties
extension Game {
    private enum Formatting {
        static let isoFormatterFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        static let isoFormatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        static let mediumDateTimeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f
        }()
    }

    /// Formatted date for display
    var formattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        return Formatting.mediumDateTimeFormatter.string(from: date)
    }

    /// Formatted score string (e.g., "112 - 108")
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "— vs —"
        }
        return "\(home) - \(away)"
    }

    var matchupTitle: String {
        "\(awayTeam) at \(homeTeam)"
    }

    /// Parsed game date
    var parsedGameDate: Date? {
        Formatting.isoFormatterFractional.date(from: gameDate)
            ?? Formatting.isoFormatter.date(from: gameDate)
    }
}
