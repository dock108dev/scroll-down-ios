import Foundation

// MARK: - Story Moment

/// A narrative moment grouping related plays in the story
/// Handles both app endpoint (snake_case, score objects) and admin endpoint (camelCase, score arrays)
struct StoryMoment: Identifiable, Equatable, Decodable {
    let period: Int
    let startClock: String?
    let endClock: String?
    let narrative: String
    let playCount: Int?

    // For admin endpoint compatibility
    let playIds: [Int]
    let explicitlyNarratedPlayIds: [Int]

    // Scores stored as ScoreSnapshot
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot

    var id: String { "\(period)-\(startClock ?? "0")" }

    enum CodingKeys: String, CodingKey {
        case period
        case startClock = "start_clock"
        case endClock = "end_clock"
        case narrative
        case playCount = "play_count"
        case playIds
        case explicitlyNarratedPlayIds
        case scoreBefore = "score_before"
        case scoreAfter = "score_after"
        // Admin endpoint uses camelCase arrays
        case scoreBeforeArray = "scoreBefore"
        case scoreAfterArray = "scoreAfter"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        period = try container.decode(Int.self, forKey: .period)
        narrative = try container.decode(String.self, forKey: .narrative)
        playCount = try container.decodeIfPresent(Int.self, forKey: .playCount)

        // Handle both snake_case and camelCase for clock fields
        startClock = try container.decodeIfPresent(String.self, forKey: .startClock)
        endClock = try container.decodeIfPresent(String.self, forKey: .endClock)

        // Admin-only fields (optional)
        playIds = try container.decodeIfPresent([Int].self, forKey: .playIds) ?? []
        explicitlyNarratedPlayIds = try container.decodeIfPresent([Int].self, forKey: .explicitlyNarratedPlayIds) ?? []

        // Handle scores - try object format first (app endpoint), then array format (admin endpoint)
        if let scoreBefore = try? container.decode(ScoreSnapshot.self, forKey: .scoreBefore) {
            startScore = scoreBefore
        } else if let scoreArray = try? container.decode([Int].self, forKey: .scoreBeforeArray) {
            // Admin format: [away, home]
            startScore = ScoreSnapshot(
                home: scoreArray.count > 1 ? scoreArray[1] : 0,
                away: scoreArray.first ?? 0
            )
        } else {
            startScore = ScoreSnapshot(home: 0, away: 0)
        }

        if let scoreAfter = try? container.decode(ScoreSnapshot.self, forKey: .scoreAfter) {
            endScore = scoreAfter
        } else if let scoreArray = try? container.decode([Int].self, forKey: .scoreAfterArray) {
            // Admin format: [away, home]
            endScore = ScoreSnapshot(
                home: scoreArray.count > 1 ? scoreArray[1] : 0,
                away: scoreArray.first ?? 0
            )
        } else {
            endScore = ScoreSnapshot(home: 0, away: 0)
        }
    }

    init(
        period: Int,
        startClock: String?,
        endClock: String?,
        narrative: String,
        playCount: Int? = nil,
        playIds: [Int] = [],
        explicitlyNarratedPlayIds: [Int] = [],
        startScore: ScoreSnapshot,
        endScore: ScoreSnapshot
    ) {
        self.period = period
        self.startClock = startClock
        self.endClock = endClock
        self.narrative = narrative
        self.playCount = playCount
        self.playIds = playIds
        self.explicitlyNarratedPlayIds = explicitlyNarratedPlayIds
        self.startScore = startScore
        self.endScore = endScore
    }

    // Legacy accessors for compatibility
    var scoreBefore: [Int] { [startScore.away, startScore.home] }
    var scoreAfter: [Int] { [endScore.away, endScore.home] }
}

// MARK: - Story Play

/// Individual play details within the story (admin endpoint only)
struct StoryPlay: Codable, Identifiable, Equatable {
    let playId: Int
    let playIndex: Int
    let period: Int
    let clock: String?
    let playType: String?
    let description: String?
    let team: String?
    let playerName: String?
    let homeScore: Int?
    let awayScore: Int?

    var id: Int { playId }

    enum CodingKeys: String, CodingKey {
        case playId
        case playIndex
        case period
        case clock
        case playType
        case description
        case team
        case playerName
        case homeScore
        case awayScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playId = try container.decode(Int.self, forKey: .playId)
        playIndex = try container.decode(Int.self, forKey: .playIndex)
        period = try container.decode(Int.self, forKey: .period)
        clock = try container.decodeIfPresent(String.self, forKey: .clock)
        playType = try container.decodeIfPresent(String.self, forKey: .playType)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        team = try container.decodeIfPresent(String.self, forKey: .team)
        playerName = try container.decodeIfPresent(String.self, forKey: .playerName)
        homeScore = try container.decodeIfPresent(Int.self, forKey: .homeScore)
        awayScore = try container.decodeIfPresent(Int.self, forKey: .awayScore)
    }

    init(
        playId: Int,
        playIndex: Int,
        period: Int,
        clock: String?,
        playType: String?,
        description: String?,
        team: String? = nil,
        playerName: String? = nil,
        homeScore: Int?,
        awayScore: Int?
    ) {
        self.playId = playId
        self.playIndex = playIndex
        self.period = period
        self.clock = clock
        self.playType = playType
        self.description = description
        self.team = team
        self.playerName = playerName
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

// MARK: - Game Story Response

/// Response from the story endpoint
/// Handles both app endpoint (/api/games/{id}/story) and admin endpoint formats
struct GameStoryResponse: Decodable {
    let gameId: Int
    let sport: String?
    let storyVersion: String?
    let moments: [StoryMoment]
    let momentCount: Int?
    let generatedAt: String?
    let hasStory: Bool

    // Admin endpoint fields
    let plays: [StoryPlay]
    let validationPassed: Bool
    let validationErrors: [String]

    // Computed property for StoryContent compatibility
    var story: StoryContent {
        StoryContent(moments: moments)
    }

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case sport
        case storyVersion = "story_version"
        case moments
        case momentCount = "moment_count"
        case generatedAt = "generated_at"
        case hasStory = "has_story"
        case plays
        case validationPassed = "validation_passed"
        case validationErrors = "validation_errors"
        // Admin endpoint nesting
        case story
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        gameId = try container.decode(Int.self, forKey: .gameId)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        storyVersion = try container.decodeIfPresent(String.self, forKey: .storyVersion)
        momentCount = try container.decodeIfPresent(Int.self, forKey: .momentCount)
        generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        hasStory = try container.decodeIfPresent(Bool.self, forKey: .hasStory) ?? true

        // Try direct moments array (app endpoint) first
        if let directMoments = try? container.decode([StoryMoment].self, forKey: .moments) {
            moments = directMoments
        }
        // Fall back to nested story.moments (admin endpoint)
        else if let storyContent = try? container.decode(StoryContent.self, forKey: .story) {
            moments = storyContent.moments
        } else {
            moments = []
        }

        // Admin-only fields
        plays = try container.decodeIfPresent([StoryPlay].self, forKey: .plays) ?? []
        validationPassed = try container.decodeIfPresent(Bool.self, forKey: .validationPassed) ?? true
        validationErrors = try container.decodeIfPresent([String].self, forKey: .validationErrors) ?? []
    }

    init(
        gameId: Int,
        sport: String? = nil,
        storyVersion: String? = nil,
        moments: [StoryMoment],
        momentCount: Int? = nil,
        generatedAt: String? = nil,
        hasStory: Bool = true,
        plays: [StoryPlay] = [],
        validationPassed: Bool = true,
        validationErrors: [String] = []
    ) {
        self.gameId = gameId
        self.sport = sport
        self.storyVersion = storyVersion
        self.moments = moments
        self.momentCount = momentCount
        self.generatedAt = generatedAt
        self.hasStory = hasStory
        self.plays = plays
        self.validationPassed = validationPassed
        self.validationErrors = validationErrors
    }
}

// MARK: - Story Content (for admin endpoint compatibility)

struct StoryContent: Decodable, Equatable {
    let moments: [StoryMoment]

    init(moments: [StoryMoment]) {
        self.moments = moments
    }
}

// MARK: - Score Snapshot

/// Score at a point in time
struct ScoreSnapshot: Codable, Equatable {
    let home: Int
    let away: Int

    init(home: Int, away: Int) {
        self.home = home
        self.away = away
    }
}

// MARK: - Beat Type

/// Beat type for narrative moments - determines styling and importance
enum BeatType: String, Codable, CaseIterable {
    case fastStart = "FAST_START"
    case backAndForth = "BACK_AND_FORTH"
    case earlyControl = "EARLY_CONTROL"
    case run = "RUN"
    case response = "RESPONSE"
    case stall = "STALL"
    case crunchSetup = "CRUNCH_SETUP"
    case closingSequence = "CLOSING_SEQUENCE"
    case overtime = "OVERTIME"

    var displayName: String {
        switch self {
        case .fastStart: return "Fast Start"
        case .backAndForth: return "Back & Forth"
        case .earlyControl: return "Early Control"
        case .run: return "Scoring Run"
        case .response: return "Response"
        case .stall: return "Stall"
        case .crunchSetup: return "Crunch Time"
        case .closingSequence: return "Closing"
        case .overtime: return "Overtime"
        }
    }

    var iconName: String {
        switch self {
        case .fastStart: return "flame.fill"
        case .backAndForth: return "arrow.left.arrow.right"
        case .earlyControl: return "arrow.up.right"
        case .run: return "bolt.fill"
        case .response: return "arrow.turn.up.left"
        case .stall: return "pause.circle"
        case .crunchSetup: return "clock.badge.exclamationmark"
        case .closingSequence: return "checkmark.seal.fill"
        case .overtime: return "clock.arrow.circlepath"
        }
    }

    var isHighlight: Bool {
        switch self {
        case .run, .crunchSetup, .closingSequence, .overtime:
            return true
        case .fastStart, .backAndForth, .earlyControl, .response, .stall:
            return false
        }
    }
}
