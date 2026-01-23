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
        // Use sections-based subtitle when story data is available
        if viewModel.hasStoryData {
            let sectionCount = viewModel.sections.count
            let highlightCount = viewModel.highlightSections.count
            if highlightCount > 0 {
                return "\(sectionCount) sections • \(highlightCount) highlights"
            }
            return "\(sectionCount) sections"
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
            // Compact story: AI-generated narrative
            if let compactStory = viewModel.compactStory {
                compactStorySection(compactStory)
            }

            // Story sections: primary rendering
            if viewModel.hasStoryData {
                storySectionsTimelineView
            }
            // Unified timeline: raw PBP + tweets when no story
            else if viewModel.hasUnifiedTimeline {
                unifiedTimelineView
            } else {
                EmptySectionView(text: "No timeline data available.")
            }
        }
        .onAppear {
            if viewModel.hasStoryData {
                initializeCollapsedSections()
            } else {
                initializeCollapsedQuarters()
            }
        }
        .onChange(of: viewModel.sections.count) { _ in
            if viewModel.hasStoryData && !hasInitializedSections {
                initializeCollapsedSections()
            }
        }
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

    /// Sets all sections as collapsed by default
    private func initializeCollapsedSections() {
        guard !hasInitializedSections else { return }
        hasInitializedSections = true

        for section in viewModel.sections {
            collapsedSections.insert(section.id)
        }
    }

    // MARK: - Compact Story Section

    /// AI-generated game narrative (shown above timeline)
    private func compactStorySection(_ story: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.caption)
                Text("Game Story")
                    .font(.caption.weight(.semibold))

                Spacer()

                if let quality = viewModel.storyQuality {
                    Text(quality.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(DesignSystem.TextColor.secondary)

            Text(story)
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.primary)
                .lineLimit(isCompactStoryExpanded ? nil : 3)

            if story.count > 200 {
                Button(isCompactStoryExpanded ? "Show Less" : "Read More") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompactStoryExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.accent)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.cardBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - Story Sections Timeline

    /// Timeline view grouped by story sections
    private var storySectionsTimelineView: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            ForEach(sortedSectionPeriods, id: \.self) { period in
                sectionPeriodGroup(period: period)
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

    /// Sorted list of periods that have sections
    private var sortedSectionPeriods: [Int] {
        Array(viewModel.sectionsByPeriod.keys).sorted()
    }

    /// Section for a single period containing its story sections
    private func sectionPeriodGroup(period: Int) -> some View {
        let periodSections = viewModel.sectionsByPeriod[period] ?? []
        let highlightCount = periodSections.filter { $0.isHighlight }.count

        return CollapsibleQuarterCard(
            title: periodSectionTitle(period: period, sectionCount: periodSections.count, highlightCount: highlightCount),
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(period) },
                set: { isExpanded in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if isExpanded {
                            collapsedQuarters.remove(period)
                        } else {
                            collapsedQuarters.insert(period)
                        }
                    }
                }
            )
        ) {
            VStack(spacing: DesignSystem.Spacing.list) {
                ForEach(periodSections) { section in
                    StorySectionCardView(
                        section: section,
                        plays: viewModel.unifiedEventsForSection(section),
                        homeTeam: viewModel.game?.homeTeam ?? "Home",
                        awayTeam: viewModel.game?.awayTeam ?? "Away",
                        isExpanded: sectionExpandedBinding(for: section)
                    )
                }
            }
        }
        .id("period-sections-\(period)")
    }

    /// Title for period section showing section and highlight counts
    private func periodSectionTitle(period: Int, sectionCount: Int, highlightCount: Int) -> String {
        let periodName = quarterTitle(period)
        if highlightCount > 0 {
            return "\(periodName) (\(sectionCount) sections, \(highlightCount) highlights)"
        }
        return "\(periodName) (\(sectionCount) sections)"
    }

    /// Binding for section expansion state
    private func sectionExpandedBinding(for section: SectionEntry) -> Binding<Bool> {
        Binding(
            get: { !collapsedSections.contains(section.id) },
            set: { isExpanded in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        collapsedSections.remove(section.id)
                    } else {
                        collapsedSections.insert(section.id)
                    }
                }
            }
        )
    }

    // MARK: - Unified Timeline (Grouped by Quarter)

    /// Groups events by quarter with all collapsed by default
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
