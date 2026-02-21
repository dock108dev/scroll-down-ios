import SwiftUI

extension GameDetailView {
    /// Returns the period/quarter title, sport-aware.
    /// NCAAB: "1st Half", "2nd Half", "OT"; NHL: "Period 1", "Period 2", "Period 3", "OT"; NBA: "Q1"-"Q4", "OT"
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
        let sport = viewModel.game?.leagueCode ?? "NBA"
        switch sport {
        case "NCAAB":
            switch quarter {
            case 1: return "1st Half"
            case 2: return "2nd Half"
            case 3: return "OT"
            default: return "\(quarter - 2)OT"
            }
        case "NHL":
            switch quarter {
            case 1...3: return "Period \(quarter)"
            case 4: return "OT"
            case 5: return "SO"
            default: return "\(quarter - 3)OT"
            }
        default: // NBA and others
            switch quarter {
            case 1...4: return "Q\(quarter)"
            case 5: return "OT"
            default: return "\(quarter - 4)OT"
            }
        }
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
        guard let quarter = play.quarter else {
            return "Game"
        }

        let ordinal = quarterOrdinal(quarter)
        guard let clock = play.gameClock,
              let minutesRemaining = Int(clock.split(separator: ":").first ?? "") else {
            return ordinal
        }

        let phase = periodPhaseLabel(minutesRemaining: minutesRemaining)
        return "\(phase) \(ordinal)"
    }

    func periodPhaseLabel(minutesRemaining: Int) -> String {
        switch minutesRemaining {
        case 8...:
            return "Early"
        case 4..<8:
            return "Mid"
        default:
            return "Late"
        }
    }

    func quarterOrdinal(_ quarter: Int) -> String {
        let sport = viewModel.game?.leagueCode ?? "NBA"
        switch sport {
        case "NCAAB":
            switch quarter {
            case 1: return "1st Half"
            case 2: return "2nd Half"
            case 3: return "OT"
            default: return "\(quarter - 2)OT"
            }
        case "NHL":
            switch quarter {
            case 1...3: return "P\(quarter)"
            case 4: return "OT"
            default: return "\(quarter - 3)OT"
            }
        default:
            switch quarter {
            case 1: return "1st"
            case 2: return "2nd"
            case 3: return "3rd"
            case 4: return "4th"
            case 0: return "OT"
            default: return "\(quarter)th"
            }
        }
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

    func resumePromptView(onResume: @escaping () -> Void, onStartOver: @escaping () -> Void) -> some View {
        VStack(spacing: GameDetailLayout.resumePromptSpacing) {
            Text("Resume where you left off?")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: GameDetailLayout.resumeButtonSpacing) {
                Button("Start over") {
                    onStartOver()
                }
                .buttonStyle(.bordered)
                Button("Resume") {
                    onResume()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(GameDetailLayout.resumePromptPadding)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resume where you left off?")
    }

    func resumeScroll(using proxy: ScrollViewProxy) {
        guard let savedResumePlayIndex else {
            shouldShowResumePrompt = false
            isResumeTrackingEnabled = true
            return
        }
        isTimelineExpanded = true
        selectedSection = .timeline
        expandQuarter(for: savedResumePlayIndex)
        withAnimation(.easeInOut) {
            proxy.scrollTo("play-\(savedResumePlayIndex)", anchor: .top)
        }
        shouldShowResumePrompt = false
        isResumeTrackingEnabled = true
    }

    func startOver(using proxy: ScrollViewProxy) {
        clearSavedResumeMarker()
        shouldShowResumePrompt = false
        isResumeTrackingEnabled = true
        withAnimation(.easeInOut) {
            proxy.scrollTo(GameSection.header, anchor: .top)
        }
    }

    func expandQuarter(for playIndex: Int) {
        guard let quarter = viewModel.detail?.plays.first(where: { $0.playIndex == playIndex })?.quarter else {
            return
        }
        collapsedQuarters.remove(quarter)
    }

    func loadResumeMarkerIfNeeded() {
        guard !hasLoadedResumeMarker else { return }
        guard viewModel.detail != nil else { return }
        hasLoadedResumeMarker = true
        guard let position = ReadingPositionStore.shared.load(gameId: gameId) else { return }

        // Always restore displayed scores first — independent of play-index validity
        if let away = position.awayScore, let home = position.homeScore {
            displayedAwayScore = away
            displayedHomeScore = home
        }

        // Validate play index for resume-scroll prompt
        let storedPlayIndex = position.playIndex
        guard viewModel.detail?.plays.contains(where: { $0.playIndex == storedPlayIndex }) == true else {
            // Play index doesn't match current PBP data (e.g. playIndex: 0 from hold-to-reveal).
            // Skip resume prompt but keep the saved position so scores persist.
            return
        }
        savedResumePlayIndex = storedPlayIndex
        shouldShowResumePrompt = true
        isResumeTrackingEnabled = false
    }

    func updateResumeMarkerIfNeeded() {
        guard isResumeTrackingEnabled else { return }
        guard let play = currentViewingPlay else { return }
        let playIndex = play.playIndex
        guard playIndex != savedResumePlayIndex else { return }
        savedResumePlayIndex = playIndex

        let periodLabel: String? = {
            guard let quarter = play.quarter else { return nil }
            return quarterOrdinal(quarter)
        }()
        let timeLabel: String? = {
            guard let quarter = play.quarter else { return nil }
            let ordinal = quarterOrdinal(quarter)
            if let clock = play.gameClock {
                return "\(ordinal) \(clock)"
            }
            return ordinal
        }()
        let position = ReadingPosition(
            playIndex: playIndex,
            period: play.quarter,
            gameClock: play.gameClock,
            periodLabel: periodLabel,
            timeLabel: timeLabel,
            savedAt: Date(),
            homeScore: play.homeScore,
            awayScore: play.awayScore
        )
        ReadingPositionStore.shared.save(gameId: gameId, position: position)

        // Update displayed scores as user scrolls (only when scores are present)
        if let away = play.awayScore, let home = play.homeScore {
            displayedAwayScore = away
            displayedHomeScore = home
        }
    }

    func clearSavedResumeMarker() {
        savedResumePlayIndex = nil
        ReadingPositionStore.shared.clear(gameId: gameId)
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
    
    // MARK: - Section Anchors

    /// Creates an invisible anchor view for scroll-to-section functionality
    /// The anchor is positioned at the top of each section for reliable scrollTo targeting
    /// Uses anchorId to avoid ID conflicts with navigation buttons
    func sectionAnchor(for section: GameSection) -> some View {
        Color.clear
            .frame(height: 1)
            .id(section.anchorId)
            .accessibilityHidden(true)
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
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        }
    }
}
