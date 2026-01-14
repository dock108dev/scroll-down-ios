import SwiftUI

/// DEPRECATED: This view used the old CompactMoment-based approach
/// Timeline is now rendered via UnifiedTimelineRowView from timeline_json
/// This file is kept for reference but should be deleted when cleanup is complete
@available(*, deprecated, message: "Timeline now uses unified rendering from timeline_json")
struct CompactMomentExpandedView: View {
    let moment: CompactMoment
    let service: GameService

    @StateObject private var viewModel = CompactMomentPbpViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                headerSection
                pbpSection
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.bottom, Layout.bottomPadding)
        }
        .background(GameTheme.background)
        .navigationTitle("Play-by-play")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(moment: moment, service: service)
        }
    }

    /// Empty state view with context-aware messaging
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            Text("No play-by-play data yet")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.rowPadding)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }
    
    /// Context-aware empty state message
    private var emptyStateMessage: String {
        // In a future phase, we could check game status to provide better messaging
        // For now, provide a neutral explanation
        "Play-by-play events will appear here as they become available. Some games may have delayed or partial coverage."
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            Text(moment.displayTitle)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            if let description = moment.description, description != moment.displayTitle {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: Layout.detailSpacing) {
                if let timeLabel = moment.timeLabel {
                    Label(timeLabel, systemImage: "clock")
                }
                if let team = moment.teamAbbreviation {
                    Label(team, systemImage: "sportscourt")
                }
                if let player = moment.playerName {
                    Label(player, systemImage: "person.fill")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
        }
    }

    private var pbpSection: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            Text("Play-by-play timeline")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: Layout.textSpacing) {
                    Text("Unable to load play-by-play.")
                        .font(.subheadline.weight(.semibold))
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.load(moment: moment, service: service) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.periodGroups.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: Layout.periodSpacing) {
                    ForEach(viewModel.periodGroups) { group in
                        periodSection(group: group)
                    }
                }
            }
        }
    }
    
    /// Get the index of an event in the full timeline (across all periods)
    private func indexInFullTimeline(event: PbpEvent, group: PeriodGroup) -> Int {
        // Calculate position based on all events before this period + position within period
        let eventsBefore = viewModel.periodGroups
            .filter { $0.period < group.period }
            .reduce(0) { $0 + $1.events.count }
        
        let indexInPeriod = group.events.firstIndex(where: { $0.id == event.id }) ?? 0
        return eventsBefore + indexInPeriod
    }
    
    /// Collapsible period section with pagination
    private func periodSection(group: PeriodGroup) -> some View {
        let isExpanded = !viewModel.collapsedPeriods.contains(group.period)
        
        return VStack(alignment: .leading, spacing: Layout.rowSpacing) {
            // Period header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    viewModel.togglePeriod(group.period)
                }
            } label: {
                HStack {
                    Text(group.displayLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text("(\(group.events.count) events)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if group.isLive {
                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .padding(Layout.periodHeaderPadding)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(group.displayLabel), \(group.events.count) events")
            .accessibilityHint(isExpanded ? "Tap to collapse" : "Tap to expand")
            
            // Period content (when expanded)
            if isExpanded {
                VStack(spacing: Layout.rowSpacing) {
                    let visibleEvents = viewModel.visibleEvents(for: group.period)
                    
                    ForEach(Array(visibleEvents.enumerated()), id: \.element.id) { index, event in
                        // Insert moment summary if one exists at this position
                        if let summary = viewModel.momentSummaries.first(where: { 
                            $0.position == indexInFullTimeline(event: event, group: group)
                        }) {
                            MomentSummaryCard(summary: summary)
                        }
                        
                        PbpEventRow(event: event)
                    }
                    
                    // Load more button
                    if viewModel.hasMoreEvents(for: group.period) {
                        Button {
                            viewModel.loadMoreEvents(for: group.period)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Show \(viewModel.remainingEventCount(for: group.period)) more events")
                                    .font(.subheadline.weight(.medium))
                                Image(systemName: "arrow.down.circle")
                                Spacer()
                            }
                            .foregroundColor(GameTheme.accentColor)
                            .padding(Layout.loadMorePadding)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Load \(viewModel.remainingEventCount(for: group.period)) more events")
                    }
                }
                .padding(.leading, Layout.periodContentIndent)
            }
        }
    }
}

/// Summary card - a narrative bridge between event clusters
/// These provide context without revealing outcomes
private struct MomentSummaryCard: View {
    let summary: MomentSummary
    
    var body: some View {
        HStack(spacing: Layout.summarySpacing) {
            Image(systemName: "text.quote")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(summary.text)
                .font(.subheadline.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(Layout.summaryPadding)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .opacity(0.3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play summary")
        .accessibilityValue(summary.text)
    }
}

private struct PbpEventRow: View {
    let event: PbpEvent

    var body: some View {
        HStack(alignment: .top, spacing: Layout.rowContentSpacing) {
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                // Display description without score information
                // The backend provides reveal-aware descriptions
                Text(event.displayDescription)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let player = event.playerName {
                    Text(player)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let team = event.team {
                    Text(team)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let timeLabel = event.timeLabel {
                Text(timeLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(Layout.rowPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: Layout.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play-by-play event")
        .accessibilityValue(event.displayDescription)
    }
}

private extension PbpEvent {
    /// Display description that respects reveal state
    /// Backend provides reveal-aware descriptions; client just displays them
    var displayDescription: String {
        if let description, !description.isEmpty {
            return description
        }
        if let eventType {
            return eventType.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return "Play update"
    }

    /// Time label showing period and game clock
    /// Note: Period is shown in the section header, so we only show clock here
    var timeLabel: String? {
        if let gameClock {
            return gameClock
        }
        return nil
    }
}

private enum Layout {
    static let sectionSpacing: CGFloat = 20
    static let textSpacing: CGFloat = 6
    static let detailSpacing: CGFloat = 12
    static let cardSpacing: CGFloat = 12
    static let periodSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 10
    static let rowContentSpacing: CGFloat = 12
    static let rowPadding: CGFloat = 12
    static let periodHeaderPadding: CGFloat = 12
    static let periodContentIndent: CGFloat = 8
    static let loadMorePadding: CGFloat = 12
    static let summarySpacing: CGFloat = 10
    static let summaryPadding: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
    static let horizontalPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 24
}

#Preview {
    let moment = PreviewFixtures.highlightsHeavyGame.compactMoments?.first
        ?? CompactMoment(
            id: .int(1),
            period: 1,
            gameClock: "12:00",
            title: "Opening tip",
            description: "Opening tip sets the tempo early.",
            teamAbbreviation: "BOS",
            playerName: "Jayson Tatum"
        )

    NavigationStack {
        CompactMomentExpandedView(moment: moment, service: MockGameService())
    }
    .preferredColorScheme(.dark)
}
