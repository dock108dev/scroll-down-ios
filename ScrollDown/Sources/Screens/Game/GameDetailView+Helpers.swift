import SwiftUI

extension GameDetailView {
    /// Returns the period/quarter title from the API-provided server label.
    func quarterTitle(_ quarter: Int, serverLabel: String? = nil) -> String {
        if quarter == 0 {
            return "Additional"
        }
        if let label = serverLabel, !label.isEmpty {
            // Expand abbreviated server labels for readability
            switch label {
            case "H1": return "1st Half"
            case "H2": return "2nd Half"
            case "P1": return "Period 1"
            case "P2": return "Period 2"
            case "P3": return "Period 3"
            default: return label
            }
        }
        return "Period \(quarter)"
    }

    var viewingPillText: String? {
        guard isTimelineVisible else {
            return nil
        }

        guard let play = currentViewingPlay,
              let scoreText = scoreDisplay(for: play) else {
            return nil
        }

        return "\(periodDescriptor(for: play)) | \(scoreText)"
    }

    var isTimelineVisible: Bool {
        timelineFrame.height > 0 && scrollViewFrame.height > 0 && timelineFrame.intersects(scrollViewFrame)
    }

    var currentViewingPlay: PlayEntry? {
        guard scrollViewFrame.height > 0 else {
            return nil
        }

        let playsByIndex = Dictionary(
            uniqueKeysWithValues: (viewModel.detail?.plays ?? []).map { ($0.playIndex, $0) }
        )

        let visiblePlays = playRowFrames.compactMap { playIndex, frame -> (PlayEntry, CGRect)? in
            guard let play = playsByIndex[playIndex],
                  frame.maxY >= scrollViewFrame.minY,
                  frame.minY <= scrollViewFrame.maxY else {
                return nil
            }
            return (play, frame)
        }

        return visiblePlays
            .sorted { $0.1.minY < $1.1.minY }
            .last?
            .0
    }

    func periodDescriptor(for play: PlayEntry) -> String {
        if let label = play.periodLabel, !label.isEmpty {
            if let phase = play.phase, !phase.isEmpty {
                return "\(phase) \(label)"
            }
            return label
        }
        guard let quarter = play.quarter else {
            return "Game"
        }
        return "Q\(quarter)"
    }

    func scoreDisplay(for play: PlayEntry) -> String? {
        guard let away = play.awayScore, let home = play.homeScore else {
            return nil
        }

        return "\(away)–\(home)"
    }

    func viewingPillView(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, GameDetailLayout.viewingPillHorizontalPadding)
            .padding(.vertical, GameDetailLayout.viewingPillVerticalPadding)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    func expandQuarter(for playIndex: Int) {
        guard let quarter = viewModel.detail?.plays.first(where: { $0.playIndex == playIndex })?.quarter else {
            return
        }
        collapsedQuarters.remove(quarter)
    }

    func scrollToQuarterHeader(_ quarter: Int, using proxy: ScrollViewProxy) {
        let anchorId = quarterAnchorId(quarter)
        DispatchQueue.main.async {
            proxy.scrollTo(anchorId, anchor: .top)
        }
    }

    func quarterAnchorId(_ quarter: Int) -> String {
        "quarter-\(quarter)"
    }

    /// Game summary view - renders pre-generated summary from server
    /// No async loading, retry, or AI generation semantics
    var summaryView: some View {
        Group {
            switch viewModel.summaryState {
            case .unavailable:
                // Static unavailable state - summaries are pre-generated, no retry
                EmptySectionView(text: "Recap unavailable for this game.")
            case .available(let summary):
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: GameDetailLayout.summaryMinHeight, alignment: .leading)
        .accessibilityLabel("Game recap")
        .accessibilityValue(summaryAccessibilityValue)
    }

    var summaryAccessibilityValue: String {
        switch viewModel.summaryState {
        case .available(let summary):
            return summary
        case .unavailable:
            return "Recap unavailable"
        }
    }

    /// Sections that have content to display
    var visibleSections: [GameSection] {
        var sections: [GameSection] = []

        // Pregame - only if there are pregame social posts
        if !viewModel.pregameSocialPosts.isEmpty {
            sections.append(.overview)
        }

        // Game Flow / Live PBP - show when flow data exists or for live games with PBP
        if viewModel.hasFlowData || (viewModel.game?.status.isLive == true && viewModel.hasPbpData) {
            sections.append(.timeline)
        }

        // Player Stats - if we have player stats data
        if !viewModel.playerStats.isEmpty {
            sections.append(.playerStats)
        }

        // Team Stats - if we have team stats data
        if !viewModel.teamStats.isEmpty {
            sections.append(.teamStats)
        }

        // Odds - if we have odds data
        if viewModel.hasOddsData {
            sections.append(.odds)
        }

        // Wrap-up - only for truly completed games (with confirmation signals)
        if viewModel.isGameTrulyCompleted {
            sections.append(.final)
        }

        return sections
    }

    func sectionNavigationBar(onSelect: @escaping (GameSection) -> Void) -> some View {
        HStack(spacing: 0) {
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(visibleSections, id: \.self) { section in
                            Button {
                                onSelect(section)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(section.title)
                                        .font(.subheadline.weight(selectedSection == section ? .semibold : .regular))
                                        .foregroundColor(selectedSection == section ? .primary : Color(.tertiaryLabel))

                                    // Subtle underline indicator
                                    Rectangle()
                                        .fill(selectedSection == section ? Color(.label) : Color.clear)
                                        .frame(height: 1.5)
                                        .animation(.easeInOut(duration: 0.2), value: selectedSection)
                                }
                            }
                            .id(section)
                            .accessibilityLabel("Jump to \(section.title)")
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: selectedSection) { _, newSection in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollProxy.scrollTo(newSection, anchor: .center)
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Section navigation")
            }

            if viewModel.hasPbpData || viewModel.hasUnifiedTimeline {
                Spacer(minLength: 8)

                Button {
                    showingFullPlayByPlay = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.caption2)
                        Text("PBP")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(DesignSystem.Colors.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Colors.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingFullPlayByPlay) {
                    FullPlayByPlayView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Section Frame Tracking

    func sectionFrameTracker(for section: GameSection) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: SectionFramePreferenceKey.self,
                value: [section: geo.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))]
            )
        }
    }
    
    func updateSelectedSectionFromScroll() {
        // Skip scroll-based updates during manual tab selection
        guard !isManualTabSelection else { return }

        // Find the section whose top is closest to the top of the visible area
        // with a threshold to prevent jitter
        let threshold: CGFloat = 100

        var bestSection: GameSection?
        var bestDistance: CGFloat = .infinity

        for section in GameSection.navigationSections {
            guard let frame = sectionFrames[section] else { continue }

            // Distance from section top to viewport top
            let distance = frame.minY

            // Prefer sections that are at or just past the top
            if distance < threshold && distance > -frame.height * 0.5 {
                let absDistance = abs(distance)
                if absDistance < bestDistance {
                    bestDistance = absDistance
                    bestSection = section
                }
            }
        }

        // Find most visible section if none near top
        if bestSection == nil {
            for section in GameSection.navigationSections {
                guard let frame = sectionFrames[section] else { continue }

                // Section is visible if its top is above viewport bottom
                if frame.minY < scrollViewFrame.height {
                    let distance = abs(frame.minY)
                    if distance < bestDistance {
                        bestDistance = distance
                        bestSection = section
                    }
                }
            }
        }

        if let section = bestSection, section != selectedSection {
            // No animation during scroll — avoids layout thrash and jitter
            selectedSection = section
        }
    }
}
