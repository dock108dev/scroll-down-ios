import Foundation

/// Detailed play-by-play event
///
/// REVEAL PHILOSOPHY:
/// - homeScore and awayScore are present in the model but NOT displayed by default
/// - The backend provides reveal-aware descriptions that don't leak outcomes
/// - Future phases will add reveal toggles; this phase prepares for that
/// - Timeline rendering must remain spoiler-safe by default
struct PbpEvent: Codable, Identifiable, Equatable {
    let id: StringOrInt
    let gameId: StringOrInt?
    let period: Int?
    let gameClock: String?
    let elapsedSeconds: Double?
    let eventType: String?
    let description: String?
    let team: String?
    let teamId: String?
    let playerName: String?
    let playerId: StringOrInt?
    let homeScore: Int?
    let awayScore: Int?

    init(
        id: StringOrInt,
        gameId: StringOrInt? = nil,
        period: Int? = nil,
        gameClock: String? = nil,
        elapsedSeconds: Double? = nil,
        eventType: String? = nil,
        description: String? = nil,
        team: String? = nil,
        teamId: String? = nil,
        playerName: String? = nil,
        playerId: StringOrInt? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil
    ) {
        self.id = id
        self.gameId = gameId
        self.period = period
        self.gameClock = gameClock
        self.elapsedSeconds = elapsedSeconds
        self.eventType = eventType
        self.description = description
        self.team = team
        self.teamId = teamId
        self.playerName = playerName
        self.playerId = playerId
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

/// PBP response — expects flat events array from API
struct PbpResponse: Codable {
    let events: [PbpEvent]

    init(events: [PbpEvent]) {
        self.events = events
    }
}

// MARK: - StringOrInt for flexible ID types
/// Handles fields that can be either string or integer in the API
enum StringOrInt: Codable, Hashable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(
                StringOrInt.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or Int"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }

    /// Get value as String regardless of underlying type
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        }
    }

    /// Get value as Int if possible
    var intValue: Int? {
        switch self {
        case .string(let value):
            return Int(value)
        case .int(let value):
            return value
        }
    }
}

// MARK: - Player Name Extraction

extension PbpEvent {
    /// Extracts player name from the event
    /// Returns explicit playerName if available, otherwise attempts to parse from description
    var effectivePlayerName: String? {
        if let name = playerName, !name.isEmpty {
            return name
        }
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }

    /// Attempts to extract a player name from a play description
    static func extractPlayerName(from description: String) -> String? {
        // Pattern 1: Name at start (most common): "J. Smith makes..."
        let startPattern = #"^([A-Z]\.\s*[A-Za-z'-]+|[A-Z][a-z]+\s+[A-Za-z'-]+)"#
        if let match = description.range(of: startPattern, options: .regularExpression) {
            return String(description[match]).trimmingCharacters(in: .whitespaces)
        }

        // Pattern 2: "Turnover by Name" or "Foul on Name"
        let byPattern = #"(?:by|on)\s+([A-Z]\.\s*[A-Za-z'-]+|[A-Z][a-z]+\s+[A-Za-z'-]+)"#
        if let regex = try? NSRegularExpression(pattern: byPattern, options: []),
           let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)),
           let range = Range(match.range(at: 1), in: description) {
            return String(description[range]).trimmingCharacters(in: .whitespaces)
        }

        return nil
    }
}

extension PlayEntry {
    /// Extracts player name from the entry
    var effectivePlayerName: String? {
        if let name = playerName, !name.isEmpty {
            return name
        }
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }
}

extension FlowPlay {
    /// Extracts player name from the play
    var effectivePlayerName: String? {
        if let name = playerName, !name.isEmpty {
            return name
        }
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }
}
