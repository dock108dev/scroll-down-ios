import Foundation

struct GameEventSituationSnapshot: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let sport: String
    let display: GameEventSituationDisplay?
    let score: ScoreState?
    let period: GameEventSituationPeriod?
    let clock: GameEventSituationClock?
    let possession: [String: JSONValue]?
    let sportState: GameEventSituationSportState?
    let pressure: GameEventSituationPressure?
    let confidence: GameEventSituationConfidence?

    var normalizedSport: String {
        sport
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    var hasRenderableConfidence: Bool {
        guard let level = confidence?.normalizedLevel else { return false }
        return ["verified", "derived", "partial"].contains(level)
    }

    var hasTypedBaseballDiagramConfidence: Bool {
        guard let level = confidence?.normalizedLevel else { return false }
        return ["verified", "derived"].contains(level)
    }
}

struct GameEventSituationDisplay: Codable, Hashable, Sendable {
    let headline: String?
    let subheadline: String?
    let tokens: [String]
    let accessibilityLabel: String?
}

struct GameEventSituationPeriod: Codable, Hashable, Sendable {
    let ordinal: Int?
    let label: String?
    let phase: String?
}

struct GameEventSituationClock: Codable, Hashable, Sendable {
    let label: String?
    let secondsRemaining: Double?
}

struct GameEventSituationPressure: Codable, Hashable, Sendable {
    let level: String?
    let rank: Int?
    let winProbability: Double?
    let leverageIndex: Double?
}

struct GameEventSituationConfidence: Codable, Hashable, Sendable {
    let level: String?
    let source: String?
    let reasons: [String]

    var normalizedLevel: String? {
        level?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .nilIfBlank
    }
}

struct GameEventSituationSportState: Codable, Hashable, Sendable {
    let baseball: GameEventBaseballSituation?
    let football: [String: JSONValue]?
    let hockey: [String: JSONValue]?
    let basketball: [String: JSONValue]?
    let soccer: [String: JSONValue]?
    let golf: [String: JSONValue]?
    let tennis: [String: JSONValue]?
}

struct GameEventBaseballSituation: Codable, Hashable, Sendable {
    let inning: Int?
    let half: String?
    let outs: Int?
    let balls: Int?
    let strikes: Int?
    let bases: GameEventBaseballBases?
    let baseState: String?
    let battingTeamAbbreviation: String?
    let fieldingTeamAbbreviation: String?
    let batterName: String?
    let pitcherName: String?
}

struct GameEventBaseballBases: Codable, Hashable, Sendable {
    let first: Bool?
    let second: Bool?
    let third: Bool?
}
