import Foundation

// MARK: - V2 API Types (Moments-Based)

/// Story moment from the V2 API - replaces chapters/sections with play-grouped moments
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

    /// Convert to existing ScoreSnapshot format (start of moment)
    var startScore: ScoreSnapshot {
        ScoreSnapshot(
            home: scoreBefore.count > 1 ? scoreBefore[1] : 0,
            away: scoreBefore.first ?? 0
        )
    }

    /// Convert to existing ScoreSnapshot format (end of moment)
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

/// Story play from the V2 API - individual play details
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

/// Nested wrapper for story content in V2 response
struct StoryContent: Codable, Equatable {
    let moments: [StoryMoment]

    init(moments: [StoryMoment]) {
        self.moments = moments
    }
}

/// V2 story response with moments-based structure
struct GameStoryResponseV2: Codable {
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

// MARK: - Game Story Response

/// Response from the /api/games/{id}/story endpoint
/// App endpoint returns a simplified response (no chapters, metadata)
/// Admin endpoint returns full response with chapters
struct GameStoryResponse: Codable {
    let gameId: Int
    let sport: String
    let storyVersion: String

    // Chapter data (admin endpoint only - not returned by app endpoint)
    let chapters: [ChapterEntry]
    let chapterCount: Int
    let totalPlays: Int

    // Section data (narrative units - 3-10 per game)
    let sections: [SectionEntry]
    let sectionCount: Int

    // AI-generated narrative content
    let compactStory: String?
    let wordCount: Int?
    let targetWordCount: Int?
    let quality: StoryQuality?
    let readingTimeEstimateMinutes: Double?

    // Metadata
    let generatedAt: String?
    /// App endpoint uses `has_story`, admin uses `has_compact_story`
    let hasStory: Bool
    /// Admin endpoint only
    let hasCompactStory: Bool
    let metadata: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case sport
        case storyVersion = "story_version"
        case chapters
        case chapterCount = "chapter_count"
        case totalPlays = "total_plays"
        case sections
        case sectionCount = "section_count"
        case compactStory = "compact_story"
        case wordCount = "word_count"
        case targetWordCount = "target_word_count"
        case quality
        case readingTimeEstimateMinutes = "reading_time_estimate_minutes"
        case generatedAt = "generated_at"
        case hasStory = "has_story"
        case hasCompactStory = "has_compact_story"
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameId = try container.decode(Int.self, forKey: .gameId)
        sport = try container.decode(String.self, forKey: .sport)
        storyVersion = try container.decodeIfPresent(String.self, forKey: .storyVersion) ?? "2.0.0"
        // Chapters only from admin endpoint
        chapters = try container.decodeIfPresent([ChapterEntry].self, forKey: .chapters) ?? []
        chapterCount = try container.decodeIfPresent(Int.self, forKey: .chapterCount) ?? chapters.count
        totalPlays = try container.decodeIfPresent(Int.self, forKey: .totalPlays) ?? 0
        sections = try container.decodeIfPresent([SectionEntry].self, forKey: .sections) ?? []
        sectionCount = try container.decodeIfPresent(Int.self, forKey: .sectionCount) ?? sections.count
        compactStory = try container.decodeIfPresent(String.self, forKey: .compactStory)
        wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount)
        targetWordCount = try container.decodeIfPresent(Int.self, forKey: .targetWordCount)
        quality = try container.decodeIfPresent(StoryQuality.self, forKey: .quality)
        readingTimeEstimateMinutes = try container.decodeIfPresent(Double.self, forKey: .readingTimeEstimateMinutes)
        generatedAt = try container.decodeIfPresent(String.self, forKey: .generatedAt)
        // App endpoint: has_story, Admin endpoint: has_compact_story
        let hasStoryValue = try container.decodeIfPresent(Bool.self, forKey: .hasStory)
        let hasCompactStoryValue = try container.decodeIfPresent(Bool.self, forKey: .hasCompactStory)
        hasStory = hasStoryValue ?? hasCompactStoryValue ?? (compactStory != nil)
        hasCompactStory = hasCompactStoryValue ?? hasStoryValue ?? (compactStory != nil)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
    }

    /// Memberwise init for previews and tests
    init(
        gameId: Int,
        sport: String,
        storyVersion: String = "2.0.0",
        chapters: [ChapterEntry] = [],
        chapterCount: Int = 0,
        totalPlays: Int = 0,
        sections: [SectionEntry] = [],
        sectionCount: Int = 0,
        compactStory: String? = nil,
        wordCount: Int? = nil,
        targetWordCount: Int? = nil,
        quality: StoryQuality? = nil,
        readingTimeEstimateMinutes: Double? = nil,
        generatedAt: String? = nil,
        hasStory: Bool = false,
        hasCompactStory: Bool = false,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.gameId = gameId
        self.sport = sport
        self.storyVersion = storyVersion
        self.chapters = chapters
        self.chapterCount = chapterCount
        self.totalPlays = totalPlays
        self.sections = sections
        self.sectionCount = sectionCount
        self.compactStory = compactStory
        self.wordCount = wordCount
        self.targetWordCount = targetWordCount
        self.quality = quality
        self.readingTimeEstimateMinutes = readingTimeEstimateMinutes
        self.generatedAt = generatedAt
        self.hasStory = hasStory
        self.hasCompactStory = hasCompactStory
        self.metadata = metadata
    }
}

// MARK: - Chapter Entry

/// Structural division of the game - deterministic, contiguous play ranges
/// Chapters are time-based boundaries (periods, timeouts, reviews)
struct ChapterEntry: Codable, Identifiable, Equatable {
    let chapterId: String
    let index: Int
    let playStartIdx: Int
    let playEndIdx: Int
    let playCount: Int
    let reasonCodes: [String]
    let period: Int?
    let timeRange: TimeRange?
    let plays: [PlayEntry]

    var id: String { chapterId }

    enum CodingKeys: String, CodingKey {
        case chapterId = "chapter_id"
        case index
        case playStartIdx = "play_start_idx"
        case playEndIdx = "play_end_idx"
        case playCount = "play_count"
        case reasonCodes = "reason_codes"
        case period
        case timeRange = "time_range"
        case plays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decode(String.self, forKey: .chapterId)
        index = try container.decode(Int.self, forKey: .index)
        playStartIdx = try container.decodeIfPresent(Int.self, forKey: .playStartIdx) ?? 0
        playEndIdx = try container.decodeIfPresent(Int.self, forKey: .playEndIdx) ?? 0
        playCount = try container.decodeIfPresent(Int.self, forKey: .playCount) ?? 0
        reasonCodes = try container.decodeIfPresent([String].self, forKey: .reasonCodes) ?? []
        period = try container.decodeIfPresent(Int.self, forKey: .period)
        timeRange = try container.decodeIfPresent(TimeRange.self, forKey: .timeRange)
        plays = try container.decodeIfPresent([PlayEntry].self, forKey: .plays) ?? []
    }

    init(
        chapterId: String,
        index: Int,
        playStartIdx: Int = 0,
        playEndIdx: Int = 0,
        playCount: Int = 0,
        reasonCodes: [String] = [],
        period: Int? = nil,
        timeRange: TimeRange? = nil,
        plays: [PlayEntry] = []
    ) {
        self.chapterId = chapterId
        self.index = index
        self.playStartIdx = playStartIdx
        self.playEndIdx = playEndIdx
        self.playCount = playCount
        self.reasonCodes = reasonCodes
        self.period = period
        self.timeRange = timeRange
        self.plays = plays
    }

    /// Human-readable description of chapter boundaries
    var boundaryDescription: String {
        reasonCodes.map { reasonCodeDisplayName($0) }.joined(separator: ", ")
    }

    private func reasonCodeDisplayName(_ code: String) -> String {
        switch code {
        case "period_start": return "Period start"
        case "period_end": return "Period end"
        case "timeout": return "Timeout"
        case "review": return "Official review"
        case "run_boundary": return "Scoring run"
        case "overtime_start": return "Overtime"
        case "game_end": return "Game end"
        default: return code.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Section Entry

/// Narrative unit - collapsed chapters with beat types
/// Sections are the primary UI element for story display (3-10 per game)
struct SectionEntry: Codable, Identifiable, Equatable {
    let sectionIndex: Int
    let beatType: BeatType
    let header: String
    /// Admin endpoint only - not returned by app endpoint
    let chaptersIncluded: [String]
    let startScore: ScoreSnapshot
    let endScore: ScoreSnapshot
    let notes: [String]

    var id: Int { sectionIndex }

    enum CodingKeys: String, CodingKey {
        case sectionIndex = "section_index"
        case beatType = "beat_type"
        case header
        case chaptersIncluded = "chapters_included"
        case startScore = "start_score"
        case endScore = "end_score"
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sectionIndex = try container.decode(Int.self, forKey: .sectionIndex)
        beatType = (try? container.decode(BeatType.self, forKey: .beatType)) ?? .backAndForth
        header = try container.decodeIfPresent(String.self, forKey: .header) ?? ""
        // chaptersIncluded only from admin endpoint
        chaptersIncluded = try container.decodeIfPresent([String].self, forKey: .chaptersIncluded) ?? []
        startScore = try container.decode(ScoreSnapshot.self, forKey: .startScore)
        endScore = try container.decode(ScoreSnapshot.self, forKey: .endScore)
        notes = try container.decodeIfPresent([String].self, forKey: .notes) ?? []
    }

    init(
        sectionIndex: Int,
        beatType: BeatType,
        header: String,
        chaptersIncluded: [String] = [],
        startScore: ScoreSnapshot,
        endScore: ScoreSnapshot,
        notes: [String] = []
    ) {
        self.sectionIndex = sectionIndex
        self.beatType = beatType
        self.header = header
        self.chaptersIncluded = chaptersIncluded
        self.startScore = startScore
        self.endScore = endScore
        self.notes = notes
    }

    /// Score delta during this section
    var scoreDelta: Int {
        let startDiff = abs(startScore.home - startScore.away)
        let endDiff = abs(endScore.home - endScore.away)
        return abs(endDiff - startDiff)
    }

    /// Formatted score range string (e.g., "12-15 → 24-22")
    var scoreRangeDisplay: String {
        "\(startScore.away)-\(startScore.home) → \(endScore.away)-\(endScore.home)"
    }

    /// Whether this section is considered a highlight
    var isHighlight: Bool {
        beatType.isHighlight
    }
}

// MARK: - Beat Type

/// Beat type for narrative sections - determines styling and importance
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

    /// Human-readable display name
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

    /// SF Symbol name for the beat type
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

    /// Whether this beat type is considered a highlight moment
    var isHighlight: Bool {
        switch self {
        case .run, .crunchSetup, .closingSequence, .overtime:
            return true
        case .fastStart, .backAndForth, .earlyControl, .response, .stall:
            return false
        }
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

// MARK: - Time Range

/// Clock time range for chapter boundaries
struct TimeRange: Codable, Equatable {
    let start: String
    let end: String

    init(start: String, end: String) {
        self.start = start
        self.end = end
    }

    /// Formatted display string (e.g., "12:00-8:45")
    var displayString: String {
        "\(start)-\(end)"
    }
}

// MARK: - Story Quality

/// Quality level of the game - determines narrative length
enum StoryQuality: String, Codable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"

    /// Target word count for this quality level
    var targetWordCount: Int {
        switch self {
        case .low: return 400
        case .medium: return 700
        case .high: return 1050
        }
    }

    /// Human-readable description
    var displayName: String {
        switch self {
        case .low: return "Standard"
        case .medium: return "Notable"
        case .high: return "Must-Read"
        }
    }
}

