import Foundation

// MARK: - Timeline Extension

extension GameDetailViewModel {
    // MARK: - Unified Timeline

    /// Unified timeline events from server
    var unifiedTimelineEvents: [UnifiedTimelineEvent] {
        serverUnifiedTimeline ?? []
    }

    /// Whether timeline/PBP data is available for "View All Plays"
    /// True if we have: flow plays, detail plays, or separately fetched PBP events
    var hasUnifiedTimeline: Bool {
        // Flow plays are available
        if !flowPlays.isEmpty {
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

    // MARK: - Phase-Filtered Social Posts

    /// Pregame social posts sorted by likes (most popular first)
    var pregameSocialPosts: [SocialPostEntry] {
        (detail?.socialPosts.filter { $0.gamePhase == "pregame" && $0.hasContent } ?? [])
            .sorted { ($0.likesCount ?? 0) > ($1.likesCount ?? 0) }
    }

    /// In-game social posts (tweets posted during the game) sorted by time
    var inGameSocialPosts: [SocialPostEntry] {
        (detail?.socialPosts.filter { $0.gamePhase == "in_game" && $0.hasContent } ?? [])
            .sorted { $0.postedAt < $1.postedAt }
    }

    /// Postgame social posts based on server-assigned gamePhase (oldest first)
    var postgameSocialPosts: [SocialPostEntry] {
        (detail?.socialPosts.filter { $0.gamePhase == "postgame" && $0.hasContent } ?? [])
            .sorted { $0.postedAt < $1.postedAt }
    }

    // MARK: - Key Play IDs

    /// Union of all key play IDs across all flow blocks
    var allKeyPlayIds: Set<Int> {
        guard let response = flowResponse else { return [] }
        var ids = Set<Int>()
        for block in response.blocks {
            ids.formUnion(block.keyPlayIds)
        }
        return ids
    }

    // MARK: - Server Play Groupings

    /// Server-provided tiered play groups from game detail response
    var serverPlayGroups: [ServerTieredPlayGroup] {
        detail?.groupedPlays ?? []
    }

    /// Whether the server provided pre-computed play groupings
    var hasServerGroupings: Bool {
        !serverPlayGroups.isEmpty
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

}

// MARK: - Timeline Constants

enum TimelineConstants {
    static let eventsKey = "events"
    static let timestampKey = "timestamp"
    static let eventTimestampKey = "event_timestamp"
    static let timeKey = "time"
    static let clockKey = "clock"
    static let scorePattern = #"(\d+)\s*(?:-|–|to)\s*(\d+)"#
    static let scoreRegex = try? NSRegularExpression(pattern: scorePattern, options: [])
}
