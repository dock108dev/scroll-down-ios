//
//  SimulatorAPIModels.swift
//  ScrollDown
//
//  Codable types for the MLB Monte Carlo simulator API.
//

import Foundation

// MARK: - Teams

struct MLBTeamsResponse: Codable {
    let teams: [SimulatorTeam]
    let count: Int
}

struct SimulatorTeam: Codable, Identifiable, Hashable {
    let id: Int
    let abbreviation: String
    let name: String
    let shortName: String
    let gamesWithStats: Int

    enum CodingKeys: String, CodingKey {
        case id, abbreviation, name
        case shortName = "short_name"
        case gamesWithStats = "games_with_stats"
    }
}

// MARK: - Roster

struct MLBRosterResponse: Codable {
    let batters: [RosterBatter]
    let pitchers: [RosterPitcher]
}

struct RosterBatter: Codable, Identifiable, Hashable {
    let externalRef: String
    let name: String
    let gamesPlayed: Int

    var id: String { externalRef }

    enum CodingKeys: String, CodingKey {
        case externalRef = "external_ref"
        case name
        case gamesPlayed = "games_played"
    }
}

struct RosterPitcher: Codable, Identifiable, Hashable {
    let externalRef: String
    let name: String
    let games: Int
    let avgIp: Double

    var id: String { externalRef }

    enum CodingKeys: String, CodingKey {
        case externalRef = "external_ref"
        case name, games
        case avgIp = "avg_ip"
    }
}

// MARK: - Simulation Request

struct SimulationRequest: Codable {
    let sport: String
    let homeTeam: String
    let awayTeam: String
    let iterations: Int?
    let probabilityMode: String?
    let homeLineup: [LineupSlot]?
    let awayLineup: [LineupSlot]?
    let homeStarter: PitcherSlot?
    let awayStarter: PitcherSlot?
    let starterInnings: Int?
    let excludePlayoffs: Bool?

    enum CodingKeys: String, CodingKey {
        case sport
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case iterations
        case probabilityMode = "probability_mode"
        case homeLineup = "home_lineup"
        case awayLineup = "away_lineup"
        case homeStarter = "home_starter"
        case awayStarter = "away_starter"
        case starterInnings = "starter_innings"
        case excludePlayoffs = "exclude_playoffs"
    }
}

struct LineupSlot: Codable, Identifiable, Hashable {
    let externalRef: String
    let name: String

    var id: String { externalRef }

    enum CodingKeys: String, CodingKey {
        case externalRef = "external_ref"
        case name
    }
}

struct PitcherSlot: Codable, Hashable {
    let externalRef: String
    let name: String
    let avgIp: Double?

    enum CodingKeys: String, CodingKey {
        case externalRef = "external_ref"
        case name
        case avgIp = "avg_ip"
    }
}

// MARK: - Simulation Result

struct SimulatorResult: Codable {
    let sport: String
    let homeTeam: String
    let awayTeam: String
    let homeWinProbability: Double
    let awayWinProbability: Double
    let averageHomeScore: Double
    let averageAwayScore: Double
    let averageTotal: Double
    let medianTotal: Double
    let mostCommonScores: [MostCommonScore]
    let iterations: Int
    let probabilitySource: String?
    let profileMeta: ProfileMeta?
    let homePaProbabilities: [String: Double]?
    let awayPaProbabilities: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case sport
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeWinProbability = "home_win_probability"
        case awayWinProbability = "away_win_probability"
        case averageHomeScore = "average_home_score"
        case averageAwayScore = "average_away_score"
        case averageTotal = "average_total"
        case medianTotal = "median_total"
        case mostCommonScores = "most_common_scores"
        case iterations
        case probabilitySource = "probability_source"
        case profileMeta = "profile_meta"
        case homePaProbabilities = "home_pa_probabilities"
        case awayPaProbabilities = "away_pa_probabilities"
    }
}

struct MostCommonScore: Codable, Identifiable {
    let score: String
    let probability: Double

    var id: String { score }

    /// Parse "3-2" into (away, home) tuple
    var parsed: (away: Int, home: Int)? {
        let parts = score.split(separator: "-")
        guard parts.count == 2,
              let a = Int(parts[0]),
              let h = Int(parts[1]) else { return nil }
        return (a, h)
    }
}

struct ProfileMeta: Codable {
    let hasProfiles: Bool?
    let modelWinProbability: Double?
    let lineupMode: LineupModeInfo?
    let homePitcher: PitcherProfileInfo?
    let awayPitcher: PitcherProfileInfo?
    let homeBullpen: [String: Double]?
    let awayBullpen: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case hasProfiles = "has_profiles"
        case modelWinProbability = "model_win_probability"
        case lineupMode = "lineup_mode"
        case homePitcher = "home_pitcher"
        case awayPitcher = "away_pitcher"
        case homeBullpen = "home_bullpen"
        case awayBullpen = "away_bullpen"
    }
}

struct LineupModeInfo: Codable {
    let enabled: Bool
    let homeBattersResolved: Int
    let awayBattersResolved: Int
    let homeStarterResolved: Bool
    let awayStarterResolved: Bool
    let starterInnings: Int

    enum CodingKeys: String, CodingKey {
        case enabled
        case homeBattersResolved = "home_batters_resolved"
        case awayBattersResolved = "away_batters_resolved"
        case homeStarterResolved = "home_starter_resolved"
        case awayStarterResolved = "away_starter_resolved"
        case starterInnings = "starter_innings"
    }
}

struct PitcherProfileInfo: Codable {
    let name: String?
    let avgIp: Double?
    let rawProfile: [String: Double]?
    let adjustedProfile: [String: Double]?
    let isRegressed: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case avgIp = "avg_ip"
        case rawProfile = "raw_profile"
        case adjustedProfile = "adjusted_profile"
        case isRegressed = "is_regressed"
    }
}
