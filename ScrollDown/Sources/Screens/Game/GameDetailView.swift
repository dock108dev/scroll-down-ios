import SwiftUI

/// Game detail view showing full game information
struct GameDetailView: View {
    @EnvironmentObject var appConfig: AppConfig
    @EnvironmentObject var readStateStore: ReadStateStore
    let gameId: Int
    let leagueCode: String?

    @StateObject var viewModel: GameDetailViewModel
    // Timeline rows default to compact, users expand individual rows as needed
    @State var expandedTimelineRows: Set<String> = []
    @State var selectedSection: GameSection = .overview
    @State var collapsedQuarters: Set<Int> = []
    @State var hasInitializedQuarters = false
    @State var isCompactFlowExpanded = false
    // Content Hierarchy Default States:
    // Tier 1 (Game Flow): Always expanded - handled by GameFlowView
    // Tier 2 (Timeline): Collapsed by default unless no flow
    // Tier 3 (Stats): Collapsed by default
    // Tier 4 (Reference): Collapsed by default
    @State var isFlowCardExpanded = true  // Flow Card: expanded by default (primary content)
    @State var isOverviewExpanded = false  // Tier 4: Reference
    @State var pregamePostsShown = 5  // Paginate pregame posts
    @State var isTimelineExpanded = false  // Tier 2: Secondary (expanded if no flow)
    @State var isPlayerStatsExpanded = false  // Tier 3: Supporting
    @State var playerStatsTeamFilter: String? = nil
    @State var isTeamStatsExpanded = false  // Tier 3: Supporting
    @State var isOddsExpanded = false  // Tier 3: Supporting
    @State var selectedOddsCategory: MarketCategory = .mainline
    @State var oddsPlayerSearch: String = ""
    @State var collapsedOddsGroups: Set<String> = []
    @State var isWrapUpExpanded = false  // Tier 4: Reference
    @State var showingFullPlayByPlay = false
    @State var playRowFrames: [Int: CGRect] = [:]
    @State var timelineFrame: CGRect = .zero
    @State var scrollViewFrame: CGRect = .zero
    @State var sectionFrames: [GameSection: CGRect] = [:]
    @State var savedResumePlayIndex: Int?
    @State var hasLoadedResumeMarker = false
    @State var isResumeTrackingEnabled = true
    @State var shouldShowResumePrompt = false
    @State var isManualTabSelection = false
    @State var scrollToSection: GameSection? = nil  // Triggers scroll when set
    @State var displayedAwayScore: Int? = nil
    @State var displayedHomeScore: Int? = nil
    // iPad: Size class for adaptive layouts (internal for extension access)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(gameId: Int, leagueCode: String? = nil, detail: GameDetailResponse? = nil) {
        self.gameId = gameId
        self.leagueCode = leagueCode
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(detail: detail))

        let prefs = UserDefaults.standard.string(forKey: "gameExpandedSections") ?? "timeline"
        let expandedSet = Set(prefs.split(separator: ",").map(String.init))
        _isFlowCardExpanded = State(initialValue: expandedSet.contains("timeline"))
        _isOverviewExpanded = State(initialValue: expandedSet.contains("overview"))
        _isPlayerStatsExpanded = State(initialValue: expandedSet.contains("playerStats"))
        _isTeamStatsExpanded = State(initialValue: expandedSet.contains("teamStats"))
        _isWrapUpExpanded = State(initialValue: expandedSet.contains("final"))
    }

    var body: some View {
        Group {
            if !isValidGameId {
                unavailableView
            } else if viewModel.isUnavailable {
                unavailableView
            } else if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if viewModel.detail != nil {
                gameContentView()
            } else {
                unavailableView
            }
        }
        .navigationTitle(viewModel.game?.matchupTitle ?? "Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard isValidGameId else {
                // Invalid game ID — show unavailable state.
                GameRoutingLogger.logInvalidNavigation(tappedId: gameId, destinationId: gameId, league: leagueCode)
                return
            }

            GameRoutingLogger.logDetailLoad(tappedId: gameId, destinationId: gameId, league: leagueCode)
            await viewModel.load(gameId: gameId, league: leagueCode, service: appConfig.gameService)

            if !viewModel.isUnavailable {
                // Load user preferences
                viewModel.loadSocialTabPreference(for: gameId)

                // Load timeline and social in parallel with flow loading
                async let timelineTask: () = viewModel.loadTimeline(gameId: gameId, service: appConfig.gameService)
                async let socialTask: () = loadSocialIfEnabled()

                if viewModel.game?.status.isLive == true {
                    // Live game: load PBP as primary content, start polling
                    await viewModel.loadPbp(gameId: gameId, service: appConfig.gameService)
                    viewModel.startLivePolling(gameId: gameId, service: appConfig.gameService)
                } else {
                    // Final/other: try flow first
                    await viewModel.loadFlow(gameId: gameId, service: appConfig.gameService)

                    // If flow found, build unified timeline from flow plays (for Full PBP popup)
                    if viewModel.hasFlowData {
                        isTimelineExpanded = false
                        viewModel.buildUnifiedTimelineFromFlow()
                    } else {
                        await viewModel.loadPbp(gameId: gameId, service: appConfig.gameService)
                    }
                }

                // Await remaining parallel tasks
                _ = await (timelineTask, socialTask)
            }
        }
    }

    private var isValidGameId: Bool {
        gameId > 0
    }

    /// Whether the user has already read this game (wrap-up opened now or previously)
    private var isGameRead: Bool {
        isWrapUpExpanded || readStateStore.isRead(gameId: gameId)
    }

    private func loadSocialIfEnabled() async {
        if viewModel.isSocialTabEnabled {
            await viewModel.loadSocialPosts(gameId: gameId, service: appConfig.gameService)
        }
    }

    // MARK: - Subviews

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading game...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var unavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Game unavailable")
                .font(.headline)
            Text("We couldn't confirm this game's identity.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func errorView(_ message: String) -> some View {
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
                Task { await viewModel.load(gameId: gameId, league: leagueCode, service: appConfig.gameService) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func gameContentView() -> some View {
        standardContentView
    }

    var standardContentView: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                // MARK: Sticky Navigation Bar
                // Stays pinned at top when scrolling
                sectionNavigationBar { section in
                    isManualTabSelection = true
                    selectedSection = section
                    // Reset first to ensure onChange fires even for same section (re-tap)
                    scrollToSection = nil
                    // Trigger scroll via state change (handled by .onChange below)
                    DispatchQueue.main.async {
                        scrollToSection = section
                    }
                }
                .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                .frame(maxWidth: .infinity) // Center on iPad
                .background(GameTheme.background)

                // Subtle divider below sticky nav
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5)

                // MARK: Scrollable Content
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        VStack(spacing: GameDetailLayout.sectionSpacing(horizontalSizeClass)) {
                            // Header - constrained to max-width on iPad
                            if let game = viewModel.game {
                                GameHeaderView(
                                game: game,
                                scoreRevealed: isGameRead,
                                onRevealScore: {
                                    if game.status.isLive {
                                        // Show current live score and persist it
                                        displayedAwayScore = game.awayScore
                                        displayedHomeScore = game.homeScore
                                        if let away = game.awayScore, let home = game.homeScore {
                                            ReadingPositionStore.shared.updateScores(for: gameId, awayScore: away, homeScore: home)
                                        }
                                    } else {
                                        readStateStore.markRead(gameId: gameId, status: game.status)
                                    }
                                },
                                scoreRevealMode: readStateStore.scoreRevealMode,
                                hasReadingPosition: ReadingPositionStore.shared.load(gameId: gameId) != nil,
                                resumeText: ReadingPositionStore.shared.resumeDisplayText(for: gameId),
                                displayAwayScore: displayedAwayScore,
                                displayHomeScore: displayedHomeScore,
                                scoreContextText: ReadingPositionStore.shared.scoreContext(for: gameId)
                            )
                                    .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                                    .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                                    .id(GameSection.header)
                            }

                            // Resume prompt (if applicable)
                            if shouldShowResumePrompt {
                                resumePromptView(
                                    onResume: { resumeScroll(using: proxy) },
                                    onStartOver: { startOver(using: proxy) }
                                )
                                .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                                .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                            }

                            // Content sections matching navigation order
                            VStack(spacing: 0) {
                                // Pregame section - only if content exists
                                if !viewModel.pregameSocialPosts.isEmpty {
                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .overview)
                                        pregameSection
                                    }
                                    .background(sectionFrameTracker(for: .overview))

                                    Color.clear.frame(height: 8)
                                }

                                // Game Flow / Live PBP section
                                if viewModel.hasFlowData || (viewModel.game?.status.isLive == true && viewModel.hasPbpData) {
                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .timeline)
                                        timelineSection(using: proxy)
                                    }
                                    .background(sectionFrameTracker(for: .timeline))
                                }

                                // Player Stats - only if data exists
                                if !viewModel.playerStats.isEmpty {
                                    Color.clear.frame(height: 8)

                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .playerStats)
                                        playerStatsSection(viewModel.playerStats)
                                    }
                                    .background(sectionFrameTracker(for: .playerStats))
                                }

                                // Team Stats - only if data exists
                                if !viewModel.teamStats.isEmpty {
                                    Color.clear.frame(height: 8)

                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .teamStats)
                                        teamStatsSection(viewModel.teamStats)
                                    }
                                    .background(sectionFrameTracker(for: .teamStats))
                                }

                                // Odds - only if odds data exists
                                if viewModel.hasOddsData {
                                    Color.clear.frame(height: 8)

                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .odds)
                                        oddsSection
                                    }
                                    .background(sectionFrameTracker(for: .odds))
                                }

                                // Wrap-up - for completed games (with confirmation signals)
                                if viewModel.isGameTrulyCompleted {
                                    Color.clear.frame(height: 8)

                                    VStack(spacing: 0) {
                                        sectionAnchor(for: .final)
                                        wrapUpSection
                                    }
                                    .background(sectionFrameTracker(for: .final))
                                }
                            }
                            .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                            // iPad: Constrain content width for better readability
                            .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                        }
                        .padding(.bottom, GameDetailLayout.bottomPadding)
                    }
                    .coordinateSpace(name: GameDetailLayout.scrollCoordinateSpace)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ScrollViewFramePreferenceKey.self,
                                value: proxy.frame(in: .named(GameDetailLayout.scrollCoordinateSpace))
                            )
                        }
                    )

                    if let viewingText = viewingPillText {
                        viewingPillView(text: viewingText)
                            .padding(.top, GameDetailLayout.viewingPillTopPadding)
                            .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                            .transition(.opacity)
                            .accessibilityLabel("Viewing \(viewingText)")
                    }
                }
            }
            .background(GameTheme.background)
            .clipped()
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
            .onPreferenceChange(SectionFramePreferenceKey.self) { value in
                sectionFrames = value
                updateSelectedSectionFromScroll()
            }
            .onAppear {
                loadResumeMarkerIfNeeded()
            }
            .onDisappear {
                viewModel.stopLivePolling()
            }
            .onChange(of: viewModel.detail?.plays.count ?? 0) {
                loadResumeMarkerIfNeeded()
            }
            .onChange(of: isWrapUpExpanded) { _, expanded in
                if expanded, let status = viewModel.game?.status {
                    readStateStore.markRead(gameId: gameId, status: status)
                }
            }
            .onChange(of: scrollToSection) { _, target in
                guard let target else { return }
                // Position section at top of visible area (anchor .top)
                // Use anchorId to target the content anchor, not the nav button
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(target.anchorId, anchor: .top)
                }
                // Reset after scroll completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scrollToSection = nil
                    isManualTabSelection = false
                }
            }
        }
    }

}

#Preview {
    Group {
        NavigationStack {
            GameDetailView(gameId: 1, detail: PreviewFixtures.highlightsHeavyGame)
        }
        .preferredColorScheme(.light)
        .environmentObject(AppConfig.shared)
        .environmentObject(ReadStateStore.shared)

        NavigationStack {
            GameDetailView(gameId: 2, detail: PreviewFixtures.highlightsLightGame)
        }
        .preferredColorScheme(.dark)
        .environmentObject(AppConfig.shared)
        .environmentObject(ReadStateStore.shared)

        NavigationStack {
            GameDetailView(gameId: 3, detail: PreviewFixtures.overtimeGame)
        }
        .environmentObject(AppConfig.shared)
        .environmentObject(ReadStateStore.shared)

        NavigationStack {
            GameDetailView(gameId: 4, detail: PreviewFixtures.preGameOnlyGame)
        }
        .environmentObject(AppConfig.shared)
        .environmentObject(ReadStateStore.shared)
    }
}
