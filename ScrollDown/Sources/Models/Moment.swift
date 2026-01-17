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
enum MomentType: String, Codable {
    case neutral = "NEUTRAL"
    case run = "RUN"
    case battle = "BATTLE"
    case closing = "CLOSING"
    
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .neutral:
            return "Normal play"
        case .run:
            return "Scoring run"
        case .battle:
            return "Lead changes"
        case .closing:
            return "Closing time"
        }
    }
    
    /// Whether this moment type is notable by default
    var isTypicallyNotable: Bool {
        self != .neutral
    }
    
    /// SF Symbol name for the moment type
    var iconName: String {
        switch self {
        case .neutral:
            return "circle"
        case .run:
            return "flame.fill"
        case .battle:
            return "arrow.left.arrow.right"
        case .closing:
            return "clock.fill"
        }
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
