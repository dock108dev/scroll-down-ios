import Foundation

/// Unified timeline event parsed from timeline_json
/// Supports both play-by-play (pbp) and social (tweet) events
/// Rendered in server-provided order — no client-side sorting
struct UnifiedTimelineEvent: Identifiable, Equatable {
    let id: String
    let eventType: EventType
    let syntheticTimestamp: String?
    let period: Int?
    let gameClock: String?
    let sport: String?  // For sport-aware period labeling (NBA, NHL, NCAAB, etc.)

    // PBP-specific fields
    let description: String?
    let team: String?
    let playerName: String?
    let homeScore: Int?
    let awayScore: Int?
    let playType: String?

    // Tweet-specific fields
    let tweetText: String?
    let tweetUrl: String?
    let sourceHandle: String?
    let imageUrl: String?
    let videoUrl: String?
    let postedAt: String?

    enum EventType: String, Equatable {
        case pbp
        case tweet
        case unknown
    }
    
    /// Parse from raw dictionary in timeline_json
    init(from dict: [String: Any], index: Int, sport: String? = nil) {
        // ID: use event_id if present, otherwise generate from index
        if let eventId = dict["event_id"] as? String {
            self.id = eventId
        } else if let eventId = dict["id"] as? Int {
            self.id = "event-\(eventId)"
        } else {
            self.id = "event-\(index)"
        }

        // Event type
        let rawType = dict["event_type"] as? String ?? ""
        self.eventType = EventType(rawValue: rawType) ?? .unknown

        // Sport (from parameter or dictionary)
        self.sport = sport ?? dict["sport"] as? String ?? dict["league"] as? String

        // Common fields
        self.syntheticTimestamp = dict["synthetic_timestamp"] as? String
            ?? dict["timestamp"] as? String
        self.period = dict["period"] as? Int
            ?? dict["quarter"] as? Int
        self.gameClock = dict["game_clock"] as? String
            ?? dict["clock"] as? String
        
        // PBP fields
        let rawDescription = dict["description"] as? String
            ?? dict["play_description"] as? String
        self.description = rawDescription
        self.team = dict["team"] as? String
            ?? dict["team_abbreviation"] as? String
        self.playType = dict["play_type"] as? String

        // Player name: use explicit field if available, otherwise extract from description
        if let explicitName = dict["player_name"] as? String ?? dict["player"] as? String,
           !explicitName.isEmpty {
            self.playerName = explicitName
        } else if let desc = rawDescription {
            self.playerName = PbpEvent.extractPlayerName(from: desc)
        } else {
            self.playerName = nil
        }
        
        // Score parsing - handle multiple formats
        // Format 1: separate home_score/away_score fields
        if let home = dict["home_score"] as? Int, let away = dict["away_score"] as? Int {
            self.homeScore = home
            self.awayScore = away
        }
        // Format 2: combined "score" string like "102-98" or "0-2"
        else if let scoreStr = dict["score"] as? String {
            let parts = scoreStr.split(separator: "-").map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2, let away = Int(parts[0]), let home = Int(parts[1]) {
                self.awayScore = away
                self.homeScore = home
            } else {
                self.homeScore = nil
                self.awayScore = nil
            }
        }
        // Format 3: nested score object
        else if let scoreDict = dict["score"] as? [String: Any] {
            self.homeScore = scoreDict["home"] as? Int ?? scoreDict["home_score"] as? Int
            self.awayScore = scoreDict["away"] as? Int ?? scoreDict["away_score"] as? Int
        }
        else {
            self.homeScore = nil
            self.awayScore = nil
        }
        
        // Tweet fields
        self.tweetText = dict["tweet_text"] as? String
            ?? dict["text"] as? String
        self.tweetUrl = dict["tweet_url"] as? String
            ?? dict["post_url"] as? String
        self.sourceHandle = dict["source_handle"] as? String
            ?? dict["handle"] as? String
        self.imageUrl = dict["image_url"] as? String
        self.videoUrl = dict["video_url"] as? String
        self.postedAt = dict["posted_at"] as? String
    }
    
    /// Display title for the event
    var displayTitle: String {
        switch eventType {
        case .pbp:
            return description ?? "Play"
        case .tweet:
            return tweetText ?? "Tweet"
        case .unknown:
            return description ?? tweetText ?? "Event"
        }
    }
    
    /// Time label for display (sport-aware period labeling)
    var timeLabel: String? {
        guard let clock = gameClock else { return nil }
        guard let period = period else { return clock }

        let periodLabel = Self.periodLabel(for: period, sport: sport)
        return "\(periodLabel) \(clock)"
    }

    /// Returns the period label based on sport
    /// - NBA: Q1, Q2, Q3, Q4, OT, 2OT, etc.
    /// - NHL: P1, P2, P3, OT, SO
    /// - NCAAB: H1, H2, OT, 2OT, etc.
    static func periodLabel(for period: Int, sport: String?) -> String {
        let sportUpper = sport?.uppercased()

        switch sportUpper {
        case "NHL":
            switch period {
            case 1...3: return "P\(period)"
            case 4: return "OT"
            case 5: return "SO"  // Shootout
            default: return "\(period - 4)OT"
            }
        case "NCAAB":
            switch period {
            case 1: return "H1"
            case 2: return "H2"
            case 3: return "OT"
            default: return "\(period - 2)OT"
            }
        case "NBA", .none:
            // Default to NBA-style quarters
            switch period {
            case 1...4: return "Q\(period)"
            case 5: return "OT"
            default: return "\(period - 4)OT"
            }
        default:
            // Generic fallback
            return "Q\(period)"
        }
    }
}
