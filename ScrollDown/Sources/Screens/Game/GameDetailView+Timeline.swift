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
            timelineArtifactStatusView
            
            // UNIFIED TIMELINE: Render from timeline_json in server-provided order
            if viewModel.hasUnifiedTimeline {
                unifiedTimelineView
            } else {
                // Fallback to legacy quarters if timeline_json is empty
                legacyTimelineView(using: proxy)
            }
        }
    }
    
    // MARK: - Unified Timeline (Single Source of Truth)
    
    /// Renders events in server-provided order from plays data
    /// Branches only on event_type (pbp vs tweet)
    private var unifiedTimelineView: some View {
        LazyVStack(spacing: GameDetailLayout.compactCardSpacing) {
            ForEach(viewModel.unifiedTimelineEvents) { event in
                UnifiedTimelineRowView(
                    event: event,
                    homeTeam: viewModel.game?.homeTeam ?? "Home",
                    awayTeam: viewModel.game?.awayTeam ?? "Away"
                )
                .id(event.id)
            }
        }
    }
    
    // MARK: - Legacy Timeline (Fallback)
    
    /// Fallback to client-side grouped quarters if timeline_json is empty
    @available(*, deprecated, message: "Use unifiedTimelineView when timeline_json is available")
    private func legacyTimelineView(using proxy: ScrollViewProxy) -> some View {
        VStack(spacing: GameDetailLayout.cardSpacing) {
            if let liveMarker = viewModel.liveScoreMarker {
                TimelineScoreChipView(marker: liveMarker)
            }

            ForEach(viewModel.timelineQuarters) { quarter in
                quarterSection(quarter, using: proxy)
            }

            if viewModel.timelineQuarters.isEmpty {
                EmptySectionView(text: "No play-by-play data available.")
            }
        }
    }

    func quarterSection(
        _ quarter: QuarterTimeline,
        using proxy: ScrollViewProxy
    ) -> some View {
        CollapsibleQuarterCard(
            title: "\(quarterTitle(quarter.quarter)) (\(quarter.plays.count) plays)",
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(quarter.quarter) },
                set: { isExpanded in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        if isExpanded {
                            collapsedQuarters.remove(quarter.quarter)
                        } else {
                            collapsedQuarters.insert(quarter.quarter)
                        }
                    }
                    if isExpanded {
                        scrollToQuarterHeader(quarter.quarter, using: proxy)
                    }
                }
            )
        ) {
            VStack(spacing: GameDetailLayout.cardSpacing) {
                ForEach(quarter.plays) { play in
                    if let highlights = viewModel.highlightByPlayIndex[play.playIndex] {
                        ForEach(highlights) { highlight in
                            HighlightCardView(post: highlight)
                        }
                    }

                    TimelineRowView(play: play)
                        .id("play-\(play.playIndex)")
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: PlayRowFramePreferenceKey.self,
                                    value: [play.playIndex: proxy.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
                                )
                            }
                        )

                    if let marker = viewModel.scoreMarker(for: play) {
                        TimelineScoreChipView(marker: marker)
                    }
                }
            }
            .padding(.top, GameDetailLayout.listSpacing)
        }
        .id(quarterAnchorId(quarter.quarter))
    }

    @ViewBuilder
    private var timelineArtifactStatusView: some View {
        switch viewModel.timelineArtifactState {
        case .idle:
            EmptyView()
        case .loading:
            Text(TimelineVerificationConstants.loadingText)
                .font(.caption)
                .foregroundColor(.secondary)
        case .failed(let message):
            Text(String(format: TimelineVerificationConstants.failureText, message))
                .font(.caption)
                .foregroundColor(.secondary)
        case .loaded:
            if let summary = viewModel.timelineArtifactSummary {
                VStack(alignment: .leading, spacing: GameDetailLayout.textSpacing) {
                    Text(String(format: TimelineVerificationConstants.countText, summary.eventCount))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    if let firstTimestamp = summary.firstTimestamp {
                        Text(String(format: TimelineVerificationConstants.firstTimestampText, firstTimestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let lastTimestamp = summary.lastTimestamp {
                        Text(String(format: TimelineVerificationConstants.lastTimestampText, lastTimestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text(TimelineVerificationConstants.missingTimelineText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private enum TimelineVerificationConstants {
    static let loadingText = "Loading timeline artifact…"
    static let failureText = "Timeline artifact load failed: %@"
    static let countText = "Timeline events: %d"
    static let firstTimestampText = "First timestamp: %@"
    static let lastTimestampText = "Last timestamp: %@"
    static let missingTimelineText = "Timeline artifact loaded (timeline_json missing)."
}
