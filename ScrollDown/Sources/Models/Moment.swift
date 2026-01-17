import Foundation

/// Moment representing a segment of the game timeline
/// Moments partition the entire game - every play belongs to exactly one moment
/// Use `isNotable` to filter for highlights
struct Moment: Codable, Identifiable, Equatable {
    let id: String
    let type: MomentType
    let startPlay: Int
    let endPlay: Int
    let playCount: Int
    let teams: [String]
    let primaryTeam: String?  // The team that drove the narrative for this moment
    let players: [PlayerContribution]
    let scoreStart: String
    let scoreEnd: String
    let clock: String
    let isNotable: Bool
    let isPeriodStart: Bool  // True if this moment starts a new period
    let note: String?
    
    // Optional extended fields
    let runInfo: RunInfo?
    let ladderTierBefore: Int?
    let ladderTierAfter: Int?
    let teamInControl: String?  // "home", "away", or null
    let keyPlayIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startPlay = "start_play"
        case endPlay = "end_play"
        case playCount = "play_count"
        case teams
        case primaryTeam = "primary_team"
        case players
        case scoreStart = "score_start"
        case scoreEnd = "score_end"
        case clock
        case isNotable = "is_notable"
        case isPeriodStart = "is_period_start"
        case note
        case runInfo = "run_info"
        case ladderTierBefore = "ladder_tier_before"
        case ladderTierAfter = "ladder_tier_after"
        case teamInControl = "team_in_control"
        case keyPlayIds = "key_play_ids"
    }
    
    // Custom init for decoding with defaults for new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MomentType.self, forKey: .type)
        startPlay = try container.decode(Int.self, forKey: .startPlay)
        endPlay = try container.decode(Int.self, forKey: .endPlay)
        playCount = try container.decode(Int.self, forKey: .playCount)
        teams = try container.decode([String].self, forKey: .teams)
        primaryTeam = try container.decodeIfPresent(String.self, forKey: .primaryTeam)
        players = try container.decode([PlayerContribution].self, forKey: .players)
        scoreStart = try container.decode(String.self, forKey: .scoreStart)
        scoreEnd = try container.decode(String.self, forKey: .scoreEnd)
        clock = try container.decode(String.self, forKey: .clock)
        isNotable = try container.decode(Bool.self, forKey: .isNotable)
        isPeriodStart = try container.decodeIfPresent(Bool.self, forKey: .isPeriodStart) ?? false
        note = try container.decodeIfPresent(String.self, forKey: .note)
        runInfo = try container.decodeIfPresent(RunInfo.self, forKey: .runInfo)
        ladderTierBefore = try container.decodeIfPresent(Int.self, forKey: .ladderTierBefore)
        ladderTierAfter = try container.decodeIfPresent(Int.self, forKey: .ladderTierAfter)
        teamInControl = try container.decodeIfPresent(String.self, forKey: .teamInControl)
        keyPlayIds = try container.decodeIfPresent([Int].self, forKey: .keyPlayIds)
    }
    
    // Memberwise init for previews and tests
    init(
        id: String,
        type: MomentType,
        startPlay: Int,
        endPlay: Int,
        playCount: Int,
        teams: [String],
        primaryTeam: String? = nil,
        players: [PlayerContribution],
        scoreStart: String,
        scoreEnd: String,
        clock: String,
        isNotable: Bool,
        isPeriodStart: Bool = false,
        note: String?,
        runInfo: RunInfo? = nil,
        ladderTierBefore: Int? = nil,
        ladderTierAfter: Int? = nil,
        teamInControl: String? = nil,
        keyPlayIds: [Int]? = nil
    ) {
        self.id = id
        self.type = type
        self.startPlay = startPlay
        self.endPlay = endPlay
        self.playCount = playCount
        self.teams = teams
        self.primaryTeam = primaryTeam
        self.players = players
        self.scoreStart = scoreStart
        self.scoreEnd = scoreEnd
        self.clock = clock
        self.isNotable = isNotable
        self.isPeriodStart = isPeriodStart
        self.note = note
        self.runInfo = runInfo
        self.ladderTierBefore = ladderTierBefore
        self.ladderTierAfter = ladderTierAfter
        self.teamInControl = teamInControl
        self.keyPlayIds = keyPlayIds
    }
    
    /// Parse quarter number from clock string (e.g., "Q1 9:12-7:48" -> 1)
    var quarter: Int? {
        guard clock.hasPrefix("Q"),
              let quarterChar = clock.dropFirst().first,
              let quarter = Int(String(quarterChar)) else {
            return nil
        }
        return quarter
    }
    
    /// Display label for the moment (uses note if available, otherwise type description)
    var displayLabel: String {
        note ?? type.displayName
    }
    
    /// Time range extracted from clock (e.g., "Q1 9:12-7:48" -> "9:12-7:48")
    var timeRange: String? {
        guard let spaceIndex = clock.firstIndex(of: " ") else {
            return nil
        }
        return String(clock[clock.index(after: spaceIndex)...])
    }
    
    // MARK: - Narrative Headline Generation
    
    /// Human-readable narrative headline describing what happened
    /// Uses moment context to generate story-like description
    func narrativeHeadline(homeTeam: String, awayTeam: String) -> String {
        let driver = primaryTeam ?? (teamInControl == "home" ? homeTeam : awayTeam)
        let scoreDelta = parseScoreDelta()
        let isQuickStretch = playCount < 12
        let isLongStretch = playCount > 25
        
        switch type {
        case .flip:
            if isPeriodStart {
                return "\(driver) take an early lead"
            }
            return "\(driver) flip the lead after sustained pressure"
            
        case .leadBuild:
            if let delta = scoreDelta, delta >= 8 {
                return "\(driver) pull away with a \(delta)-point run"
            }
            if isQuickStretch {
                return "\(driver) extend their lead with a quick burst"
            }
            return "\(driver) build on their momentum"
            
        case .cut:
            if let delta = scoreDelta, delta >= 8 {
                return "\(driver) storm back, cutting the deficit"
            }
            if isQuickStretch {
                return "\(driver) respond quickly to trim the lead"
            }
            return "\(driver) chip away at the lead"
            
        case .tie:
            return "Game tied after back-and-forth stretch"
            
        case .closingControl:
            return "\(driver) close it out in the final stretch"
            
        case .highImpact:
            return note ?? "Key moment shifts the momentum"
            
        case .neutral:
            if isPeriodStart && quarter == 1 {
                return "Game underway with early exchanges"
            }
            if isPeriodStart {
                return "Teams trade baskets to open the period"
            }
            if isLongStretch {
                return "Slow, physical stretch keeps the game tight"
            }
            return "Neither team separates during this stretch"
        }
    }
    
    /// Compact metadata line (e.g., "Q1 · 11:46–9:16 · 22 plays")
    var compactMetadata: String {
        let quarterLabel = quarter.map { "Q\($0)" } ?? ""
        let timeLabel = timeRange ?? ""
        let playLabel = "\(playCount) plays"
        
        if !quarterLabel.isEmpty && !timeLabel.isEmpty {
            return "\(quarterLabel) · \(timeLabel) · \(playLabel)"
        } else if !timeLabel.isEmpty {
            return "\(timeLabel) · \(playLabel)"
        }
        return playLabel
    }
    
    /// Whether this moment represents a major inflection point
    /// Used for accent styling (only these get visual emphasis)
    var isMajorInflection: Bool {
        switch type {
        case .flip, .closingControl:
            return true
        case .cut, .leadBuild:
            // Major if large swing
            if let delta = parseScoreDelta(), delta >= 10 {
                return true
            }
            return false
        default:
            return false
        }
    }
    
    /// Parse score delta from scoreStart/scoreEnd
    private func parseScoreDelta() -> Int? {
        let startScores = scoreStart.replacingOccurrences(of: "–", with: "-").split(separator: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        let endScores = scoreEnd.replacingOccurrences(of: "–", with: "-").split(separator: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        guard startScores.count == 2, endScores.count == 2 else { return nil }
        
        let startDiff = abs(startScores[0] - startScores[1])
        let endDiff = abs(endScores[0] - endScores[1])
        
        // Return the change in lead magnitude
        return abs(endDiff - startDiff)
    }
}

/// Type of moment - determines styling and importance
/// Based on Lead Ladder system from backend
enum MomentType: String, Codable {
    case leadBuild = "LEAD_BUILD"
    case cut = "CUT"
    case tie = "TIE"
    case flip = "FLIP"
    case closingControl = "CLOSING_CONTROL"
    case highImpact = "HIGH_IMPACT"
    case neutral = "NEUTRAL"
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .leadBuild:
            return "Lead extended"
        case .cut:
            return "Cutting in"
        case .tie:
            return "Tied up"
        case .flip:
            return "Lead change"
        case .closingControl:
            return "Dagger"
        case .highImpact:
            return "Key moment"
        case .neutral:
            return "Normal play"
        }
    }
    
    /// Whether this moment type is notable by default
    var isTypicallyNotable: Bool {
        self != .neutral
    }
    
    /// SF Symbol name for the moment type
    var iconName: String {
        switch self {
        case .leadBuild:
            return "arrow.up.right"
        case .cut:
            return "arrow.down.left"
        case .tie:
            return "equal"
        case .flip:
            return "arrow.left.arrow.right"
        case .closingControl:
            return "checkmark.seal.fill"
        case .highImpact:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "circle"
        }
    }
}

/// Run information when a scoring run contributed to a moment
struct RunInfo: Codable, Equatable {
    let team: String  // "home" or "away"
    let points: Int
    let unanswered: Bool
    let playIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case team
        case points
        case unanswered
        case playIds = "play_ids"
    }
}

/// Player contribution within a moment
struct PlayerContribution: Codable, Equatable {
    let name: String
    let stats: [String: Int]
    let summary: String?
    
    /// Formatted display string for stats
    var displayStats: String {
        if let summary = summary {
            return summary
        }
        
        var parts: [String] = []
        if let pts = stats["pts"], pts > 0 {
            parts.append("\(pts) pts")
        }
        if let ast = stats["ast"], ast > 0 {
            parts.append("\(ast) ast")
        }
        if let stl = stats["stl"], stl > 0 {
            parts.append("\(stl) stl")
        }
        if let blk = stats["blk"], blk > 0 {
            parts.append("\(blk) blk")
        }
        
        return parts.isEmpty ? name : parts.joined(separator: ", ")
    }
}

/// Response from the moments API endpoint
struct MomentsResponse: Codable {
    let gameId: Int
    let generatedAt: String
    let moments: [Moment]
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case generatedAt = "generated_at"
        case moments
        case totalCount = "total_count"
    }
    
    /// Computed highlight count (moments where isNotable=true)
    var highlightCount: Int {
        moments.filter { $0.isNotable }.count
    }
}
