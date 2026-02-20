import Foundation

/// Converts server-provided `ServerTieredPlayGroup` data into `TieredPlayGroup` display models.
/// When the server provides pre-computed play groupings with summary labels, this adapter
/// maps them onto the tiered display system.
enum ServerPlayGroupAdapter {

    /// Convert server play groups + timeline events into display-ready `TieredPlayGroup` models.
    /// Events not covered by any server group are treated as secondary (tier 2).
    static func convert(
        serverGroups: [ServerTieredPlayGroup],
        events: [UnifiedTimelineEvent]
    ) -> [TieredPlayGroup] {
        let pbpEvents = events.filter { $0.eventType == .pbp }

        // Build lookup: playIndex → event by parsing "play-{playIndex}" IDs
        var eventByPlayIndex: [Int: UnifiedTimelineEvent] = [:]
        for event in pbpEvents {
            if let playIndex = parsePlayIndex(from: event.id) {
                eventByPlayIndex[playIndex] = event
            }
        }

        // Build a set of all play indices covered by server groups
        var coveredPlayIndices = Set<Int>()
        for group in serverGroups {
            coveredPlayIndices.formUnion(group.playIndices)
        }

        var result: [TieredPlayGroup] = []
        var currentUncoveredGroup: [UnifiedTimelineEvent] = []
        var groupCounter = 0
        var addedServerGroupIds = Set<String>()

        for event in pbpEvents {
            let playIndex = parsePlayIndex(from: event.id)
            let eventTier = PlayTier(rawTier: event.tier ?? 2)

            // Check if this event's playIndex falls in a server group
            if let idx = playIndex,
               let serverGroup = serverGroups.first(where: { $0.playIndices.contains(idx) }) {
                // Flush any uncovered events first
                if !currentUncoveredGroup.isEmpty {
                    result.append(TieredPlayGroup(
                        id: "uncovered-\(groupCounter)",
                        events: currentUncoveredGroup,
                        tier: .secondary
                    ))
                    groupCounter += 1
                    currentUncoveredGroup = []
                }

                // Check if we already added this server group
                let serverGroupId = "server-group-\(serverGroup.startIndex)-\(serverGroup.endIndex)"
                if !addedServerGroupIds.contains(serverGroupId) {
                    addedServerGroupIds.insert(serverGroupId)
                    let groupEvents = serverGroup.playIndices.compactMap { eventByPlayIndex[$0] }
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

    /// Parse the integer play index from an event ID formatted as "play-{playIndex}"
    private static func parsePlayIndex(from eventId: String) -> Int? {
        guard eventId.hasPrefix("play-") else { return nil }
        return Int(eventId.dropFirst(5))
    }
}
