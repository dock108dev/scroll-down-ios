import SwiftUI

/// Game detail view showing full game information
struct GameDetailView: View {
    @EnvironmentObject var appConfig: AppConfig
    let gameId: Int
    
    @StateObject private var viewModel: GameDetailViewModel
    @AppStorage("compactModeEnabled") private var isCompactMode = false
    @State private var selectedSection: GameSection = .overview
    @State private var collapsedQuarters: Set<Int> = []
    @State private var hasInitializedQuarters = false
    // Default expansion states per spec
    @State private var isOverviewExpanded = true
    @State private var isPreGameExpanded = true
    @State private var isTimelineExpanded = true
    @State private var isPlayerStatsExpanded = false
    @State private var isTeamStatsExpanded = false
    @State private var isFinalScoreExpanded = false
    @State private var isPostGameExpanded = false
    @State private var isRelatedPostsExpanded = false
    @State private var isCompactSummaryExpanded = false
    @State private var isCompactTimelineExpanded = false
    @State private var isCompactPostsExpanded = false
    @State private var selectedCompactMoment: CompactMoment?
    @State private var playRowFrames: [Int: CGRect] = [:]
    @State private var timelineFrame: CGRect = .zero
    @State private var scrollViewFrame: CGRect = .zero
    @State private var savedResumePlayIndex: Int?
    @State private var hasLoadedResumeMarker = false
    @State private var isResumeTrackingEnabled = true
    @State private var shouldShowResumePrompt = false

    init(gameId: Int, detail: GameDetailResponse? = nil) {
        self.gameId = gameId
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(detail: detail))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.detail != nil {
                gameContentView()
            }
        }
        .navigationTitle(viewModel.game?.matchupTitle ?? "Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let detailLoad: Void = viewModel.load(gameId: gameId, service: appConfig.gameService)
            async let summaryLoad: Void = viewModel.loadSummary(gameId: gameId, service: appConfig.gameService)
            _ = await (detailLoad, summaryLoad)
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading game...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.load(gameId: gameId, service: appConfig.gameService) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func gameContentView() -> some View {
        Group {
            if isCompactMode {
                compactContentView
            } else {
                standardContentView
            }
        }
    }

    private var standardContentView: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: Layout.sectionSpacing) {
                        if let game = viewModel.game {
                            GameHeaderView(game: game)
                                .id(GameSection.header)
                        }

                        VStack(spacing: Layout.sectionSpacing) {
                            displayOptionsSection
                            overviewSection
                                .id(GameSection.overview)
                                .onAppear {
                                    selectedSection = .overview
                                }
                            preGameSection
                            timelineSection
                                .id(GameSection.timeline)
                                .onAppear {
                                    selectedSection = .timeline
                                }
                            playerStatsSection(viewModel.playerStats)
                                .id(GameSection.playerStats)
                                .onAppear {
                                    selectedSection = .playerStats
                                }
                            teamStatsSection(viewModel.teamStats)
                                .id(GameSection.teamStats)
                                .onAppear {
                                    selectedSection = .teamStats
                                }
                            finalScoreSection
                                .id(GameSection.final)
                                .onAppear {
                                    selectedSection = .final
                                }
                            postGameSection
                            relatedPostsSection
                        }
                        .padding(.horizontal, Layout.horizontalPadding)
                    }
                    .padding(.bottom, Layout.bottomPadding)
                }
                .coordinateSpace(name: Layout.scrollCoordinateSpace)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollViewFramePreferenceKey.self,
                            value: proxy.frame(in: .named(Layout.scrollCoordinateSpace))
                        )
                    }
                )
                .safeAreaInset(edge: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        sectionNavigationBar { section in
                            withAnimation(.easeInOut) {
                                selectedSection = section
                                proxy.scrollTo(section, anchor: .top)
                            }
                        }
                        if shouldShowResumePrompt {
                            resumePromptView(
                                onResume: { resumeScroll(using: proxy) },
                                onStartOver: { startOver(using: proxy) }
                            )
                        }
                    }
                }

                if let viewingText = viewingPillText {
                    viewingPillView(text: viewingText)
                        .padding(.top, Layout.viewingPillTopPadding)
                        .padding(.horizontal, Layout.horizontalPadding)
                        .transition(.opacity)
                        .accessibilityLabel("Viewing \(viewingText)")
                }
            }
            .background(GameTheme.background)
            .onPreferenceChange(PlayRowFramePreferenceKey.self) { value in
                playRowFrames = value
                updateResumeMarkerIfNeeded()
            }
            .onPreferenceChange(TimelineFramePreferenceKey.self) { value in
                timelineFrame = value
            }
            .onPreferenceChange(ScrollViewFramePreferenceKey.self) { value in
                scrollViewFrame = value
                updateResumeMarkerIfNeeded()
            }
            .onAppear {
                loadResumeMarkerIfNeeded()
            }
            .onChange(of: viewModel.detail?.plays.count ?? 0) { _ in
                loadResumeMarkerIfNeeded()
            }
        }
    }

    private var compactContentView: some View {
        ScrollView {
            VStack(spacing: Layout.sectionSpacing) {
                if let game = viewModel.game {
                    GameHeaderView(game: game)
                }

                VStack(spacing: Layout.sectionSpacing) {
                    displayOptionsSection
                    compactChapterSection(
                        number: 1,
                        title: "AI Summary",
                        subtitle: "Quick recap",
                        isExpanded: $isCompactSummaryExpanded
                    ) {
                        overviewContent
                    }
                    compactChapterSection(
                        number: 2,
                        title: "Play-by-play",
                        subtitle: "Timeline",
                        isExpanded: $isCompactTimelineExpanded
                    ) {
                        CompactTimelineView(
                            moments: viewModel.compactTimelineMoments,
                            status: viewModel.game?.status,
                            onSelect: { moment in
                                selectedCompactMoment = moment
                            }
                        )
                    }
                    compactChapterSection(
                        number: 3,
                        title: "Posts",
                        subtitle: "Highlights & reactions",
                        isExpanded: $isCompactPostsExpanded
                    ) {
                        compactPostsContent
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
            }
            .padding(.bottom, Layout.bottomPadding)
        }
        .background(GameTheme.background)
        .sheet(item: $selectedCompactMoment) { moment in
            NavigationStack {
                CompactMomentExpandedView(moment: moment, service: appConfig.gameService)
            }
        }
    }

    private var displayOptionsSection: some View {
        SectionCardView(title: "Recap Style", subtitle: "Choose your flow") {
            Toggle("Compact Mode", isOn: $isCompactMode)
                .tint(GameTheme.accentColor)
        }
        .accessibilityHint("Switch to a chapter-based recap flow")
    }

    private var overviewSection: some View {
        CollapsibleSectionCard(
            title: "Overview",
            subtitle: "Recap",
            isExpanded: $isOverviewExpanded
        ) {
            overviewContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game overview")
    }

    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: Layout.textSpacing) {
            aiSummaryView

            VStack(alignment: .leading, spacing: Layout.listSpacing) {
                ForEach(viewModel.recapBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: Layout.listSpacing) {
                        Circle()
                            .frame(width: Layout.bulletSize, height: Layout.bulletSize)
                            .foregroundColor(.secondary)
                            .padding(.top, Layout.bulletOffset)
                        Text(bullet)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var preGameSection: some View {
        CollapsibleSectionCard(
            title: "Pre-Game",
            subtitle: "Before tipoff",
            isExpanded: $isPreGameExpanded
        ) {
            preGameContent
        }
        .accessibilityHint("Expands to show pre-game posts")
    }

    private var preGameContent: some View {
        VStack(spacing: Layout.cardSpacing) {
            ForEach(viewModel.preGamePosts) { post in
                HighlightCardView(post: post)
            }

            if viewModel.preGamePosts.isEmpty {
                EmptySectionView(text: "Pre-game posts will appear here.")
            }
        }
    }

    private var timelineSection: some View {
        CollapsibleSectionCard(
            title: "Timeline",
            subtitle: "Play-by-play",
            isExpanded: $isTimelineExpanded
        ) {
            timelineContent
        }
        .onChange(of: viewModel.timelineQuarters) { quarters in
            guard !hasInitializedQuarters else { return }
            // Q1 expanded, Q2+ collapsed per spec
            collapsedQuarters = Set(quarters.filter { $0.quarter > 1 }.map(\.quarter))
            hasInitializedQuarters = true
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TimelineFramePreferenceKey.self,
                    value: proxy.frame(in: .named(Layout.scrollCoordinateSpace))
                )
            }
        )
        .accessibilityElement(children: .contain)
    }

    private var timelineContent: some View {
        VStack(spacing: Layout.cardSpacing) {
            if let liveMarker = viewModel.liveScoreMarker {
                TimelineScoreChipView(marker: liveMarker)
            }

            ForEach(viewModel.timelineQuarters) { quarter in
                quarterSection(quarter)
            }

            if viewModel.timelineQuarters.isEmpty {
                EmptySectionView(text: "No play-by-play data available.")
            }
        }
    }

    private func quarterSection(_ quarter: GameDetailViewModel.QuarterTimeline) -> some View {
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
                }
            )
        ) {
            VStack(spacing: Layout.cardSpacing) {
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
                                    value: [play.playIndex: proxy.frame(in: .named(Layout.scrollCoordinateSpace))]
                                )
                            }
                        )

                    if let marker = viewModel.scoreMarker(for: play) {
                        TimelineScoreChipView(marker: marker)
                    }
                }
            }
            .padding(.top, Layout.listSpacing)
        }
    }

    private func playerStatsSection(_ stats: [PlayerStat]) -> some View {
        CollapsibleSectionCard(
            title: "Player Stats",
            subtitle: "Individual performance",
            isExpanded: $isPlayerStatsExpanded
        ) {
            playerStatsContent(stats)
        }
    }

    private func playerStatsContent(_ stats: [PlayerStat]) -> some View {
        if stats.isEmpty {
            EmptySectionView(text: "Player stats are not yet available.")
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    playerStatsHeader
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        playerStatsRow(stat, isAlternate: index.isMultiple(of: 2))
                    }
                }
                .frame(minWidth: Layout.statsTableWidth)
            }
        }
    }

    private var playerStatsHeader: some View {
        HStack(spacing: Layout.statsColumnSpacing) {
            Text("Player")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("PTS")
                .frame(width: Layout.statColumnWidth)
            Text("REB")
                .frame(width: Layout.statColumnWidth)
            Text("AST")
                .frame(width: Layout.statColumnWidth)
        }
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.vertical, Layout.listSpacing)
        .padding(.horizontal, Layout.statsHorizontalPadding)
        .background(Color(.systemGray6))
    }

    private func playerStatsRow(_ stat: PlayerStat, isAlternate: Bool) -> some View {
        HStack(spacing: Layout.statsColumnSpacing) {
            VStack(alignment: .leading, spacing: Layout.smallSpacing) {
                Text(stat.playerName)
                    .font(.subheadline.weight(.medium))
                Text(stat.team)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(stat.points.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
            Text(stat.rebounds.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
            Text(stat.assists.map(String.init) ?? Constants.statFallback)
                .frame(width: Layout.statColumnWidth)
        }
        .font(.subheadline)
        .padding(.vertical, Layout.listSpacing)
        .padding(.horizontal, Layout.statsHorizontalPadding)
        .background(isAlternate ? Color(.systemGray6) : Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.playerName), \(stat.team)")
        .accessibilityValue("Points \(stat.points ?? 0), rebounds \(stat.rebounds ?? 0), assists \(stat.assists ?? 0)")
    }

    private func teamStatsSection(_ stats: [TeamStat]) -> some View {
        CollapsibleSectionCard(
            title: "Team Stats",
            subtitle: "How the game unfolded",
            isExpanded: $isTeamStatsExpanded
        ) {
            teamStatsContent(stats)
        }
    }

    private func teamStatsContent(_ stats: [TeamStat]) -> some View {
        if viewModel.teamComparisonStats.isEmpty {
            EmptySectionView(text: "Team stats will appear once available.")
        } else {
            VStack(spacing: Layout.listSpacing) {
                ForEach(viewModel.teamComparisonStats) { stat in
                    TeamComparisonRowView(
                        stat: stat,
                        homeTeam: stats.first(where: { $0.isHome })?.team ?? "Home",
                        awayTeam: stats.first(where: { !$0.isHome })?.team ?? "Away"
                    )
                }
            }
        }
    }

    private var finalScoreSection: some View {
        CollapsibleSectionCard(
            title: "Final Score",
            subtitle: "Wrap-up",
            isExpanded: $isFinalScoreExpanded
        ) {
            finalScoreContent
        }
    }

    private var finalScoreContent: some View {
        VStack(spacing: Layout.textSpacing) {
            Text(viewModel.game?.scoreDisplay ?? Constants.scoreFallback)
                .font(.system(size: Layout.finalScoreSize, weight: .bold))
            Text("Final")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.listSpacing)
    }

    private var postGameSection: some View {
        CollapsibleSectionCard(
            title: "Post-Game",
            subtitle: "Reactions",
            isExpanded: $isPostGameExpanded
        ) {
            postGameContent
        }
        .accessibilityHint("Expands to show post-game posts")
    }

    private var postGameContent: some View {
        VStack(spacing: Layout.cardSpacing) {
            ForEach(viewModel.postGamePosts) { post in
                HighlightCardView(post: post)
            }

            if viewModel.postGamePosts.isEmpty {
                EmptySectionView(text: "Post-game posts will appear here.")
            }
        }
    }

    private var compactPostsContent: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            if viewModel.preGamePosts.isEmpty && viewModel.postGamePosts.isEmpty {
                EmptySectionView(text: "Posts will appear here.")
            } else {
                compactPostsSection(
                    title: "Pre-Game",
                    posts: viewModel.preGamePosts,
                    emptyText: "Pre-game posts will appear here."
                )
                compactPostsSection(
                    title: "Post-Game",
                    posts: viewModel.postGamePosts,
                    emptyText: "Post-game posts will appear here."
                )
            }

            relatedPostsCompactSection
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionNavigationBar(onSelect: @escaping (GameSection) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.navigationSpacing) {
                ForEach(GameSection.navigationSections, id: \.self) { section in
                    Button {
                        onSelect(section)
                    } label: {
                        Text(section.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, Layout.navigationHorizontalPadding)
                            .padding(.vertical, Layout.navigationVerticalPadding)
                            .foregroundColor(selectedSection == section ? .white : .primary)
                            .background(selectedSection == section ? GameTheme.accentColor : Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .accessibilityLabel("Jump to \(section.title)")
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.listSpacing)
        }
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Section navigation")
    }

    private func compactChapterSection(
        number: Int,
        title: String,
        subtitle: String?,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.chapterSpacing) {
            Text("Chapter \(number)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, Layout.chapterHorizontalPadding)
            CollapsibleSectionCard(
                title: title,
                subtitle: subtitle,
                isExpanded: isExpanded
            ) {
                content()
            }
        }
    }

    private func compactPostsSection(
        title: String,
        posts: [SocialPostEntry],
        emptyText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.listSpacing) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            if posts.isEmpty {
                EmptySectionView(text: emptyText)
            } else {
                ForEach(posts) { post in
                    HighlightCardView(post: post)
                }
            }
        }
    }

    private var relatedPostsSection: some View {
        CollapsibleSectionCard(
            title: "Related Posts",
            subtitle: "More coverage",
            isExpanded: $isRelatedPostsExpanded
        ) {
            relatedPostsContent
        }
        .accessibilityHint("Expands to show related posts")
    }

    private var relatedPostsCompactSection: some View {
        VStack(alignment: .leading, spacing: Layout.listSpacing) {
            Text("Related")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            relatedPostsContent
        }
    }

    private var relatedPostsContent: some View {
        VStack(alignment: .leading, spacing: Layout.cardSpacing) {
            switch viewModel.relatedPostsState {
            case .idle, .loading:
                HStack(spacing: Layout.listSpacing) {
                    ProgressView()
                    Text("Loading related posts...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: Layout.listSpacing) {
                    Text("Related posts unavailable.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadRelatedPosts(gameId: gameId, service: appConfig.gameService) }
                    }
                    .buttonStyle(.bordered)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .loaded:
                if viewModel.relatedPosts.isEmpty {
                    EmptySectionView(text: "Related posts will appear here.")
                } else {
                    LazyVStack(spacing: Layout.cardSpacing) {
                        ForEach(viewModel.relatedPosts) { post in
                            RelatedPostCardView(
                                post: post,
                                isRevealed: viewModel.isRelatedPostRevealed(post),
                                onReveal: {
                                    withAnimation(.easeInOut) {
                                        viewModel.revealRelatedPost(id: post.id)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadRelatedPosts(gameId: gameId, service: appConfig.gameService)
        }
    }

    private func quarterTitle(_ quarter: Int) -> String {
        quarter == 0 ? "Additional" : "Q\(quarter)"
    }

    private var viewingPillText: String? {
        guard isTimelineVisible else {
            return nil
        }

        guard let play = currentViewingPlay,
              let scoreText = scoreDisplay(for: play) else {
            return nil
        }

        return "\(periodDescriptor(for: play)) | \(scoreText)"
    }

    private var isTimelineVisible: Bool {
        timelineFrame.height > 0 && scrollViewFrame.height > 0 && timelineFrame.intersects(scrollViewFrame)
    }

    private var currentViewingPlay: PlayEntry? {
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

    private func periodDescriptor(for play: PlayEntry) -> String {
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

    private func periodPhaseLabel(minutesRemaining: Int) -> String {
        switch minutesRemaining {
        case 8...:
            return "Early"
        case 4..<8:
            return "Mid"
        default:
            return "Late"
        }
    }

    private func quarterOrdinal(_ quarter: Int) -> String {
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

    private func scoreDisplay(for play: PlayEntry) -> String? {
        guard let away = play.awayScore, let home = play.homeScore else {
            return nil
        }

        return "\(away)–\(home)"
    }

    private func viewingPillView(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, Layout.viewingPillHorizontalPadding)
            .padding(.vertical, Layout.viewingPillVerticalPadding)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    private func resumePromptView(onResume: @escaping () -> Void, onStartOver: @escaping () -> Void) -> some View {
        VStack(spacing: Layout.resumePromptSpacing) {
            Text("Resume where you left off?")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: Layout.resumeButtonSpacing) {
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
        .padding(Layout.resumePromptPadding)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resume where you left off?")
    }

    private func resumeScroll(using proxy: ScrollViewProxy) {
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

    private func startOver(using proxy: ScrollViewProxy) {
        clearSavedResumeMarker()
        shouldShowResumePrompt = false
        isResumeTrackingEnabled = true
        withAnimation(.easeInOut) {
            proxy.scrollTo(GameSection.header, anchor: .top)
        }
    }

    private func expandQuarter(for playIndex: Int) {
        guard let quarter = viewModel.detail?.plays.first(where: { $0.playIndex == playIndex })?.quarter else {
            return
        }
        collapsedQuarters.remove(quarter)
    }

    private func loadResumeMarkerIfNeeded() {
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

    private func updateResumeMarkerIfNeeded() {
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

    private func clearSavedResumeMarker() {
        savedResumePlayIndex = nil
        UserDefaults.standard.removeObject(forKey: resumeMarkerKey)
    }

    private var resumeMarkerKey: String {
        "game.resume.playIndex.\(gameId)"
    }

    private var aiSummaryView: some View {
        Group {
            switch viewModel.summaryState {
            case .loading:
                HStack(spacing: Layout.listSpacing) {
                    ProgressView()
                    Text("Loading summary...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            case .failed:
                VStack(alignment: .leading, spacing: Layout.smallSpacing) {
                    Text("Summary unavailable right now.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await viewModel.loadSummary(gameId: gameId, service: appConfig.gameService) }
                    }
                    .buttonStyle(.bordered)
                }
            case .loaded(let summary):
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Layout.summaryMinHeight, alignment: .leading)
        .accessibilityLabel("Summary")
        .accessibilityValue(summaryAccessibilityValue)
    }

    private var summaryAccessibilityValue: String {
        switch viewModel.summaryState {
        case .loaded(let summary):
            return summary
        case .failed:
            return "Summary unavailable"
        case .loading:
            return "Loading summary"
        }
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let sectionSpacing: CGFloat = 20
    static let textSpacing: CGFloat = 12
    static let listSpacing: CGFloat = 8
    static let smallSpacing: CGFloat = 4
    static let cardSpacing: CGFloat = 16
    static let horizontalPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 32
    static let bulletSize: CGFloat = 6
    static let bulletOffset: CGFloat = 6
    static let navigationSpacing: CGFloat = 12
    static let navigationHorizontalPadding: CGFloat = 16
    static let navigationVerticalPadding: CGFloat = 8
    static let statsColumnSpacing: CGFloat = 12
    static let statColumnWidth: CGFloat = 48
    static let statsHorizontalPadding: CGFloat = 16
    static let statsTableWidth: CGFloat = 360
    static let finalScoreSize: CGFloat = 40
    static let chapterSpacing: CGFloat = 8
    static let chapterHorizontalPadding: CGFloat = 4
    static let summaryMinHeight: CGFloat = 72
    static let viewingPillHorizontalPadding: CGFloat = 12
    static let viewingPillVerticalPadding: CGFloat = 6
    static let viewingPillTopPadding: CGFloat = 12
    static let resumePromptPadding: CGFloat = 16
    static let resumePromptSpacing: CGFloat = 8
    static let resumeButtonSpacing: CGFloat = 12
    static let scrollCoordinateSpace = "gameScrollView"
}

private struct PlayRowFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct TimelineFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct ScrollViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private enum Constants {
    static let statFallback = "--"
    static let scoreFallback = "--"
}

#Preview {
    Group {
        NavigationStack {
            GameDetailView(gameId: 1, detail: PreviewFixtures.highlightsHeavyGame)
        }
        .preferredColorScheme(.light)
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 2, detail: PreviewFixtures.highlightsLightGame)
        }
        .preferredColorScheme(.dark)
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 3, detail: PreviewFixtures.overtimeGame)
        }
        .environmentObject(AppConfig.shared)

        NavigationStack {
            GameDetailView(gameId: 4, detail: PreviewFixtures.preGameOnlyGame)
        }
        .environmentObject(AppConfig.shared)
    }
}
