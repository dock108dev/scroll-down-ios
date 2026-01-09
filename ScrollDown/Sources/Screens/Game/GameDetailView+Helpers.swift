import SwiftUI

extension GameDetailView {
    func quarterTitle(_ quarter: Int) -> String {
        quarter == 0 ? "Additional" : "Q\(quarter)"
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
        switch quarter {
        case 1:
            return "1st"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        case 4:
            return "4th"
        case 0:
            return "OT"
        default:
            return "\(quarter)th"
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
        guard !hasLoadedResumeMarker else {
            return
        }
        guard viewModel.detail != nil else {
            return
        }
        hasLoadedResumeMarker = true
        guard let storedPlayIndex = UserDefaults.standard.object(forKey: resumeMarkerKey) as? Int else {
            return
        }
        guard viewModel.detail?.plays.contains(where: { $0.playIndex == storedPlayIndex }) == true else {
            clearSavedResumeMarker()
            return
        }
        savedResumePlayIndex = storedPlayIndex
        shouldShowResumePrompt = true
        isResumeTrackingEnabled = false
    }

    func updateResumeMarkerIfNeeded() {
        guard isResumeTrackingEnabled else {
            return
        }
        guard let play = currentViewingPlay else {
            return
        }
        let playIndex = play.playIndex
        guard playIndex != savedResumePlayIndex else {
            return
        }
        savedResumePlayIndex = playIndex
        UserDefaults.standard.set(playIndex, forKey: resumeMarkerKey)
    }

    func clearSavedResumeMarker() {
        savedResumePlayIndex = nil
        UserDefaults.standard.removeObject(forKey: resumeMarkerKey)
    }

    var resumeMarkerKey: String {
        "game.resume.playIndex.\(gameId)"
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

    var aiSummaryView: some View {
        Group {
            switch viewModel.summaryState {
            case .loading:
                // Phase F: Loading skeleton instead of spinner
                LoadingSkeletonView(style: .textBlock)
            case .failed:
                // Phase F: Improved error state
                EmptySectionView(
                    text: "Summary unavailable right now. Tap to retry.",
                    icon: "exclamationmark.triangle"
                )
                .onTapGesture {
                        Task { await viewModel.loadSummary(gameId: gameId, service: appConfig.gameService) }
                }
            case .loaded(let summary):
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: GameDetailLayout.summaryMinHeight, alignment: .leading)
        .accessibilityLabel("Summary")
        .accessibilityValue(summaryAccessibilityValue)
    }

    var summaryAccessibilityValue: String {
        switch viewModel.summaryState {
        case .loaded(let summary):
            return summary
        case .failed:
            return "Summary unavailable"
        case .loading:
            return "Loading summary"
        }
    }

    func sectionNavigationBar(onSelect: @escaping (GameSection) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GameDetailLayout.navigationSpacing) {
                ForEach(GameSection.navigationSections, id: \.self) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, GameDetailLayout.navigationHorizontalPadding)
                            .padding(.vertical, GameDetailLayout.navigationVerticalPadding)
                            .foregroundColor(selectedSection == section ? .white : .primary)
                            .background(selectedSection == section ? GameTheme.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Jump to \(section.title)")
                }
            }
            .padding(.horizontal, GameDetailLayout.horizontalPadding)
            .padding(.vertical, GameDetailLayout.listSpacing)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Section navigation")
    }

    func compactChapterSection(
        number: Int,
        title: String,
        subtitle: String?,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.chapterSpacing) {
            Text("Chapter \(number)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, GameDetailLayout.chapterHorizontalPadding)
            CollapsibleSectionCard(
                title: title,
                subtitle: subtitle,
                isExpanded: isExpanded
            ) {
                content()
            }
        }
    }
}
