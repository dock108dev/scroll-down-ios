import Foundation

struct SDAScoreDTO: Decodable, Hashable, Sendable {
    let home: Int?
    let away: Int?
}

struct SDAGameListResponseDTO: Decodable, Sendable {
    let games: [SDAGameSummaryDTO]
    let total: Int?
    let lastUpdatedAt: String?
}

struct SDAGameListPage: Sendable {
    let games: [Game]
    let total: Int?
    let returnedCount: Int
}

struct SDAGameSummaryDTO: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let leagueCode: String
    let gameDate: Date
    let localGameDate: String?
    let status: String
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int?
    let awayTeamId: Int?
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let currentPeriod: Int?
    let currentPeriodLabel: String?
    let gameClock: String?
    let score: SDAScoreDTO?
    let hasPbp: Bool?
    let playCount: Int?
    let presentation: SDAMobilePresentationDTO?
    let eligibility: SDAGameEligibilityDTO?
    let scoreboard: SDAScoreboardDTO?
}

struct SDAGameDetailResponseDTO: Decodable, Sendable {
    let detailContractVersion: Int
    let situationContract: SDASituationContractDTO?
    let game: SDAGameDTO
    let teamStats: [TeamStat]
    let playerStats: [PlayerStat]
    let plays: [SDAPlayDTO]
    let mlbBatters: [MLBBatterStat]?
    let mlbPitchers: [MLBPitcherStat]?
    let nhlSkaters: [NHLPlayerStat]?
    let nhlGoalies: [NHLPlayerStat]?
}

struct SDACardFeedResponseDTO: Decodable, Sendable {
    let contractVersion: Int
    let game: SDACardFeedGameDTO
    let spoilerPolicy: String
    let generation: SDAFeedGenerationDTO
    let reveal: SDARevealAvailabilityDTO
    let cards: [SDANarrativeCardDTO]
}

struct SDACardFeedGameDTO: Decodable, Hashable, Sendable {
    let gameId: Int
    let sport: String
    let league: String
    let status: String?
    let homeTeam: String?
    let awayTeam: String?
    let homeTeamId: Int?
    let awayTeamId: Int?
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
}

struct SDAFeedGenerationDTO: Decodable, Hashable, Sendable {
    let status: String
    let cardCount: Int
    let lastPlayIndex: Int?
    let generatedAt: String?
    let isStale: Bool
    let validationIssues: [String]
}

struct SDARevealAvailabilityDTO: Decodable, Hashable, Sendable {
    let available: Bool
    let status: String
    let scoresInCards: Bool
    let revealRequiredForScores: Bool
}

struct SDANarrativeCardDTO: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let gameId: Int
    let sourcePlayId: String
    let playIndex: Int
    let sport: String
    let league: String
    let tier: Int
    let contentDepth: String
    let modeEligibility: SDAEventModeEligibilityDTO
    let importance: SDAEventImportanceDTO
    let visualImportance: String
    let period: SDACardPeriodDTO
    let displayTime: String?
    let clock: String?
    let team: SDACardTeamDTO
    let scoreBefore: SDAScoreSnapshotDTO?
    let scoreChange: SDACardScoreChangeDTO?
    let scoreAfter: SDAScoreSnapshotDTO?
    let situation: SDACardSituationDTO
    let leadIn: String
    let stageSetting: String
    let headline: String
    let description: String
    let impact: String?
    let tags: [String]
    let spoilerLevel: String
}

struct SDACardPeriodDTO: Decodable, Hashable, Sendable {
    let ordinal: Int?
    let label: String?
    let type: String?
}

struct SDACardTeamDTO: Decodable, Hashable, Sendable {
    let abbreviation: String?
    let name: String?
    let side: String
}

struct SDACardScoreChangeDTO: Decodable, Hashable, Sendable {
    let home: Int
    let away: Int
}

struct SDACardSituationDTO: Decodable, Hashable, Sendable {
    let summary: String?
    let raw: [String: JSONValue]?
}

struct SDAGameDTO: Decodable, Identifiable, Hashable, Sendable {
    let id: Int
    let leagueCode: String
    let gameDate: Date
    let localGameDate: String?
    let status: String
    let homeTeam: String
    let awayTeam: String
    let homeTeamId: Int?
    let awayTeamId: Int?
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let currentPeriod: Int?
    let currentPeriodLabel: String?
    let gameClock: String?
    let score: SDAScoreDTO?
    let presentation: SDAMobilePresentationDTO?
    let eligibility: SDAGameEligibilityDTO?
    let scoreboard: SDAScoreboardDTO?
}

struct SDAPlayDTO: Decodable, Identifiable, Hashable, Sendable {
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
    let score: SDAScoreDTO?
    let periodLabel: String
    let clockLabel: String?
    let timeLabel: String?
    let tier: Int?
    let scoreDisplay: String?
    let presentation: SDAMobilePresentationDTO?
    let card: SDANormalizedPlayCardDTO?
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
    let situationBefore: SDAEventSituationDTO?
    let situationAfter: SDAEventSituationDTO?
    let sportMetadata: [String: JSONValue]?
    let metadata: [String: JSONValue]?
}

struct SDASituationContractDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int
    let supportsSituationBefore: Bool
    let supportsSituationAfter: Bool?
    let supportedSports: [String]?
    let minimumDetailContractVersion: Int?
    let generatedAt: String?
}

struct SDAEventSituationDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int
    let sport: String
    let display: SDASituationDisplayDTO?
    let score: SDAScoreSnapshotDTO?
    let period: SDASituationPeriodDTO?
    let clock: SDASituationClockDTO?
    let possession: [String: JSONValue]?
    let sportState: SDASituationSportStateDTO?
    let pressure: SDASituationPressureDTO?
    let confidence: SDASituationConfidenceDTO?
}

struct SDASituationDisplayDTO: Decodable, Hashable, Sendable {
    let headline: String?
    let subheadline: String?
    let tokens: [String]?
    let accessibilityLabel: String?
}

struct SDASituationPeriodDTO: Decodable, Hashable, Sendable {
    let ordinal: Int?
    let label: String?
    let phase: String?
}

struct SDASituationClockDTO: Decodable, Hashable, Sendable {
    let label: String?
    let secondsRemaining: Double?
}

struct SDASituationPressureDTO: Decodable, Hashable, Sendable {
    let level: String?
    let rank: Int?
    let winProbability: Double?
    let leverageIndex: Double?
}

struct SDASituationConfidenceDTO: Decodable, Hashable, Sendable {
    let level: String?
    let source: String?
    let reasons: [String]?
}

struct SDASituationSportStateDTO: Decodable, Hashable, Sendable {
    let baseball: SDABaseballSituationDTO?
    let football: [String: JSONValue]?
    let hockey: [String: JSONValue]?
    let basketball: [String: JSONValue]?
    let soccer: [String: JSONValue]?
    let golf: [String: JSONValue]?
    let tennis: [String: JSONValue]?
}

struct SDABaseballSituationDTO: Decodable, Hashable, Sendable {
    let inning: Int?
    let half: String?
    let outs: Int?
    let balls: Int?
    let strikes: Int?
    let bases: SDABasesOccupiedDTO?
    let baseState: String?
    let battingTeamAbbreviation: String?
    let fieldingTeamAbbreviation: String?
    let batterName: String?
    let pitcherName: String?
}

struct SDABasesOccupiedDTO: Decodable, Hashable, Sendable {
    let first: Bool?
    let second: Bool?
    let third: Bool?
}

struct TeamStat: Codable, Identifiable, Hashable, Sendable {
    var id: String { "\(team)-\(isHome)" }
    let team: String
    let isHome: Bool
    let stats: [String: JSONValue]
    let normalizedStats: [NormalizedStat]?
}

struct NormalizedStat: Codable, Hashable, Sendable {
    let key: String
    let displayLabel: String
    let group: String?
    let value: JSONValue?
}

struct PlayerStat: Codable, Identifiable, Hashable, Sendable {
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

struct MLBBatterStat: Codable, Identifiable, Hashable, Sendable {
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

struct MLBPitcherStat: Codable, Identifiable, Hashable, Sendable {
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

struct NHLPlayerStat: Codable, Identifiable, Hashable, Sendable {
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
