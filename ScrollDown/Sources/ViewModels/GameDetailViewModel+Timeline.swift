import Foundation

// MARK: - Timeline Extension

extension GameDetailViewModel {
    // MARK: - Unified Timeline

    /// Unified timeline events - merges plays (with scores) and social posts
    var unifiedTimelineEvents: [UnifiedTimelineEvent] {
        var events: [UnifiedTimelineEvent] = []

        // Get sport for period labeling (NBA, NHL, NCAAB, etc.)
        let sport = detail?.game.leagueCode

        // Priority: detail.plays > storyPlays > pbpEvents
        let plays = detail?.plays ?? []
        if !plays.isEmpty {
            let playEvents = plays.enumerated().map { index, play in
                UnifiedTimelineEvent(from: playToDictionary(play), index: index, sport: sport)
            }
            events.append(contentsOf: playEvents)
        } else if !storyPlays.isEmpty {
            // Use story plays if available (when story loaded but detail.plays is empty)
            let playEvents = storyPlays.enumerated().map { index, play in
                UnifiedTimelineEvent(from: storyPlayToDictionary(play), index: index, sport: sport)
            }
            events.append(contentsOf: playEvents)
        } else if !pbpEvents.isEmpty {
            // Use separately fetched PBP events
            let playEvents = pbpEvents.enumerated().map { index, event in
                UnifiedTimelineEvent(from: pbpEventToDictionary(event), index: index, sport: sport)
            }
            events.append(contentsOf: playEvents)
        }

        let totalPlays = plays.isEmpty ? pbpEvents.count : plays.count

        if let timelineValue = timelineArtifact?.timelineJson?.value {
            let rawEvents = extractTimelineEvents(from: timelineValue)
            let tweetEvents = rawEvents.enumerated().compactMap { index, dict -> UnifiedTimelineEvent? in
                let eventType = dict["event_type"] as? String
                guard eventType == "tweet" else { return nil }
                return UnifiedTimelineEvent(from: dict, index: totalPlays + index, sport: sport)
            }
            events.append(contentsOf: tweetEvents)
        }

        return events
    }

    /// Whether timeline/PBP data is available for "View All Plays"
    /// True if we have: story plays, detail plays, or separately fetched PBP events
    var hasUnifiedTimeline: Bool {
        // Story plays are available
        if !storyPlays.isEmpty {
            return true
        }
        // Regular timeline events are available
        return !unifiedTimelineEvents.isEmpty
    }

    var timelineArtifactSummary: TimelineArtifactSummary? {
        guard let timelineValue = timelineArtifact?.timelineJson?.value else {
            return nil
        }

        let events = extractTimelineEvents(from: timelineValue)
        guard !events.isEmpty else {
            return TimelineArtifactSummary(eventCount: 0, firstTimestamp: nil, lastTimestamp: nil)
        }

        let firstTimestamp = extractTimestamp(from: events.first)
        let lastTimestamp = extractTimestamp(from: events.last)
        return TimelineArtifactSummary(
            eventCount: events.count,
            firstTimestamp: firstTimestamp,
            lastTimestamp: lastTimestamp
        )
    }

    /// Summary state derived from timeline artifact
    var summaryState: SummaryState {
        if let summaryText = extractSummaryFromArtifact() {
            return .available(summaryText)
        }
        return .unavailable
    }

    /// Extract narrative summary from timeline artifact's summary_json
    func extractSummaryFromArtifact() -> String? {
        guard let summaryJson = timelineArtifact?.summaryJson,
              let dict = summaryJson.value as? [String: Any] else {
            return nil
        }

        if let overall = dict["overall"] as? String {
            return sanitizeSummary(overall)
        }

        if let summary = dict["summary"] as? String {
            return sanitizeSummary(summary)
        }

        if let directSummary = summaryJson.value as? String {
            return sanitizeSummary(directSummary)
        }

        return nil
    }

    var highlightByPlayIndex: [Int: [SocialPostEntry]] {
        let plays = detail?.plays ?? []
        let highlightPosts = highlights
        guard !plays.isEmpty, !highlightPosts.isEmpty else {
            return [:]
        }

        let spacing = max(TimelineConstants.minimumHighlightSpacing, plays.count / max(TimelineConstants.minimumHighlightSpacing, highlightPosts.count))
        var mapping: [Int: [SocialPostEntry]] = [:]

        for (index, highlight) in highlightPosts.enumerated() {
            let playIndex = highlightPlayIndex(for: index, spacing: spacing, plays: plays)
            mapping[playIndex, default: []].append(highlight)
        }

        return mapping
    }

    // MARK: - Pre/Post Game Tweet Helpers

    /// Pre-game tweets (tweets before the first PBP event)
    var pregameTweets: [UnifiedTimelineEvent] {
        guard let firstPbpIndex = unifiedTimelineEvents.firstIndex(where: { $0.eventType == .pbp }) else {
            return unifiedTimelineEvents.filter { $0.eventType == .tweet && $0.period == nil }
        }
        return Array(unifiedTimelineEvents.prefix(upTo: firstPbpIndex)).filter { $0.eventType == .tweet }
    }

    /// Post-game tweets (tweets after the last PBP event)
    var postGameTweets: [UnifiedTimelineEvent] {
        guard let lastPbpIndex = unifiedTimelineEvents.lastIndex(where: { $0.eventType == .pbp }) else {
            return []
        }
        let afterLastPbp = unifiedTimelineEvents.suffix(from: unifiedTimelineEvents.index(after: lastPbpIndex))
        return Array(afterLastPbp).filter { $0.eventType == .tweet }
    }

    // MARK: - Timeline Parsing Helpers

    func extractTimelineEvents(from value: Any) -> [[String: Any]] {
        if let events = value as? [[String: Any]] {
            return events
        }

        if let array = value as? [Any] {
            return array.compactMap { $0 as? [String: Any] }
        }

        if let dict = value as? [String: Any] {
            if let events = dict[TimelineConstants.eventsKey] as? [[String: Any]] {
                return events
            }
            if let eventsArray = dict[TimelineConstants.eventsKey] as? [Any] {
                return eventsArray.compactMap { $0 as? [String: Any] }
            }
        }

        return []
    }

    func extractTimestamp(from event: [String: Any]?) -> String? {
        guard let event else {
            return nil
        }

        let candidates = [
            TimelineConstants.timestampKey,
            TimelineConstants.eventTimestampKey,
            TimelineConstants.timeKey,
            TimelineConstants.clockKey
        ]

        for key in candidates {
            if let value = event[key] {
                if let stringValue = value as? String {
                    return stringValue
                }
                if let numberValue = value as? NSNumber {
                    return numberValue.stringValue
                }
            }
        }

        return nil
    }

    func highlightPlayIndex(for index: Int, spacing: Int, plays: [PlayEntry]) -> Int {
        let targetIndex = min(index * spacing, plays.count - 1)
        return plays[targetIndex].playIndex
    }

    func sanitizeSummary(_ summary: String) -> String? {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let regex = TimelineConstants.scoreRegex {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return nil
            }
        }

        return trimmed
    }

    /// Convert PlayEntry to dictionary for UnifiedTimelineEvent parsing
    func playToDictionary(_ play: PlayEntry) -> [String: Any] {
        var dict: [String: Any] = [
            "event_type": "pbp",
            "play_index": play.playIndex
        ]
        if let quarter = play.quarter { dict["period"] = quarter }
        if let clock = play.gameClock { dict["game_clock"] = clock }
        if let desc = play.description { dict["description"] = desc }
        if let team = play.teamAbbreviation { dict["team"] = team }
        if let player = play.playerName { dict["player_name"] = player }
        if let home = play.homeScore { dict["home_score"] = home }
        if let away = play.awayScore { dict["away_score"] = away }
        if let playType = play.playType { dict["play_type"] = playType.rawValue }
        return dict
    }

    /// Convert PbpEvent to dictionary for UnifiedTimelineEvent parsing
    func pbpEventToDictionary(_ event: PbpEvent) -> [String: Any] {
        var dict: [String: Any] = [
            "event_type": "pbp"
        ]
        if let period = event.period { dict["period"] = period }
        if let clock = event.gameClock { dict["game_clock"] = clock }
        if let desc = event.description { dict["description"] = desc }
        if let team = event.team { dict["team"] = team }
        if let player = event.playerName { dict["player_name"] = player }
        if let home = event.homeScore { dict["home_score"] = home }
        if let away = event.awayScore { dict["away_score"] = away }
        if let eventType = event.eventType { dict["play_type"] = eventType }
        return dict
    }

    /// Convert StoryPlay to dictionary for UnifiedTimelineEvent parsing
    func storyPlayToDictionary(_ play: StoryPlay) -> [String: Any] {
        var dict: [String: Any] = [
            "event_type": "pbp",
            "play_index": play.playIndex,
            "period": play.period
        ]
        if let clock = play.clock { dict["game_clock"] = clock }
        if let desc = play.description { dict["description"] = desc }
        if let team = play.team { dict["team"] = team }
        if let player = play.playerName { dict["player_name"] = player }
        if let home = play.homeScore { dict["home_score"] = home }
        if let away = play.awayScore { dict["away_score"] = away }
        if let playType = play.playType { dict["play_type"] = playType }
        return dict
    }
}

// MARK: - Timeline Constants

enum TimelineConstants {
    static let minimumHighlightSpacing = 1
    static let eventsKey = "events"
    static let timestampKey = "timestamp"
    static let eventTimestampKey = "event_timestamp"
    static let timeKey = "time"
    static let clockKey = "clock"
    static let scorePattern = #"(\d+)\s*(?:-|–|to)\s*(\d+)"#
    static let scoreRegex = try? NSRegularExpression(pattern: scorePattern, options: [])
}
