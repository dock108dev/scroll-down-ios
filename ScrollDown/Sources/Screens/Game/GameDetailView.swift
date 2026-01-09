import SwiftUI

/// Game detail view showing full game information
struct GameDetailView: View {
    @EnvironmentObject var appConfig: AppConfig
    let gameId: Int

    @StateObject var viewModel: GameDetailViewModel
    @AppStorage("compactModeEnabled") var isCompactMode = false
    @State var selectedSection: GameSection = .overview
    @State var collapsedQuarters: Set<Int> = []
    @State var hasInitializedQuarters = false
    // Default expansion states per spec
    @State var isOverviewExpanded = true
    @State var isPreGameExpanded = true
    @State var isTimelineExpanded = true
    @State var isPlayerStatsExpanded = false
    @State var isTeamStatsExpanded = false
    @State var isFinalScoreExpanded = false
    @State var isPostGameExpanded = false
    @State var isRelatedPostsExpanded = false
    @State var isCompactSummaryExpanded = false
    @State var isCompactTimelineExpanded = false
    @State var isCompactPostsExpanded = false
    @State var selectedCompactMoment: CompactMoment?
    @State var playRowFrames: [Int: CGRect] = [:]
    @State var timelineFrame: CGRect = .zero
    @State var scrollViewFrame: CGRect = .zero
    @State var savedResumePlayIndex: Int?
    @State var hasLoadedResumeMarker = false
    @State var isResumeTrackingEnabled = true
    @State var shouldShowResumePrompt = false

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

    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading game...")
                .foregroundColor(.secondary)
        }
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
                Task { await viewModel.load(gameId: gameId, service: appConfig.gameService) }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    func gameContentView() -> some View {
        Group {
            if isCompactMode {
                compactContentView
            } else {
                standardContentView
            }
        }
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
                            displayOptionsSection
                            overviewSection
                                .id(GameSection.overview)
                                .onAppear {
                                    selectedSection = .overview
                                }
                            preGameSection
                            timelineSection(using: proxy)
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

    var compactContentView: some View {
        ScrollView {
            VStack(spacing: GameDetailLayout.sectionSpacing) {
                if let game = viewModel.game {
                    GameHeaderView(game: game)
                }

                VStack(spacing: GameDetailLayout.sectionSpacing) {
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
                .padding(.horizontal, GameDetailLayout.horizontalPadding)
            }
            .padding(.bottom, GameDetailLayout.bottomPadding)
        }
        .background(GameTheme.background)
        .sheet(item: $selectedCompactMoment) { moment in
            NavigationStack {
                CompactMomentExpandedView(moment: moment, service: appConfig.gameService)
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

