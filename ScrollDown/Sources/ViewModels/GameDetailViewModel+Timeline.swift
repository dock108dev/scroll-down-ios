import Foundation

// MARK: - Timeline Extension

extension GameDetailViewModel {
    // MARK: - Unified Timeline

    /// Unified timeline events - merges plays (with scores) and social posts
    var unifiedTimelineEvents: [UnifiedTimelineEvent] {
        var events: [UnifiedTimelineEvent] = []

        let plays = detail?.plays ?? []
        let pbpEvents = plays.enumerated().map { index, play in
            UnifiedTimelineEvent(from: playToDictionary(play), index: index)
        }
        events.append(contentsOf: pbpEvents)

        if let timelineValue = timelineArtifact?.timelineJson?.value {
            let rawEvents = extractTimelineEvents(from: timelineValue)
            let tweetEvents = rawEvents.enumerated().compactMap { index, dict -> UnifiedTimelineEvent? in
                let eventType = dict["event_type"] as? String
                guard eventType == "tweet" else { return nil }
                return UnifiedTimelineEvent(from: dict, index: plays.count + index)
            }
            events.append(contentsOf: tweetEvents)
        }

        return events
    }

    /// Whether timeline data is available from timeline_json
    var hasUnifiedTimeline: Bool {
        !unifiedTimelineEvents.isEmpty
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
