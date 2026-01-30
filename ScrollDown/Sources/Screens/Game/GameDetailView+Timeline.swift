import SwiftUI

extension GameDetailView {
    func timelineSection(using proxy: ScrollViewProxy) -> some View {
        CollapsibleSectionCard(
            title: "Timeline",
            subtitle: timelineSubtitle,
            isExpanded: $isTimelineExpanded,
            onHeaderTap: { toggleAllBoundaries() }
        ) {
            timelineContent(using: proxy)
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TimelineFramePreferenceKey.self,
                    value: proxy.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))
                )
            }
        )
        .accessibilityElement(children: .contain)
    }

    /// Toggles all boundary headers (expand all or collapse all)
    /// When expanding Timeline: expand all boundaries
    /// When collapsing Timeline: collapse all boundaries
    private func toggleAllBoundaries() {
        let quarters = groupedQuarters.map { $0.quarter }
        if isTimelineExpanded {
            // Timeline is now expanded, so expand all boundaries
            collapsedQuarters.removeAll()
        } else {
            // Timeline is now collapsed, so collapse all boundaries
            for quarter in quarters {
                collapsedQuarters.insert(quarter)
            }
        }
    }

    private var timelineSubtitle: String {
        if viewModel.hasStoryData {
            let momentCount = viewModel.momentDisplayModels.count
            let highlightCount = viewModel.momentDisplayModels.filter { $0.isHighlight }.count
            if highlightCount > 0 {
                return "\(momentCount) moments • \(highlightCount) highlights"
            }
            return "\(momentCount) moments"
        }

        let events = viewModel.unifiedTimelineEvents
        if events.isEmpty {
            return "Play-by-play"
        }
        let pbpCount = events.filter { $0.eventType == .pbp }.count
        let tweetCount = events.filter { $0.eventType == .tweet }.count
        if tweetCount > 0 {
            return "\(pbpCount) plays • \(tweetCount) posts"
        }
        return "\(pbpCount) plays"
    }

    func timelineContent(using proxy: ScrollViewProxy) -> some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            // Priority 1: Show story if available (story with moments)
            if viewModel.hasStoryData {
                GameStoryView(
                    viewModel: viewModel,
                    isCompactStoryExpanded: $isCompactStoryExpanded
                )
            }
            // Priority 2: Show PBP grouped by period (from PBP API or detail.plays)
            else if viewModel.hasPbpData {
                unifiedTimelineView
            }
            // Priority 3: Still loading story or PBP
            else if viewModel.isLoadingAnyData {
                timelineLoadingView
            }
            // Priority 4: No content available - show Coming Soon
            else {
                comingSoonView
            }
        }
        .onAppear {
            initializeCollapsedQuarters()
        }
    }

    private var timelineLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading timeline...")
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var comingSoonView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundColor(Color(.tertiaryLabel))
            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(Color(.secondaryLabel))
            Text("Play-by-play data is being processed")
                .font(.caption)
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    /// Sets all quarters as collapsed by default
    private func initializeCollapsedQuarters() {
        guard !hasInitializedQuarters else { return }
        hasInitializedQuarters = true

        let quarters = groupedQuarters.map { $0.quarter }
        for quarter in quarters {
            collapsedQuarters.insert(quarter)
        }
    }

    // MARK: - Unified Timeline (Grouped by Quarter)

    private var unifiedTimelineView: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            ForEach(groupedQuarters, id: \.quarter) { group in
                unifiedQuarterCard(group)
            }

            if !ungroupedTweets.isEmpty {
                ForEach(ungroupedTweets) { event in
                    UnifiedTimelineRowView(
                        event: event,
                        homeTeam: viewModel.game?.homeTeam ?? "Home",
                        awayTeam: viewModel.game?.awayTeam ?? "Away"
                    )
                }
            }
        }
    }

    /// Groups events by quarter/period
    private var groupedQuarters: [QuarterGroup] {
        let events = viewModel.unifiedTimelineEvents
        var groups: [Int: [UnifiedTimelineEvent]] = [:]

        for event in events {
            let period = event.period ?? 0
            if period > 0 {
                groups[period, default: []].append(event)
            }
        }

        return groups.keys.sorted().map { quarter in
            QuarterGroup(quarter: quarter, events: groups[quarter] ?? [])
        }
    }

    /// Tweets without a period (pre/post game)
    private var ungroupedTweets: [UnifiedTimelineEvent] {
        viewModel.unifiedTimelineEvents.filter { $0.period == nil && $0.eventType == .tweet }
    }

    /// Collapsible card for a single quarter
    private func unifiedQuarterCard(_ group: QuarterGroup) -> some View {
        CollapsibleQuarterCard(
            title: "\(quarterTitle(group.quarter)) (\(group.events.count) plays)",
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(group.quarter) },
                set: { isExpanded in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            collapsedQuarters.remove(group.quarter)
                        } else {
                            collapsedQuarters.insert(group.quarter)
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
                    .id(event.id)
                }
            }
        }
        .id("quarter-\(group.quarter)")
    }
}

/// Helper struct for grouping events by quarter
private struct QuarterGroup {
    let quarter: Int
    let events: [UnifiedTimelineEvent]
}
