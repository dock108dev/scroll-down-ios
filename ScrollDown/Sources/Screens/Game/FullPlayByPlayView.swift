import SwiftUI

/// Full chronological play-by-play view
/// Accessible via "View All Plays" button from GameStoryView
/// Shows all plays organized by quarter/period with expandable sections
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
                // Initialize all periods as expanded (none collapsed)
                collapsedPeriods = []
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

    // MARK: - Period Card

    private func periodCard(_ group: PeriodGroup) -> some View {
        CollapsibleQuarterCard(
            title: "\(periodTitle(group.period)) (\(group.events.count) plays)",
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
            VStack(spacing: DesignSystem.Spacing.list) {
                ForEach(group.events) { event in
                    UnifiedTimelineRowView(
                        event: event,
                        homeTeam: viewModel.game?.homeTeam ?? "Home",
                        awayTeam: viewModel.game?.awayTeam ?? "Away"
                    )
                }
            }
        }
    }

    // MARK: - Period Title

    /// Returns the appropriate period/quarter title based on sport
    private func periodTitle(_ period: Int) -> String {
        if period == 0 {
            return "Additional"
        }

        // NHL uses "Period" terminology
        if viewModel.isNHL {
            if period > 3 {
                return period == 4 ? "OT" : "OT\(period - 3)"
            }
            return "Period \(period)"
        }

        // NBA/NCAAB/other sports use "Q" for quarters
        if period > 4 {
            return period == 5 ? "OT" : "OT\(period - 4)"
        }
        return "Q\(period)"
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
