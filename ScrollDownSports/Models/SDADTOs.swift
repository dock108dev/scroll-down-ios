import Foundation

struct SDAScoreDTO: Decodable, Hashable {
    let home: Int?
    let away: Int?
}

struct SDAGameListResponseDTO: Decodable {
    let games: [SDAGameSummaryDTO]
    let total: Int?
    let lastUpdatedAt: String?
}

struct SDAGameSummaryDTO: Decodable, Identifiable, Hashable {
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
    let score: SDAScoreDTO?
    let homeScore: Int?
    let awayScore: Int?
    let hasPbp: Bool?
    let playCount: Int?
    let isLiveFlag: Bool?
    let isFinalFlag: Bool?
    let presentation: SDAMobilePresentationDTO?
    let eligibility: SDAGameEligibilityDTO?
    let scoreboard: SDAScoreboardDTO?

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
        case presentation
        case eligibility
        case scoreboard
    }
}

struct SDAGameDetailResponseDTO: Decodable {
    let detailContractVersion: Int
    let game: SDAGameDTO
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let plays: [SDAPlayDTO]
    let mlbBatters: [MLBBatterStat]?
    let mlbPitchers: [MLBPitcherStat]?
    let nhlSkaters: [NHLPlayerStat]?
    let nhlGoalies: [NHLPlayerStat]?
}

struct SDAGameDTO: Decodable, Identifiable, Hashable {
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
    let score: SDAScoreDTO?
    let homeScore: Int?
    let awayScore: Int?
    let isLiveFlag: Bool?
    let isFinalFlag: Bool?
    let presentation: SDAMobilePresentationDTO?
    let eligibility: SDAGameEligibilityDTO?
    let scoreboard: SDAScoreboardDTO?

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
        case presentation
        case eligibility
        case scoreboard
    }
}

struct SDAPlayDTO: Decodable, Identifiable, Hashable {
    var id: String { eventId ?? "\(playIndex)-\(periodLabel)-\(clockLabel ?? gameClock ?? "")" }
    let eventId: String?
    let playIndex: Int
    let quarter: Int?
    let gameClock: String?
    let playType: String?
    let displayType: String
    let teamAbbreviation: String?
    let playerName: String?
    let description: String?
    let homeScore: Int?
    let awayScore: Int?
    let score: SDAScoreDTO?
    let periodLabel: String
    let clockLabel: String?
    let timeLabel: String?
    let tier: Int?
    let scoreChanged: Bool?
    let scoreDisplay: String?
    let presentation: SDAMobilePresentationDTO?
    let importance: SDAEventImportanceDTO
    let rawFeedText: String?
    let rawFeedSource: String?
    let rawFeedUpdatedAt: String?
    let rawDescription: String?
    let modeEligibility: SDAEventModeEligibilityDTO
    let belongsToModes: SDAEventModeEligibilityDTO?
    let scoreBefore: SDAScoreSnapshotDTO?
    let scoreAfter: SDAScoreSnapshotDTO?
    let scoreDelta: SDAScoreDeltaDTO?
    let scoreboard: SDAEventScoreboardDTO?
    let sportMetadata: [String: JSONValue]?
    let metadata: [String: JSONValue]?
}

struct TeamStat: Codable, Identifiable, Hashable {
    var id: String { "\(team)-\(isHome)" }
    let team: String
    let isHome: Bool
    let stats: [String: JSONValue]
    let normalizedStats: [NormalizedStat]?
}

struct NormalizedStat: Codable, Hashable {
    let key: String
    let displayLabel: String
    let group: String?
    let value: JSONValue?
}

struct PlayerStat: Codable, Identifiable, Hashable {
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

struct MLBBatterStat: Codable, Identifiable, Hashable {
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

struct MLBPitcherStat: Codable, Identifiable, Hashable {
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

struct NHLPlayerStat: Codable, Identifiable, Hashable {
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
