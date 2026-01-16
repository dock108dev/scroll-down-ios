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
    // Default expansion states per spec
    @State var isOverviewExpanded = true
    // NOTE: isPreGameExpanded removed - preGameSection deprecated
    @State var isTimelineExpanded = true
    @State var isPlayerStatsExpanded = false
    @State var isTeamStatsExpanded = false
    @State var isFinalScoreExpanded = false
    // NOTE: isPostGameExpanded removed - postGameSection deprecated
    // NOTE: isSocialExpanded removed - socialSection deprecated
    @State var isRelatedPostsExpanded = false
    // NOTE: Removed legacy compact view state (isCompactSummaryExpanded, isCompactTimelineExpanded, 
    // isCompactPostsExpanded, selectedCompactMoment) - compact mode now affects layout density only
    @State var playRowFrames: [Int: CGRect] = [:]
    @State var timelineFrame: CGRect = .zero
    @State var scrollViewFrame: CGRect = .zero
    @State var savedResumePlayIndex: Int?
    @State var hasLoadedResumeMarker = false
    @State var isResumeTrackingEnabled = true
    @State var shouldShowResumePrompt = false

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
                
                // Load timeline artifact (contains summary_json)
                await viewModel.loadTimeline(gameId: gameId, service: appConfig.gameService)
                
                // Load social posts if enabled
                if viewModel.isSocialTabEnabled {
                    await viewModel.loadSocialPosts(gameId: gameId, service: appConfig.gameService)
                }
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
                    VStack(spacing: GameDetailLayout.sectionSpacing) {
                        if let game = viewModel.game {
                            GameHeaderView(game: game)
                                .id(GameSection.header)
                        }

                        VStack(spacing: GameDetailLayout.sectionSpacing) {
                            pregameSection
                                .id(GameSection.overview)
                                .onAppear {
                                    selectedSection = .overview
                                }
                            // NOTE: preGameSection removed - social posts now come from timeline_json
                            timelineSection(using: proxy)
                                .id(GameSection.timeline)
                                .onAppear {
                                    selectedSection = .timeline
                                }
                            // NOTE: socialSection removed - tweets are now integrated into unified timeline
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
                            // NOTE: postGameSection removed - social posts now come from timeline_json
                            relatedPostsSection
                        }
                        .padding(.horizontal, GameDetailLayout.horizontalPadding)
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
                        .padding(.top, GameDetailLayout.viewingPillTopPadding)
                        .padding(.horizontal, GameDetailLayout.horizontalPadding)
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

    // NOTE: Legacy compactContentView deleted
    // Compact mode is now implemented as layout density changes in standardContentView
    // The old view hid sections instead of just changing layout, violating the principle
    // that compact mode should only affect presentation, not content
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
