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
    let gameId: StringOrInt?        // Optional - not in app endpoint
    let period: Int?
    let gameClock: String?
    let elapsedSeconds: Double?
    let eventType: String?          // "event_type" or "play_type"
    let description: String?
    let team: String?
    let teamId: String?
    let playerName: String?         // Often embedded in description instead
    let playerId: StringOrInt?
    let homeScore: Int?             // Present but not displayed by default (reveal-aware)
    let awayScore: Int?             // Present but not displayed by default (reveal-aware)

    enum CodingKeys: String, CodingKey {
        case id
        case index                  // App endpoint uses "index" instead of "id"
        case gameId = "game_id"
        case period
        case gameClock = "game_clock"
        case clock                  // App endpoint uses "clock" instead of "game_clock"
        case elapsedSeconds = "elapsed_seconds"
        case eventType = "event_type"
        case playType = "play_type" // App endpoint uses "play_type" instead of "event_type"
        case description
        case team
        case teamId = "team_id"
        case playerName = "player_name"
        case playerId = "player_id"
        case homeScore = "home_score"
        case awayScore = "away_score"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle id: can be "id" (string/int) or "index" (int)
        if let idValue = try? container.decode(StringOrInt.self, forKey: .id) {
            self.id = idValue
        } else if let indexValue = try? container.decode(Int.self, forKey: .index) {
            self.id = .int(indexValue)
        } else {
            // Generate an ID if neither is present
            self.id = .int(0)
        }

        self.gameId = try container.decodeIfPresent(StringOrInt.self, forKey: .gameId)
        self.period = try container.decodeIfPresent(Int.self, forKey: .period)

        // Handle clock: can be "game_clock" or "clock"
        self.gameClock = try container.decodeIfPresent(String.self, forKey: .gameClock)
            ?? container.decodeIfPresent(String.self, forKey: .clock)

        self.elapsedSeconds = try container.decodeIfPresent(Double.self, forKey: .elapsedSeconds)

        // Handle event type: can be "event_type" or "play_type"
        self.eventType = try container.decodeIfPresent(String.self, forKey: .eventType)
            ?? container.decodeIfPresent(String.self, forKey: .playType)

        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.team = try container.decodeIfPresent(String.self, forKey: .team)
        self.teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        self.playerName = try container.decodeIfPresent(String.self, forKey: .playerName)
        self.playerId = try container.decodeIfPresent(StringOrInt.self, forKey: .playerId)
        self.homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
        self.awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
    }

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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(gameId, forKey: .gameId)
        try container.encodeIfPresent(period, forKey: .period)
        try container.encodeIfPresent(gameClock, forKey: .gameClock)
        try container.encodeIfPresent(elapsedSeconds, forKey: .elapsedSeconds)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(team, forKey: .team)
        try container.encodeIfPresent(teamId, forKey: .teamId)
        try container.encodeIfPresent(playerName, forKey: .playerName)
        try container.encodeIfPresent(playerId, forKey: .playerId)
        try container.encodeIfPresent(homeScore, forKey: .homeScore)
        try container.encodeIfPresent(awayScore, forKey: .awayScore)
    }
}

/// PBP response
struct PbpResponse: Codable {
    let events: [PbpEvent]

    enum CodingKeys: String, CodingKey {
        case events
        case periods
    }

    init(events: [PbpEvent]) {
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Try flat events array first
        if let flatEvents = try? container.decode([PbpEvent].self, forKey: .events) {
            self.events = flatEvents
            return
        }

        // Try periods format: {"periods": [{"period": 1, "events": [...]}]}
        if let periods = try? container.decode([PbpPeriod].self, forKey: .periods) {
            self.events = periods.flatMap { $0.events }
            return
        }

        // Default to empty if neither format works
        self.events = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(events, forKey: .events)
    }
}

/// Period wrapper for grouped PBP format
private struct PbpPeriod: Codable {
    let period: Int
    let events: [PbpEvent]
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
        // Return explicit playerName if available
        if let name = playerName, !name.isEmpty {
            return name
        }

        // Try to extract from description
        // Common formats: "J. Smith makes...", "K. Durant scores...", "Player (team)..."
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }

    /// Attempts to extract a player name from a play description
    /// Handles formats like:
    /// - "K. Durant makes 3-pt shot from 24 ft"
    /// - "J. Tatum rebound"
    /// - "Turnover by L. James"
    static func extractPlayerName(from description: String) -> String? {
        // Pattern 1: Name at start (most common): "J. Smith makes..."
        // Look for: Initial. LastName or First LastName at the beginning
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
    /// Returns explicit playerName if available, otherwise attempts to parse from description
    var effectivePlayerName: String? {
        // Return explicit playerName if available
        if let name = playerName, !name.isEmpty {
            return name
        }

        // Try to extract from description
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }
}

extension StoryPlay {
    /// Extracts player name from the play
    /// Returns explicit playerName if available, otherwise attempts to parse from description
    var effectivePlayerName: String? {
        // Return explicit playerName if available
        if let name = playerName, !name.isEmpty {
            return name
        }

        // Try to extract from description
        guard let desc = description else { return nil }
        return PbpEvent.extractPlayerName(from: desc)
    }
}



