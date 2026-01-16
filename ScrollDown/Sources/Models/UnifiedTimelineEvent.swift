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
    init(from dict: [String: Any], index: Int) {
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
        
        // Common fields
        self.syntheticTimestamp = dict["synthetic_timestamp"] as? String
            ?? dict["timestamp"] as? String
        self.period = dict["period"] as? Int
            ?? dict["quarter"] as? Int
        self.gameClock = dict["game_clock"] as? String
            ?? dict["clock"] as? String
        
        // PBP fields
        self.description = dict["description"] as? String
            ?? dict["play_description"] as? String
        self.team = dict["team"] as? String
            ?? dict["team_abbreviation"] as? String
        self.playerName = dict["player_name"] as? String
            ?? dict["player"] as? String
        self.playType = dict["play_type"] as? String
        
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
    
    /// Time label for display
    var timeLabel: String? {
        if let clock = gameClock, let period = period {
            return "Q\(period) \(clock)"
        }
        if let clock = gameClock {
            return clock
        }
        return nil
    }
}
