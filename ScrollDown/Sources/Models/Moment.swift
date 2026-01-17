import Foundation

/// Moment representing a segment of the game timeline
/// Moments partition the entire game - every play belongs to exactly one moment
/// Use `is_notable` to filter for highlights
struct Moment: Codable, Identifiable, Equatable {
    let id: String
    let type: MomentType
    let startPlay: Int
    let endPlay: Int
    let playCount: Int
    let teams: [String]
    let players: [PlayerContribution]
    let scoreStart: String
    let scoreEnd: String
    let clock: String
    let isNotable: Bool
    let note: String?
    
    // v2 optional fields
    let runInfo: RunInfo?
    let ladderTierBefore: Int?
    let ladderTierAfter: Int?
    let teamInControl: String?
    let keyPlayIds: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case startPlay = "start_play"
        case endPlay = "end_play"
        case playCount = "play_count"
        case teams
        case players
        case scoreStart = "score_start"
        case scoreEnd = "score_end"
        case clock
        case isNotable = "is_notable"
        case note
        case runInfo = "run_info"
        case ladderTierBefore = "ladder_tier_before"
        case ladderTierAfter = "ladder_tier_after"
        case teamInControl = "team_in_control"
        case keyPlayIds = "key_play_ids"
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
    case opener = "OPENER"
    case neutral = "NEUTRAL"
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .leadBuild:
            return "Lead extends"
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
        case .opener:
            return "Period start"
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
        case .opener:
            return "flag.fill"
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
    let highlightCount: Int
    
    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case generatedAt = "generated_at"
        case moments
        case totalCount = "total_count"
        case highlightCount = "highlight_count"
    }
}
