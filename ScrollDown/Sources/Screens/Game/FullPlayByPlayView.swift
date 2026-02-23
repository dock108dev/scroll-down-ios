import SwiftUI

/// Full chronological play-by-play view with tiered visual hierarchy
/// Tier 1: High-impact (scoring, lead changes) - Always visible, bold
/// Tier 2: Contextual (fouls, turnovers) - Visible, de-emphasized
/// Tier 3: Low-signal (misses, rebounds) - Collapsed by default
struct FullPlayByPlayView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    var initialQuarter: Int? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var collapsedPeriods: Set<Int> = []

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedPeriods, id: \.period) { group in
                            periodSection(group)
                        }

                        // Ungrouped events (pre/post game tweets)
                        if !ungroupedEvents.isEmpty {
                            Section {
                                VStack(spacing: DesignSystem.Spacing.list) {
                                    ForEach(ungroupedEvents) { event in
                                        UnifiedTimelineRowView(
                                            event: event,
                                            homeTeam: viewModel.game?.homeTeam ?? "Home",
                                            awayTeam: viewModel.game?.awayTeam ?? "Away"
                                        )
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                                .padding(.vertical, DesignSystem.Spacing.section)
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
                    let allPeriods = Set(groupedPeriods.map { $0.period })
                    if let target = initialQuarter, allPeriods.contains(target) {
                        // Expand the target quarter, collapse the rest
                        collapsedPeriods = allPeriods.subtracting([target])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut) {
                                proxy.scrollTo("pbp-period-\(target)", anchor: .top)
                            }
                        }
                    } else {
                        // All periods collapsed by default
                        collapsedPeriods = allPeriods
                    }
                }
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

    // MARK: - Period Section with Pinned Header

    private func periodSection(_ group: PeriodGroup) -> some View {
        let tieredGroups = buildTieredGroups(for: group)

        let tier1Count = tieredGroups.filter { $0.tier == .primary }.flatMap { $0.events }.count
        let tier2Count = tieredGroups.filter { $0.tier == .secondary }.flatMap { $0.events }.count
        let tier3GroupCount = tieredGroups.filter { $0.tier == .tertiary }.count

        return Section(header:
            PinnedQuarterHeader(
                title: periodTitle(group.period, events: group.events),
                subtitle: "\(tier1Count) key plays, \(tier2Count + tier3GroupCount) other",
                isExpanded: Binding(
                    get: { !collapsedPeriods.contains(group.period) },
                    set: { isExpanded in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isExpanded {
                                collapsedPeriods.remove(group.period)
                            } else {
                                collapsedPeriods.insert(group.period)
                            }
                        }
                    }
                )
            )
            .id("pbp-period-\(group.period)")
        ) {
            if !collapsedPeriods.contains(group.period) {
                LazyVStack(spacing: 6) {
                    ForEach(tieredGroups) { tieredGroup in
                        TieredPlayGroupView(
                            group: tieredGroup,
                            homeTeam: viewModel.game?.homeTeam ?? "Home",
                            awayTeam: viewModel.game?.awayTeam ?? "Away"
                        )
                    }
                }
                .quarterCardBody()
            }
        }
    }

    // MARK: - Tiered Groups

    private func buildTieredGroups(for group: PeriodGroup) -> [TieredPlayGroup] {
        if viewModel.hasServerGroupings {
            let periodPlayIndices = Set(group.events.compactMap { event -> Int? in
                guard event.id.hasPrefix("play-") else { return nil }
                return Int(event.id.dropFirst(5))
            })
            let relevantServerGroups = viewModel.serverPlayGroups.filter { serverGroup in
                !Set(serverGroup.playIndices).isDisjoint(with: periodPlayIndices)
            }
            if !relevantServerGroups.isEmpty {
                return ServerPlayGroupAdapter.convert(
                    serverGroups: relevantServerGroups,
                    events: group.events
                )
            }
        }
        return TieredPlayGrouper.group(events: group.events)
    }

    // MARK: - Period Title

    /// Returns the period title, sport-aware with server label override
    private func periodTitle(_ period: Int, events: [UnifiedTimelineEvent] = []) -> String {
        if period == 0 {
            return "Additional"
        }

        // Use server-provided label if available
        if let label = events.first?.periodLabel, !label.isEmpty {
            switch label {
            case "P1": return "Period 1"
            case "P2": return "Period 2"
            case "P3": return "Period 3"
            case "H1": return "1st Half"
            case "H2": return "2nd Half"
            default: return label
            }
        }

        let sport = viewModel.game?.leagueCode ?? "NBA"
        switch sport {
        case "NCAAB":
            switch period {
            case 1: return "1st Half"
            case 2: return "2nd Half"
            case 3: return "OT"
            default: return "\(period - 2)OT"
            }
        case "NHL":
            switch period {
            case 1...3: return "Period \(period)"
            case 4: return "OT"
            case 5: return "SO"
            default: return "\(period - 3)OT"
            }
        default:
            switch period {
            case 1...4: return "Q\(period)"
            case 5: return "OT"
            default: return "\(period - 4)OT"
            }
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
