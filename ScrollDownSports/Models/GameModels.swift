import Foundation

struct Score: Decodable, Hashable {
    let home: Int?
    let away: Int?
}

protocol GameStatusRepresentable {
    var status: String { get }
    var isLiveFlag: Bool? { get }
    var isFinalFlag: Bool? { get }
    var gameDate: Date { get }
}

extension GameStatusRepresentable {
    var isLiveGame: Bool {
        if let isLiveFlag {
            return isLiveFlag
        }
        return ["in_progress", "live"].contains(status.lowercased())
    }

    var isFinalGame: Bool {
        if let isFinalFlag {
            return isFinalFlag
        }
        return ["completed", "final", "recap_ready", "archived"].contains(status.lowercased())
    }

    var isPregame: Bool {
        ["scheduled", "pregame"].contains(status.lowercased())
    }
}

struct GameListResponse: Decodable {
    let games: [GameSummary]
    let total: Int?
    let lastUpdatedAt: String?
}

struct GameSummary: Decodable, Identifiable, Hashable, GameStatusRepresentable {
    let id: Int
    let leagueCode: String
    let gameDate: Date
    let localGameDate: String?
    let status: String
    let homeTeam: String
    let awayTeam: String
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let currentPeriod: Int?
    let currentPeriodLabel: String?
    let gameClock: String?
    let score: Score?
    let homeScore: Int?
    let awayScore: Int?
    let hasPbp: Bool?
    let playCount: Int?
    let isLiveFlag: Bool?
    let isFinalFlag: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueCode
        case gameDate
        case localGameDate
        case status
        case homeTeam
        case awayTeam
        case homeTeamAbbr
        case awayTeamAbbr
        case currentPeriod
        case currentPeriodLabel
        case gameClock
        case score
        case homeScore
        case awayScore
        case hasPbp
        case playCount
        case isLiveFlag = "isLive"
        case isFinalFlag = "isFinal"
    }

    var resolvedHomeScore: Int? { score?.home ?? homeScore }
    var resolvedAwayScore: Int? { score?.away ?? awayScore }
    var matchupText: String { "\(awayTeam) at \(homeTeam)" }
}

struct GameDetailResponse: Decodable {
    let game: Game
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let plays: [PlayEntry]
    let mlbBatters: [MLBBatterStat]?
    let mlbPitchers: [MLBPitcherStat]?
    let nhlSkaters: [NHLPlayerStat]?
    let nhlGoalies: [NHLPlayerStat]?
}

struct Game: Decodable, Identifiable, Hashable, GameStatusRepresentable {
    let id: Int
    let leagueCode: String
    let gameDate: Date
    let localGameDate: String?
    let status: String
    let homeTeam: String
    let awayTeam: String
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let currentPeriod: Int?
    let currentPeriodLabel: String?
    let gameClock: String?
    let score: Score?
    let homeScore: Int?
    let awayScore: Int?
    let isLiveFlag: Bool?
    let isFinalFlag: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case leagueCode
        case gameDate
        case localGameDate
        case status
        case homeTeam
        case awayTeam
        case homeTeamAbbr
        case awayTeamAbbr
        case currentPeriod
        case currentPeriodLabel
        case gameClock
        case score
        case homeScore
        case awayScore
        case isLiveFlag = "isLive"
        case isFinalFlag = "isFinal"
    }

    var resolvedHomeScore: Int? { score?.home ?? homeScore }
    var resolvedAwayScore: Int? { score?.away ?? awayScore }
    var matchupText: String { "\(awayTeam) at \(homeTeam)" }
}

struct TeamStat: Decodable, Identifiable, Hashable {
    var id: String { "\(team)-\(isHome)" }
    let team: String
    let isHome: Bool
    let stats: [String: JSONValue]
    let normalizedStats: [NormalizedStat]?
}

struct NormalizedStat: Decodable, Hashable {
    let key: String
    let displayLabel: String
    let group: String?
    let value: JSONValue?
}

struct PlayerStat: Decodable, Identifiable, Hashable {
    var id: String { "\(team)-\(playerName)" }
    let team: String
    let playerName: String
    let minutes: Double?
    let points: Double?
    let rebounds: Double?
    let assists: Double?
    let yards: Double?
    let touchdowns: Double?
    let rawStats: [String: JSONValue]
}

struct PlayEntry: Decodable, Identifiable, Hashable {
    var id: String { eventId ?? "\(playIndex)-\(periodLabel ?? "")-\(gameClock ?? "")" }
    let eventId: String?
    let playIndex: Int
    let quarter: Int?
    let gameClock: String?
    let playType: String?
    let teamAbbreviation: String?
    let playerName: String?
    let description: String?
    let homeScore: Int?
    let awayScore: Int?
    let score: Score?
    let periodLabel: String?
    let timeLabel: String?
    let tier: Int?
    let scoreChanged: Bool?

    var clockText: String {
        [periodLabel, timeLabel ?? gameClock]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " ")
    }
}

struct MLBBatterStat: Decodable, Identifiable, Hashable {
    var id: String { "\(team)-\(playerName)-batter" }
    let team: String
    let playerName: String
    let position: String?
    let atBats: Int?
    let hits: Int?
    let runs: Int?
    let rbi: Int?
    let homeRuns: Int?
    let baseOnBalls: Int?
    let strikeOuts: Int?
}

struct MLBPitcherStat: Decodable, Identifiable, Hashable {
    var id: String { "\(team)-\(playerName)-pitcher" }
    let team: String
    let playerName: String
    let inningsPitched: String?
    let hits: Int?
    let runs: Int?
    let earnedRuns: Int?
    let baseOnBalls: Int?
    let strikeOuts: Int?
    let homeRuns: Int?
}

struct NHLPlayerStat: Decodable, Identifiable, Hashable {
    var id: String { "\(team)-\(playerName)" }
    let team: String
    let playerName: String
    let goals: Int?
    let assists: Int?
    let points: Int?
    let shotsOnGoal: Int?
    let saves: Int?
    let goalsAgainst: Int?
    let rawStats: [String: JSONValue]?
}

