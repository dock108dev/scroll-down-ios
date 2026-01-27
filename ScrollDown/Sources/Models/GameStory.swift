import Foundation

// MARK: - Story Moment

/// A narrative moment grouping related plays in the story
struct StoryMoment: Codable, Identifiable, Equatable {
    let playIds: [Int]
    let explicitlyNarratedPlayIds: [Int]
    let period: Int
    let startClock: String?
    let endClock: String?
    let scoreBefore: [Int]  // [away, home]
    let scoreAfter: [Int]   // [away, home]
    let narrative: String

    var id: String { "\(period)-\(startClock ?? "0")" }

    var startScore: ScoreSnapshot {
        ScoreSnapshot(
            home: scoreBefore.count > 1 ? scoreBefore[1] : 0,
            away: scoreBefore.first ?? 0
        )
    }

    var endScore: ScoreSnapshot {
        ScoreSnapshot(
            home: scoreAfter.count > 1 ? scoreAfter[1] : 0,
            away: scoreAfter.first ?? 0
        )
    }

    enum CodingKeys: String, CodingKey {
        case playIds = "play_ids"
        case explicitlyNarratedPlayIds = "explicitly_narrated_play_ids"
        case period
        case startClock = "start_clock"
        case endClock = "end_clock"
        case scoreBefore = "score_before"
        case scoreAfter = "score_after"
        case narrative
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playIds = try container.decodeIfPresent([Int].self, forKey: .playIds) ?? []
        explicitlyNarratedPlayIds = try container.decodeIfPresent([Int].self, forKey: .explicitlyNarratedPlayIds) ?? []
        period = try container.decode(Int.self, forKey: .period)
        startClock = try container.decodeIfPresent(String.self, forKey: .startClock)
        endClock = try container.decodeIfPresent(String.self, forKey: .endClock)
        scoreBefore = try container.decodeIfPresent([Int].self, forKey: .scoreBefore) ?? [0, 0]
        scoreAfter = try container.decodeIfPresent([Int].self, forKey: .scoreAfter) ?? [0, 0]
        narrative = try container.decode(String.self, forKey: .narrative)
    }

    init(
        playIds: [Int],
        explicitlyNarratedPlayIds: [Int],
        period: Int,
        startClock: String?,
        endClock: String?,
        scoreBefore: [Int],
        scoreAfter: [Int],
        narrative: String
    ) {
        self.playIds = playIds
        self.explicitlyNarratedPlayIds = explicitlyNarratedPlayIds
        self.period = period
        self.startClock = startClock
        self.endClock = endClock
        self.scoreBefore = scoreBefore
        self.scoreAfter = scoreAfter
        self.narrative = narrative
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
    let homeScore: Int?
    let awayScore: Int?

    var id: Int { playId }

    enum CodingKeys: String, CodingKey {
        case playId = "play_id"
        case playIndex = "play_index"
        case period
        case clock
        case playType = "play_type"
        case description
        case homeScore = "home_score"
        case awayScore = "away_score"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playId = try container.decode(Int.self, forKey: .playId)
        playIndex = try container.decode(Int.self, forKey: .playIndex)
        period = try container.decode(Int.self, forKey: .period)
        clock = try container.decodeIfPresent(String.self, forKey: .clock)
        playType = try container.decodeIfPresent(String.self, forKey: .playType)
        description = try container.decodeIfPresent(String.self, forKey: .description)
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
        homeScore: Int?,
        awayScore: Int?
    ) {
        self.playId = playId
        self.playIndex = playIndex
        self.period = period
        self.clock = clock
        self.playType = playType
        self.description = description
        self.homeScore = homeScore
        self.awayScore = awayScore
    }
}

// MARK: - Story Content

/// Wrapper for story moments
struct StoryContent: Codable, Equatable {
    let moments: [StoryMoment]

    init(moments: [StoryMoment]) {
        self.moments = moments
    }
}

// MARK: - Game Story Response

/// Response from the story endpoint with moments and plays
struct GameStoryResponse: Codable {
    let gameId: Int
    let story: StoryContent
    let plays: [StoryPlay]
    let validationPassed: Bool
    let validationErrors: [String]

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case story
        case plays
        case validationPassed = "validation_passed"
        case validationErrors = "validation_errors"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameId = try container.decode(Int.self, forKey: .gameId)
        story = try container.decode(StoryContent.self, forKey: .story)
        plays = try container.decodeIfPresent([StoryPlay].self, forKey: .plays) ?? []
        validationPassed = try container.decodeIfPresent(Bool.self, forKey: .validationPassed) ?? true
        validationErrors = try container.decodeIfPresent([String].self, forKey: .validationErrors) ?? []
    }

    init(
        gameId: Int,
        story: StoryContent,
        plays: [StoryPlay],
        validationPassed: Bool = true,
        validationErrors: [String] = []
    ) {
        self.gameId = gameId
        self.story = story
        self.plays = plays
        self.validationPassed = validationPassed
        self.validationErrors = validationErrors
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
