import SwiftUI

extension GameDetailView {
    /// Primary content section title adapts to game status
    private var timelineSectionTitle: String {
        if viewModel.game?.status.isLive == true {
            return "Live PBP"
        }
        return "Game Flow"
    }

    /// Game Flow section - content adapts based on game status:
    /// - Live: show PBP as primary content
    /// - Final with flow: show Game Flow
    /// - Final without flow: show PBP (fallback)
    func timelineSection(using proxy: ScrollViewProxy) -> some View {
        CollapsibleSectionCard(title: timelineSectionTitle, isExpanded: $isFlowCardExpanded) {
            if viewModel.game?.status.isLive == true {
                // Live: PBP is primary content
                timelineContent(using: proxy)
            } else {
                // Final: Game Flow is primary
                GameFlowView(
                    viewModel: viewModel,
                    isCompactFlowExpanded: $isCompactFlowExpanded
                )
            }
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
        .onAppear {
            initializeCollapsedQuarters()
        }
    }

    /// Toggles all boundary headers (expand all or collapse all)
    private func toggleAllBoundaries() {
        let quarters = groupedQuarters.map { $0.quarter }
        if isTimelineExpanded {
            collapsedQuarters.removeAll()
        } else {
            for quarter in quarters {
                collapsedQuarters.insert(quarter)
            }
        }
    }

    private var timelineSubtitle: String {
        if viewModel.hasFlowData {
            return "Game Flow"
        }

        let events = viewModel.unifiedTimelineEvents
        if events.isEmpty {
            return "Play-by-play"
        }
        let pbpCount = events.filter { $0.eventType == .pbp }.count
        return "\(pbpCount) plays"
    }

    func timelineContent(using proxy: ScrollViewProxy) -> some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            // Priority 1: Show flow if available (flow with blocks)
            if viewModel.hasFlowData {
                GameFlowView(
                    viewModel: viewModel,
                    isCompactFlowExpanded: $isCompactFlowExpanded
                )
            }
            // Priority 2: Show PBP grouped by period (from PBP API or detail.plays)
            else if viewModel.hasPbpData {
                unifiedTimelineView
            }
            // Priority 3: Still loading flow or PBP
            else if viewModel.isLoadingAnyData {
                timelineLoadingView
            }
            // Priority 4: No content available - show Coming Soon
            else {
                comingSoonView
            }
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

    /// Sets Q2+ as collapsed by default, Q1 expanded
    private func initializeCollapsedQuarters() {
        guard !hasInitializedQuarters else { return }
        hasInitializedQuarters = true

        let quarters = groupedQuarters.map { $0.quarter }
        for quarter in quarters {
            // Only collapse Q2 and later - keep Q1 expanded
            if quarter > 1 {
                collapsedQuarters.insert(quarter)
            }
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

    /// Collapsible card for a single quarter — uses the same tiered layout as FullPlayByPlayView
    private func unifiedQuarterCard(_ group: QuarterGroup) -> some View {
        let tieredGroups: [TieredPlayGroup] = {
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
        }()

        let tier1Count = tieredGroups.filter { $0.tier == .primary }.flatMap { $0.events }.count
        let tier2Count = tieredGroups.filter { $0.tier == .secondary }.flatMap { $0.events }.count
        let tier3GroupCount = tieredGroups.filter { $0.tier == .tertiary }.count

        return CollapsibleQuarterCard(
            title: quarterTitle(group.quarter, serverLabel: group.events.first?.periodLabel),
            subtitle: "\(tier1Count) key plays, \(tier2Count + tier3GroupCount) other",
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(group.quarter) },
                set: { isExpanded in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            collapsedQuarters.remove(group.quarter)
                        } else {
                            collapsedQuarters.insert(group.quarter)
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
                        awayTeam: viewModel.game?.awayTeam ?? "Away"
                    )
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
