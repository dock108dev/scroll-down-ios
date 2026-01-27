import SwiftUI

extension GameDetailView {
    func timelineSection(using proxy: ScrollViewProxy) -> some View {
        CollapsibleSectionCard(
            title: "Timeline",
            subtitle: timelineSubtitle,
            isExpanded: $isTimelineExpanded
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
            // Game Story View for completed games with story data
            if viewModel.shouldShowStoryView {
                GameStoryView(
                    viewModel: viewModel,
                    isCompactStoryExpanded: $isCompactStoryExpanded
                )
            }
            // Show unified timeline while story loads or if story not available
            else if viewModel.hasUnifiedTimeline {
                if viewModel.storyState == .loading {
                    storyLoadingBanner
                }
                unifiedTimelineView
            } else if viewModel.storyState == .loading {
                timelineLoadingView
            } else {
                EmptySectionView(text: "No timeline data available.")
            }
        }
        .onAppear {
            initializeCollapsedQuarters()
        }
    }

    private var storyLoadingBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading enhanced timeline...")
                .font(.caption)
                .foregroundColor(DesignSystem.TextColor.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
