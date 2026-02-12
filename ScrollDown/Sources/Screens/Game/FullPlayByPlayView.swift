import SwiftUI

/// Full chronological play-by-play view with tiered visual hierarchy
/// Tier 1: High-impact (scoring, lead changes) - Always visible, bold
/// Tier 2: Contextual (fouls, turnovers) - Visible, de-emphasized
/// Tier 3: Low-signal (misses, rebounds) - Collapsed by default
struct FullPlayByPlayView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var collapsedPeriods: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.list) {
                    ForEach(groupedPeriods, id: \.period) { group in
                        periodCard(group)
                    }

                    // Ungrouped events (pre/post game tweets)
                    if !ungroupedEvents.isEmpty {
                        ForEach(ungroupedEvents) { event in
                            UnifiedTimelineRowView(
                                event: event,
                                homeTeam: viewModel.game?.homeTeam ?? "Home",
                                awayTeam: viewModel.game?.awayTeam ?? "Away"
                            )
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                .padding(.vertical, DesignSystem.Spacing.section)
            }
            .background(GameTheme.background)
            .navigationTitle("Play-by-Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // All periods collapsed by default - user expands what they want
                let allPeriods = Set(groupedPeriods.map { $0.period })
                collapsedPeriods = allPeriods
            }
        }
    }

    // MARK: - Period Grouping

    private var groupedPeriods: [PeriodGroup] {
        let events = viewModel.unifiedTimelineEvents
        var groups: [Int: [UnifiedTimelineEvent]] = [:]

        for event in events {
            let period = event.period ?? 0
            if period > 0 {
                groups[period, default: []].append(event)
            }
        }

        return groups.keys.sorted().map { period in
            PeriodGroup(period: period, events: groups[period] ?? [])
        }
    }

    private var ungroupedEvents: [UnifiedTimelineEvent] {
        viewModel.unifiedTimelineEvents.filter { $0.period == nil || $0.period == 0 }
    }

    // MARK: - Period Card with Tiered Display

    private func periodCard(_ group: PeriodGroup) -> some View {
        let tieredGroups: [TieredPlayGroup] = {
            if viewModel.hasServerGroupings {
                // Filter server groups to this period's index range
                let periodIndices = Set(group.events.compactMap { event -> Int? in
                    guard let idx = viewModel.unifiedTimelineEvents.firstIndex(where: { $0.id == event.id }) else { return nil }
                    return idx
                })
                let relevantServerGroups = viewModel.serverPlayGroups.filter { serverGroup in
                    !Set(serverGroup.playIndices).isDisjoint(with: periodIndices)
                }
                if !relevantServerGroups.isEmpty {
                    return ServerPlayGroupAdapter.convert(
                        serverGroups: relevantServerGroups,
                        events: group.events
                    )
                }
            }
            return TieredPlayGrouper.group(events: group.events)
        }()

        // Count visible plays (Tier 1 + Tier 2 + collapsed Tier 3 groups)
        let tier1Count = tieredGroups.filter { $0.tier == .primary }.flatMap { $0.events }.count
        let tier2Count = tieredGroups.filter { $0.tier == .secondary }.flatMap { $0.events }.count
        let tier3GroupCount = tieredGroups.filter { $0.tier == .tertiary }.count

        return CollapsibleQuarterCard(
            title: periodTitle(group.period, events: group.events),
            subtitle: "\(tier1Count) key plays, \(tier2Count + tier3GroupCount) other",
            isExpanded: Binding(
                get: { !collapsedPeriods.contains(group.period) },
                set: { isExpanded in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            collapsedPeriods.remove(group.period)
                        } else {
                            collapsedPeriods.insert(group.period)
                        }
                    }
                }
            )
        ) {
            LazyVStack(spacing: 6) {
                ForEach(tieredGroups) { tieredGroup in
                    TieredPlayGroupView(
                        group: tieredGroup,
                        homeTeam: viewModel.game?.homeTeam ?? "Home",
                        awayTeam: viewModel.game?.awayTeam ?? "Away",
                        keyPlayIds: viewModel.allKeyPlayIds
                    )
                }
            }
        }
    }

    // MARK: - Period Title

    /// Returns the period title
    private func periodTitle(_ period: Int, events: [UnifiedTimelineEvent] = []) -> String {
        if period == 0 {
            return "Additional"
        }

        guard let label = events.first?.periodLabel, !label.isEmpty else {
            return "Q\(period)"
        }

        // Expand abbreviated labels for section headers
        switch label {
        case "P1": return "Period 1"
        case "P2": return "Period 2"
        case "P3": return "Period 3"
        default: return label
        }
    }
}

/// Helper struct for grouping events by period
private struct PeriodGroup {
    let period: Int
    let events: [UnifiedTimelineEvent]
}

// MARK: - Previews

#Preview("Full Play-by-Play") {
    let viewModel = GameDetailViewModel()
    return FullPlayByPlayView(viewModel: viewModel)
}
