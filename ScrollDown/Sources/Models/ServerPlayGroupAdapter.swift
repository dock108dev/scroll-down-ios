import Foundation

/// Converts server-provided `ServerTieredPlayGroup` data into `TieredPlayGroup` display models.
/// When the server provides pre-computed play groupings with summary labels, this adapter
/// maps them onto the existing tiered display system, avoiding redundant client-side grouping.
enum ServerPlayGroupAdapter {

    /// Convert server play groups + timeline events into display-ready `TieredPlayGroup` models.
    /// Events not covered by any server group are treated as secondary (tier 2).
    static func convert(
        serverGroups: [ServerTieredPlayGroup],
        events: [UnifiedTimelineEvent]
    ) -> [TieredPlayGroup] {
        // Build index lookup: playIndex → event
        // UnifiedTimelineEvent doesn't have playIndex directly, so use array position
        let pbpEvents = events.filter { $0.eventType == .pbp }

        // Build a set of all indices covered by server groups
        var coveredIndices = Set<Int>()
        for group in serverGroups {
            coveredIndices.formUnion(group.playIndices)
        }

        var result: [TieredPlayGroup] = []
        var currentUncoveredGroup: [UnifiedTimelineEvent] = []
        var groupCounter = 0

        for (arrayIndex, event) in pbpEvents.enumerated() {
            let eventTier = PlayTier(rawTier: event.tier ?? 2)

            // Check if this event's array index falls in a server group
            if let serverGroup = serverGroups.first(where: { $0.playIndices.contains(arrayIndex) }) {
                // Flush any uncovered events first
                if !currentUncoveredGroup.isEmpty {
                    result.append(TieredPlayGroup(
                        id: "uncovered-\(groupCounter)",
                        events: currentUncoveredGroup,
                        tier: eventTier == .primary ? .primary : .secondary
                    ))
                    groupCounter += 1
                    currentUncoveredGroup = []
                }

                // Check if we already added this server group
                let serverGroupId = "server-group-\(serverGroup.startIndex)-\(serverGroup.endIndex)"
                if !result.contains(where: { $0.id == serverGroupId }) {
                    let groupEvents = serverGroup.playIndices.compactMap { idx -> UnifiedTimelineEvent? in
                        guard idx < pbpEvents.count else { return nil }
                        return pbpEvents[idx]
                    }
                    result.append(TieredPlayGroup(
                        id: serverGroupId,
                        events: groupEvents,
                        tier: .tertiary,
                        serverSummary: serverGroup.summaryLabel
                    ))
                }
            } else {
                // Event not in any server group
                if eventTier == .primary {
                    // Flush accumulated uncovered events
                    if !currentUncoveredGroup.isEmpty {
                        result.append(TieredPlayGroup(
                            id: "uncovered-\(groupCounter)",
                            events: currentUncoveredGroup,
                            tier: .secondary
                        ))
                        groupCounter += 1
                        currentUncoveredGroup = []
                    }
                    // Primary events get their own group
                    result.append(TieredPlayGroup(
                        id: event.id,
                        events: [event],
                        tier: .primary
                    ))
                } else {
                    currentUncoveredGroup.append(event)
                }
            }
        }

        // Flush remaining uncovered events
        if !currentUncoveredGroup.isEmpty {
            result.append(TieredPlayGroup(
                id: "uncovered-\(groupCounter)",
                events: currentUncoveredGroup,
                tier: .secondary
            ))
        }

        return result
    }
}
