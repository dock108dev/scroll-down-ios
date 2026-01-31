import Foundation

// MARK: - Story Moment

/// A narrative moment grouping related plays in the story
struct StoryMoment: Identifiable, Equatable, Decodable {
    let period: Int
    let startClock: String?
    let endClock: String?
    let narrative: String
    let playIds: [Int]
    let explicitlyNarratedPlayIds: [Int]
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot

    var id: String { "\(period)-\(startClock ?? "0")" }

    enum CodingKeys: String, CodingKey {
        case period
        case startClock
        case endClock
        case narrative
        case playIds
        case explicitlyNarratedPlayIds
        case scoreBefore
        case scoreAfter
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        period = try container.decode(Int.self, forKey: .period)
        narrative = try container.decode(String.self, forKey: .narrative)
        startClock = try container.decodeIfPresent(String.self, forKey: .startClock)
        endClock = try container.decodeIfPresent(String.self, forKey: .endClock)
        playIds = try container.decodeIfPresent([Int].self, forKey: .playIds) ?? []
        explicitlyNarratedPlayIds = try container.decodeIfPresent([Int].self, forKey: .explicitlyNarratedPlayIds) ?? []

        // Scores are [away, home] arrays
        if let scoreArray = try container.decodeIfPresent([Int].self, forKey: .scoreBefore) {
            startScore = ScoreSnapshot(
                home: scoreArray.count > 1 ? scoreArray[1] : 0,
                away: scoreArray.first ?? 0
            )
        } else {
            startScore = ScoreSnapshot(home: 0, away: 0)
        }

        if let scoreArray = try container.decodeIfPresent([Int].self, forKey: .scoreAfter) {
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
        playIds: [Int] = [],
        explicitlyNarratedPlayIds: [Int] = [],
        startScore: ScoreSnapshot,
        endScore: ScoreSnapshot
    ) {
        self.period = period
        self.startClock = startClock
        self.endClock = endClock
        self.narrative = narrative
        self.playIds = playIds
        self.explicitlyNarratedPlayIds = explicitlyNarratedPlayIds
        self.startScore = startScore
        self.endScore = endScore
    }
}

// MARK: - Story Play

/// Individual play details within the story
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

    init(
        playId: Int,
        playIndex: Int,
        period: Int,
        clock: String? = nil,
        playType: String? = nil,
        description: String? = nil,
        team: String? = nil,
        playerName: String? = nil,
        homeScore: Int? = nil,
        awayScore: Int? = nil
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
struct GameStoryResponse: Decodable {
    let gameId: Int
    let sport: String?
    let storyVersion: String?
    let moments: [StoryMoment]
    let momentCount: Int?
    let generatedAt: String?
    let hasStory: Bool
    let plays: [StoryPlay]
    let validationPassed: Bool
    let validationErrors: [String]

    var story: StoryContent {
        StoryContent(moments: moments)
    }

    enum CodingKeys: String, CodingKey {
        case gameId
        case sport
        case storyVersion
        case moments
        case momentCount
        case generatedAt
        case hasStory
        case plays
        case validationPassed
        case validationErrors
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

        // Moments can be at top level or nested in story object
        if let directMoments = try? container.decode([StoryMoment].self, forKey: .moments) {
            moments = directMoments
        } else if let storyContent = try? container.decode(StoryContent.self, forKey: .story) {
            moments = storyContent.moments
        } else {
            moments = []
        }

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

// MARK: - Story Content

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
