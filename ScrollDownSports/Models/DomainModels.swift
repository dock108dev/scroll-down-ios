import Foundation

enum Sport: Codable, Hashable, Sendable {
    case mlb
    case nfl
    case nba
    case nhl
    case soccer
    case golf
    case tennis
    case other(String)

    init(leagueCode: String) {
        switch leagueCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "mlb":
            self = .mlb
        case "nfl":
            self = .nfl
        case "nba":
            self = .nba
        case "nhl":
            self = .nhl
        case "soccer", "mls", "epl", "premier_league":
            self = .soccer
        case "golf", "pga", "lpga":
            self = .golf
        case "tennis", "atp", "wta":
            self = .tennis
        case let value where !value.isEmpty:
            self = .other(value)
        default:
            self = .other("unknown")
        }
    }
}

struct Game: Codable, Identifiable, Hashable, Sendable {
    typealias ID = Int

    let id: ID
    let sport: Sport
    let leagueCode: String
    let scheduledStart: Date
    let localDateLabel: String?
    let status: GameStatus
    let participants: [GameParticipant]
    let scoreState: ScoreState
    let presentation: GamePresentationData?
    let scoreboard: GameScoreboardData?
    let progress: GameProgress
    let availableFeatures: GameAvailableFeatures

    var homeParticipant: GameParticipant? { participants.first { $0.role == .home } }
    var awayParticipant: GameParticipant? { participants.first { $0.role == .away } }
    var matchupText: String {
        presentation?.matchupLabel ?? "\(awayParticipant?.name ?? "Away") at \(homeParticipant?.name ?? "Home")"
    }
}

struct GameParticipant: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let role: GameParticipantRole
    let name: String
    let abbreviation: String?

    var favoriteTeamID: String? {
        let value = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value != "home", value != "away" else { return nil }
        return value
    }
}

enum GameParticipantRole: Codable, Hashable, Sendable {
    case home
    case away
    case other(String)
}

struct ScoreState: Codable, Hashable, Sendable {
    let participantScores: [ParticipantScore]

    var home: Int? { score(for: .home) }
    var away: Int? { score(for: .away) }
    var hasAnyScore: Bool { participantScores.contains { $0.score != nil } }

    func score(for role: GameParticipantRole) -> Int? {
        participantScores.first { $0.participantRole == role }?.score
    }
}

struct ParticipantScore: Codable, Hashable, Sendable {
    let participantID: String
    let participantRole: GameParticipantRole
    let score: Int?
}

struct ScoreDelta: Codable, Hashable, Sendable {
    let participantID: String?
    let participantRole: GameParticipantRole?
    let before: Int?
    let after: Int?
    let change: Int?
}
