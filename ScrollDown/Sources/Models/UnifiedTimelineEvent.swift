import Foundation

/// Unified timeline event parsed from server timeline
/// Supports play-by-play (pbp), social (tweet), and odds events
/// Rendered in timeline order
struct UnifiedTimelineEvent: Identifiable {
    let id: String
    let eventType: EventType
    let syntheticTimestamp: String?
    let period: Int?
    let gameClock: String?
    let sport: String?

    // PBP-specific fields
    let description: String?
    let team: String?
    let playerName: String?
    let homeScore: Int?
    let awayScore: Int?
    let playType: String?

    let periodLabel: String?
    let timeLabel: String?
    let tier: Int?

    // Odds-specific fields
    let oddsType: String?
    let oddsMarkets: [String: Any]?
    let oddsBook: String?
    let oddsMovements: [[String: Any]]?

    // Tweet-specific fields
    let tweetText: String?
    let tweetUrl: String?
    let sourceHandle: String?
    let imageUrl: String?
    let videoUrl: String?
    let postedAt: String?

    // Engagement metrics (tweets)
    let likesCount: Int?
    let retweetsCount: Int?
    let repliesCount: Int?

    enum EventType: String, Equatable {
        case pbp
        case tweet
        case odds
        case unknown
    }

    /// Parse from raw dictionary — expects canonical snake_case keys from server
    init(from dict: [String: Any], index: Int, sport: String? = nil) {
        if let eventId = dict["event_id"] as? String {
            self.id = eventId
        } else if let eventId = dict["id"] as? Int {
            self.id = "event-\(eventId)"
        } else {
            self.id = "event-\(index)"
        }

        let rawType = dict["event_type"] as? String ?? ""
        self.eventType = EventType(rawValue: rawType) ?? .unknown

        self.sport = sport ?? dict["sport"] as? String

        self.syntheticTimestamp = dict["synthetic_timestamp"] as? String
        self.period = dict["period"] as? Int
        self.gameClock = dict["game_clock"] as? String

        self.periodLabel = dict["period_label"] as? String
        self.timeLabel = dict["time_label"] as? String

        self.tier = dict["tier"] as? Int

        self.oddsType = dict["odds_type"] as? String
        self.oddsMarkets = dict["odds_markets"] as? [String: Any]
        self.oddsBook = dict["book"] as? String
        self.oddsMovements = dict["movements"] as? [[String: Any]]

        let rawDescription = dict["description"] as? String
        self.description = rawDescription
        self.team = dict["team"] as? String
        self.playType = dict["play_type"] as? String

        if let explicitName = dict["player_name"] as? String,
           !explicitName.isEmpty {
            self.playerName = explicitName
        } else if let desc = rawDescription {
            self.playerName = PbpEvent.extractPlayerName(from: desc)
        } else {
            self.playerName = nil
        }

        if let home = dict["home_score"] as? Int, let away = dict["away_score"] as? Int {
            self.homeScore = home
            self.awayScore = away
        } else {
            self.homeScore = nil
            self.awayScore = nil
        }

        self.tweetText = dict["tweet_text"] as? String
        self.tweetUrl = dict["tweet_url"] as? String
        self.sourceHandle = dict["source_handle"] as? String
        self.imageUrl = dict["image_url"] as? String
        self.videoUrl = dict["video_url"] as? String
        self.postedAt = dict["posted_at"] as? String

        self.likesCount = dict["likes_count"] as? Int
        self.retweetsCount = dict["retweets_count"] as? Int
        self.repliesCount = dict["replies_count"] as? Int
    }

    /// Display title for the event
    var displayTitle: String {
        switch eventType {
        case .pbp:
            return description ?? "Play"
        case .tweet:
            return tweetText ?? "Tweet"
        case .odds:
            return description ?? "Odds Update"
        case .unknown:
            return description ?? tweetText ?? "Event"
        }
    }
}

// MARK: - Equatable

extension UnifiedTimelineEvent: Equatable {
    static func == (lhs: UnifiedTimelineEvent, rhs: UnifiedTimelineEvent) -> Bool {
        lhs.id == rhs.id &&
        lhs.eventType == rhs.eventType &&
        lhs.period == rhs.period &&
        lhs.gameClock == rhs.gameClock &&
        lhs.description == rhs.description &&
        lhs.homeScore == rhs.homeScore &&
        lhs.awayScore == rhs.awayScore &&
        lhs.oddsBook == rhs.oddsBook &&
        lhs.likesCount == rhs.likesCount &&
        lhs.retweetsCount == rhs.retweetsCount &&
        lhs.repliesCount == rhs.repliesCount
    }
}
