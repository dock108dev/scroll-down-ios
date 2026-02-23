import SwiftUI

extension GameDetailView {
    /// Primary content section title adapts to game status
    private var timelineSectionTitle: String {
        if viewModel.game?.status.isLive == true {
            return "Live PBP"
        }
        return "Game Flow"
    }

    /// Whether the PBP quarters should be separate pinned sections
    private var usesPinnedQuarters: Bool {
        guard isFlowCardExpanded else { return false }
        if viewModel.game?.status.isLive == true {
            return viewModel.hasPbpData
        }
        // Non-live without flow falls back to PBP
        return !viewModel.hasFlowData && viewModel.hasPbpData
    }

    /// Game Flow / Live PBP sections.
    /// For PBP, quarter sections are output at the same LazyVStack level
    /// so their headers can pin to the top of the scroll view.
    @ViewBuilder
    func timelineSections(using proxy: ScrollViewProxy) -> some View {
        // Main section header ("Live PBP" / "Game Flow")
        Section(header:
            PinnedSectionHeader(title: timelineSectionTitle, isExpanded: $isFlowCardExpanded)
                .id(GameSection.timeline.anchorId)
                .background(GameTheme.background)
        ) {
            if isFlowCardExpanded {
                if !usesPinnedQuarters {
                    // Flow content (or loading/empty states) stays inline
                    flowOrFallbackContent(using: proxy)
                        .sectionCardBody()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: TimelineFramePreferenceKey.self,
                                    value: geo.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))
                                )
                            }
                        )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            initializeCollapsedQuarters()
        }

        // PBP quarter sections — pinned headers at the same LazyVStack level
        if usesPinnedQuarters {
            ForEach(groupedQuarters, id: \.quarter) { group in
                pinnedQuarterSection(group)
            }

            if !ungroupedTweets.isEmpty {
                Section {
                    VStack(spacing: DesignSystem.Spacing.list) {
                        ForEach(ungroupedTweets) { event in
                            UnifiedTimelineRowView(
                                event: event,
                                homeTeam: viewModel.game?.homeTeam ?? "Home",
                                awayTeam: viewModel.game?.awayTeam ?? "Away"
                            )
                        }
                    }
                    .sectionCardBody()
                }
            }
        }
    }

    /// Flow content or non-PBP fallback (loading, coming soon)
    @ViewBuilder
    private func flowOrFallbackContent(using proxy: ScrollViewProxy) -> some View {
        if viewModel.hasFlowData {
            GameFlowView(
                viewModel: viewModel,
                isCompactFlowExpanded: $isCompactFlowExpanded
            )
        } else if viewModel.isLoadingAnyData {
            timelineLoadingView
        } else {
            comingSoonView
        }
    }

    /// A single quarter as a pinned section
    private func pinnedQuarterSection(_ group: QuarterGroup) -> some View {
        let tieredGroups = buildTieredGroups(for: group)
        let tier1Count = tieredGroups.filter { $0.tier == .primary }.flatMap { $0.events }.count
        let tier2Count = tieredGroups.filter { $0.tier == .secondary }.flatMap { $0.events }.count
        let tier3GroupCount = tieredGroups.filter { $0.tier == .tertiary }.count

        return Section(header:
            PinnedQuarterHeader(
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
            )
            .id("quarter-\(group.quarter)")
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: PlayRowFramePreferenceKey.self,
                        value: [-(10000 + group.quarter): geo.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
                    )
                }
            )
        ) {
            if !collapsedQuarters.contains(group.quarter) {
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

    /// Build tiered groups for a quarter (shared between inline and legacy paths)
    private func buildTieredGroups(for group: QuarterGroup) -> [TieredPlayGroup] {
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
            Text("Play by play data is being processed")
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

    /// Groups events by quarter/period
    var groupedQuarters: [QuarterGroup] {
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
    var ungroupedTweets: [UnifiedTimelineEvent] {
        viewModel.unifiedTimelineEvents.filter { $0.period == nil && $0.eventType == .tweet }
    }

    // MARK: - Full PBP View (Popup)

    /// Collapsible card for a single quarter — used in contexts without pinned headers
    private func unifiedQuarterCard(_ group: QuarterGroup) -> some View {
        let tieredGroups = buildTieredGroups(for: group)

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
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: PlayRowFramePreferenceKey.self,
                    value: [-(10000 + group.quarter): geo.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
                )
            }
        )
    }
}

/// Helper struct for grouping events by quarter
struct QuarterGroup {
    let quarter: Int
    let events: [UnifiedTimelineEvent]
}
