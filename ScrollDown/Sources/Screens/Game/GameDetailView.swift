import SwiftUI

/// Game detail view showing full game information
struct GameDetailView: View {
    @EnvironmentObject var appConfig: AppConfig
    let gameId: Int
    let leagueCode: String?

    @StateObject var viewModel: GameDetailViewModel
    // Timeline rows default to compact, users expand individual rows as needed
    @State var expandedTimelineRows: Set<String> = []
    @State var selectedSection: GameSection = .overview
    @State var collapsedQuarters: Set<Int> = []
    @State var hasInitializedQuarters = false
    // Story sections state
    @State var collapsedSections: Set<Int> = []
    @State var hasInitializedSections = false
    @State var isCompactStoryExpanded = false
    // Default expansion states per spec
    @State var isOverviewExpanded = true
    @State var isTimelineExpanded = true
    @State var isPlayerStatsExpanded = false
    @State var playerStatsTeamFilter: String? = nil  // nil = all teams
    @State var isTeamStatsExpanded = false
    @State var isWrapUpExpanded = false
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
    // iPad: Size class for adaptive layouts (internal for extension access)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    init(gameId: Int, leagueCode: String? = nil, detail: GameDetailResponse? = nil) {
        self.gameId = gameId
        self.leagueCode = leagueCode
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(detail: detail))
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
                // Block fallback routing when identity is missing; show a neutral unavailable state.
                GameRoutingLogger.logInvalidNavigation(tappedId: gameId, destinationId: gameId, league: leagueCode)
                return
            }

            GameRoutingLogger.logDetailLoad(tappedId: gameId, destinationId: gameId, league: leagueCode)
            await viewModel.load(gameId: gameId, league: leagueCode, service: appConfig.gameService)

            if !viewModel.isUnavailable {
                // Load user preferences
                viewModel.loadSocialTabPreference(for: gameId)

                // Load timeline, story, and social posts in parallel
                async let timelineTask: () = viewModel.loadTimeline(gameId: gameId, service: appConfig.gameService)
                async let storyTask: () = viewModel.loadStory(gameId: gameId, service: appConfig.gameService)
                async let socialTask: () = {
                    if viewModel.isSocialTabEnabled {
                        await viewModel.loadSocialPosts(gameId: gameId, service: appConfig.gameService)
                    }
                }()

                // Await all in parallel
                _ = await (timelineTask, storyTask, socialTask)
            }
        }
    }

    private var isValidGameId: Bool {
        gameId > 0
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
        // NOTE: Compact mode temporarily disabled (visual no-op)
        // The toggle remains in UI but always shows standard view
        // Compact mode previously hid sections, which violated the principle
        // that it should only change layout, not which data is rendered
        standardContentView
    }

    var standardContentView: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                ScrollView {
                    VStack(spacing: GameDetailLayout.sectionSpacing(horizontalSizeClass)) {
                        // Header - constrained to max-width on iPad
                        if let game = viewModel.game {
                            GameHeaderView(game: game)
                                .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                                .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                                .id(GameSection.header)
                        }

                        // Tab navigation - scrolls with content (not sticky)
                        sectionNavigationBar { section in
                            isManualTabSelection = true
                            selectedSection = section
                            // Trigger scroll via state change (handled by .onChange below)
                            scrollToSection = section
                        }
                        .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                        .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)

                        // Resume prompt (if applicable)
                        if shouldShowResumePrompt {
                            resumePromptView(
                                onResume: { resumeScroll(using: proxy) },
                                onStartOver: { startOver(using: proxy) }
                            )
                            .padding(.horizontal, GameDetailLayout.horizontalPadding(horizontalSizeClass))
                            .frame(maxWidth: horizontalSizeClass == .regular ? GameDetailLayout.maxContentWidth : .infinity)
                        }

                        // Content sections - each has an anchor view for reliable scrollTo
                        VStack(spacing: GameDetailLayout.sectionSpacing(horizontalSizeClass)) {
                            VStack(spacing: 0) {
                                Color.clear.frame(height: 1).id(GameSection.overview)
                                pregameSection
                            }
                            .background(sectionFrameTracker(for: .overview))

                            VStack(spacing: 0) {
                                Color.clear.frame(height: 1).id(GameSection.timeline)
                                timelineSection(using: proxy)
                            }
                            .background(sectionFrameTracker(for: .timeline))

                            VStack(spacing: 0) {
                                Color.clear.frame(height: 1).id(GameSection.playerStats)
                                playerStatsSection(viewModel.playerStats)
                            }
                            .background(sectionFrameTracker(for: .playerStats))

                            VStack(spacing: 0) {
                                Color.clear.frame(height: 1).id(GameSection.teamStats)
                                teamStatsSection(viewModel.teamStats)
                            }
                            .background(sectionFrameTracker(for: .teamStats))

                            VStack(spacing: 0) {
                                Color.clear.frame(height: 1).id(GameSection.final)
                                wrapUpSection
                            }
                            .background(sectionFrameTracker(for: .final))
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
            .onPreferenceChange(SectionFramePreferenceKey.self) { value in
                sectionFrames = value
                updateSelectedSectionFromScroll()
            }
            .onAppear {
                loadResumeMarkerIfNeeded()
            }
            .onChange(of: viewModel.detail?.plays.count ?? 0) { _ in
                loadResumeMarkerIfNeeded()
            }
            .onChange(of: scrollToSection) { target in
                guard let target = target else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(target, anchor: .top)
                }
                // Reset after scroll
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
