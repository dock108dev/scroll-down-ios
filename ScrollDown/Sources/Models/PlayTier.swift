import Foundation

/// Visual hierarchy tier for play-by-play events
/// Tier 1: High-impact moments (made shots, lead changes, clutch plays)
/// Tier 2: Contextual events (fouls, turnovers, violations)
/// Tier 3: Low-signal noise (misses, rebounds, subs) - collapsed by default
enum PlayTier: Int, Comparable {
    case primary = 1    // Always visible, strongest visual weight
    case secondary = 2  // Visible but de-emphasized
    case tertiary = 3   // Collapsed by default

    static func < (lhs: PlayTier, rhs: PlayTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    init(rawTier: Int) {
        switch rawTier {
        case 1: self = .primary
        case 3: self = .tertiary
        default: self = .secondary
        }
    }
}

/// Represents a group of events at the same tier for display
struct TieredPlayGroup: Identifiable {
    let id: String
    let events: [UnifiedTimelineEvent]
    let tier: PlayTier

    /// Whether this group contains multiple events (for collapse UI)
    var isCollapsible: Bool {
        tier == .tertiary && events.count > 1
    }

    /// Summary text for collapsed Tier 3 groups
    var collapsedSummary: String {
        let count = events.count
        let missCount = events.filter { $0.description?.lowercased().contains("miss") == true }.count
        let reboundCount = events.filter { $0.description?.lowercased().contains("rebound") == true }.count

        var parts: [String] = []
        if missCount > 0 { parts.append("\(missCount) missed shot\(missCount == 1 ? "" : "s")") }
        if reboundCount > 0 { parts.append("\(reboundCount) rebound\(reboundCount == 1 ? "" : "s")") }

        let otherCount = count - missCount - reboundCount
        if otherCount > 0 && parts.isEmpty {
            return "\(count) play\(count == 1 ? "" : "s")"
        } else if otherCount > 0 {
            parts.append("\(otherCount) other")
        }

        return parts.isEmpty ? "\(count) play\(count == 1 ? "" : "s")" : parts.joined(separator: ", ")
    }
}

/// Groups events into tiered display groups.
/// Uses `tier` from each event (defaults to 2 when absent).
enum TieredPlayGrouper {

    static func group(events: [UnifiedTimelineEvent]) -> [TieredPlayGroup] {
        var groups: [TieredPlayGroup] = []
        var currentTier3Group: [UnifiedTimelineEvent] = []
        var groupIndex = 0

        for event in events {
            guard event.eventType == .pbp else { continue }

            let tier = PlayTier(rawTier: event.tier ?? 2)

            if tier == .tertiary {
                currentTier3Group.append(event)
            } else {
                // Flush accumulated Tier 3 events
                if !currentTier3Group.isEmpty {
                    groups.append(TieredPlayGroup(
                        id: "tier3-group-\(groupIndex)",
                        events: currentTier3Group,
                        tier: .tertiary
                    ))
                    groupIndex += 1
                    currentTier3Group = []
                }

                groups.append(TieredPlayGroup(
                    id: event.id,
                    events: [event],
                    tier: tier
                ))
            }
        }

        // Flush remaining Tier 3 events
        if !currentTier3Group.isEmpty {
            groups.append(TieredPlayGroup(
                id: "tier3-group-\(groupIndex)",
                events: currentTier3Group,
                tier: .tertiary
            ))
        }

        return groups
    }
}
