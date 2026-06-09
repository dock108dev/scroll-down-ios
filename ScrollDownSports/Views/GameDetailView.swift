import SwiftUI

// Size note: Scroll/progress state stays in this View to keep SwiftUI @State ownership private; see cleanup report.
struct GameDetailView: View {
    let gameId: Int
    let summary: Game?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject var viewModel: GameDetailViewModel
    @StateObject var scrollRuntime = DetailScrollRuntime()
    @State var streamOrientationAnchorID: String?
    @State var visibilityTrackingSuppressed = true
    @State var liveEdgeMode: DetailLiveEdgeMode = .following
    @State var isNearLiveEdge = true
    @State var isTopChromeVisible = true
    @State var programmaticScrollInFlight = false
    @State var programmaticScrollTargetAnchorID: String?
    @State var lastUserScrollAt = Date.distantPast
    @State var currentVisibleEvent: DetailVisibleEventState?
    @State var returnAnchor: DetailVisibleEventState?
    @State var lastAcceptedVisibleFrame: DetailEventVisibilityFrame?
    @State var lastViewportSize: CGSize = .zero
    @State var resizeRestoreSnapshot: DetailResizeRestoreSnapshot?
    @State var resizeGeneration = 0
    @State var resizeStabilizationWorkItem: DispatchWorkItem?
    @State var contentChangeRestoreSnapshot: DetailContentChangeRestoreSnapshot?
    @State var contentChangeGeneration = 0
    @State var contentChangeStabilizationWorkItem: DispatchWorkItem?
    @State var stickyTopRequest = 0
    @State var stickyEndRequest = 0
    @State var stickyReturnRequest = 0
    @State var uiTestScoreboardRevealed = false
    @State var bottomAffordanceHeight: CGFloat = 0

    let playerStatsSectionID = "player-stats"
    let teamStatsSectionID = "team-stats"

    init(
        gameId: Int,
        summary: Game? = nil,
        apiClient: SDAApiClient = .shared,
        gameStateStore: any GameStateStore
    ) {
        self.gameId = gameId
        self.summary = summary
        _viewModel = StateObject(
            wrappedValue: GameDetailViewModel(
                gameId: gameId,
                apiClient: apiClient,
                gameStateStore: gameStateStore
            )
        )
    }

    var body: some View {
        GeometryReader { viewport in
            let layout = SportsLayoutMetrics(
                availableWidth: viewport.size.width,
                availableHeight: viewport.size.height,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass,
                dynamicTypeSize: dynamicTypeSize
            )
            let bottomObscuredHeight = bottomAffordanceObscuredHeight(
                measuredHeight: bottomAffordanceHeight,
                safeAreaBottom: viewport.safeAreaInsets.bottom,
                layout: layout
            )

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: layout.stackSpacing, pinnedViews: []) {
                        if let detail = viewModel.detail {
                            Color.clear
                                .frame(height: 1)
                                .id(GameDetailScrollAnchor.top)
                                .accessibilityIdentifier("detail.anchor.top")
                            let renderer = SportRendererRegistry.renderer(for: detail.game)
                            GameHeaderView(
                                game: detail.game,
                                renderer: renderer,
                                isPinned: viewModel.isGamePinned,
                                newPlayCount: pendingNewPlayCount,
                                progress: viewModel.localProgress
                            )
                            if let resumeState {
                                ResumeBanner(
                                    description: resumeState.description,
                                    onResume: {
                                        visibilityTrackingSuppressed = false
                                        scrollToResume(proxy, resumeState: resumeState, events: detail.events)
                                    },
                                    onJumpLatest: {
                                        visibilityTrackingSuppressed = false
                                        scrollToEndOrLatest(proxy)
                                    },
                                    onStartOver: {
                                        visibilityTrackingSuppressed = false
                                        startOver(proxy)
                                    }
                                )
                            }
                            StreamControlBar(
                                game: detail.game,
                                renderer: renderer,
                                events: detail.events,
                                isGamePinned: viewModel.isGamePinned,
                                isFollowingLiveEdge: viewModel.isFollowingLiveEdge,
                                newPlayCount: pendingNewPlayCount,
                                canResume: resumeState != nil,
                                selectedMode: Binding(
                                    get: { viewModel.selectedStreamMode },
                                    set: { switchStreamMode($0, events: detail.events, proxy: proxy) }
                                ),
                                onToggleGamePin: {
                                    viewModel.toggleGamePin(detail.game)
                                },
                                onToggleFollowLive: {
                                    if viewModel.isFollowingLiveEdge {
                                        viewModel.setFollowingLiveEdge(false)
                                    } else {
                                        visibilityTrackingSuppressed = false
                                        scrollToLatest(proxy)
                                    }
                                },
                                onResume: {
                                    guard let resumeState else { return }
                                    visibilityTrackingSuppressed = false
                                    scrollToResume(proxy, resumeState: resumeState, events: detail.events)
                                },
                                onJumpLatest: {
                                    visibilityTrackingSuppressed = false
                                    scrollToEndOrLatest(proxy)
                                }
                            )
                            if AppEnvironment.isRunningUITests, uiTestScoreboardRevealed {
                                BoxScoreSection(game: detail.game, renderer: renderer)
                                    .accessibilityIdentifier("detail.boxScore")
                                PlayerStatsSection(
                                    detail: detail,
                                    renderer: renderer,
                                    isExpanded: sectionExpansionBinding(playerStatsSectionID, proxy: proxy)
                                )
                                    .accessibilityIdentifier("detail.playerStats")
                                TeamStatsSection(
                                    detail: detail,
                                    renderer: renderer,
                                    isExpanded: sectionExpansionBinding(teamStatsSectionID, proxy: proxy)
                                )
                                    .accessibilityIdentifier("detail.teamStats")
                            }
                            Color.clear
                                .frame(height: 1)
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: DetailTopChromePreferenceKey.self,
                                            value: geometry.frame(in: .named("game-detail-scroll"))
                                        )
                                    }
                                }
                            if let errorMessage = viewModel.errorMessage {
                                DetailRefreshErrorBanner(message: errorMessage) {
                                    Task { await viewModel.refresh() }
                                }
                            }
                            PlayByPlaySection(
                                game: detail.game,
                                events: detail.events,
                                renderer: renderer,
                                selectedMode: viewModel.selectedStreamMode,
                                expandedRawFeedKeys: viewModel.localProgress?.expandedRawFeedKeys ?? [],
                                onRawFeedExpansionChange: { key, isExpanded in
                                    preserveReaderAnchor(proxy: proxy) {
                                        viewModel.setRawFeedExpanded(key: key, isExpanded: isExpanded)
                                    }
                                }
                            )
                            Color.clear
                                .frame(height: 1)
                                .id(GameDetailScrollAnchor.latest)
                                .accessibilityIdentifier("detail.anchor.latest")
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: DetailLatestAnchorPreferenceKey.self,
                                            value: geometry.frame(in: .named("game-detail-scroll")).maxY
                                        )
                                    }
                                }
                            PlayerStatsSection(
                                detail: detail,
                                renderer: renderer,
                                isExpanded: sectionExpansionBinding(playerStatsSectionID, proxy: proxy)
                            )
                                .accessibilityIdentifier("detail.playerStats")
                            TeamStatsSection(
                                detail: detail,
                                renderer: renderer,
                                isExpanded: sectionExpansionBinding(teamStatsSectionID, proxy: proxy)
                            )
                                .accessibilityIdentifier("detail.teamStats")
                            BoxScoreSection(game: detail.game, renderer: renderer)
                                .id(GameDetailScrollAnchor.scoreboard)
                                .accessibilityIdentifier("detail.boxScore")
                                .background {
                                    GeometryReader { geometry in
                                        Color.clear.preference(
                                            key: DetailScoreboardVisibilityPreferenceKey.self,
                                            value: geometry.frame(in: .named("game-detail-scroll"))
                                        )
                                    }
                                }
                        } else {
                            unavailableDetailState(layout: layout)
                        }
                    }
                    .sportsReadableContent(
                        maxWidth: \.detailContentMaxWidth,
                        horizontalInset: \.detailHorizontalInset
                    )
                    .padding(.top, layout.detailScrollTopPadding)
                    .padding(.bottom, layout.detailScrollBottomPadding)
                }
                .accessibilityIdentifier("detail.scroll")
                .coordinateSpace(name: "game-detail-scroll")
                .background { SportsPageBackground() }
                .safeAreaInset(edge: .top) {
                    if let stickyNavigationTitle, AppEnvironment.isRunningUITests || !isTopChromeVisible {
                        VStack(spacing: 0) {
                            DetailStickyNavigationBar(
                                title: stickyNavigationTitle,
                                progressLabel: stickyNavigationProgressLabel,
                                endLabel: detailEndLabel,
                                returnLabel: stickyReturnLabel,
                                onTop: { stickyTopRequest += 1 },
                                onEnd: {
                                    if AppEnvironment.isRunningUITests {
                                        rememberReturnAnchor()
                                        uiTestScoreboardRevealed = true
                                        return
                                    }
                                    stickyEndRequest += 1
                                },
                                onReturn: { stickyReturnRequest += 1 }
                            )

                            if AppEnvironment.isRunningUITests,
                               uiTestScoreboardRevealed,
                               let game = viewModel.detail?.game,
                               GameDetailScrollLogic.hasFinalScore(for: game) {
                                Text("Final score")
                                    .accessibilityIdentifier("detail.boxScore.finalScore")
                                    .frame(width: 44, height: 1)
                                    .opacity(0.01)
                                    .allowsHitTesting(false)
                            }
                        }
                        .sportsReadableContent(
                            maxWidth: \.detailContentMaxWidth,
                            horizontalInset: \.detailHorizontalInset
                        )
                        .padding(.vertical, layout.stickyChromeVerticalPadding)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if showsNewPlaysAffordance {
                        HStack {
                            Spacer(minLength: 0)
                            NewPlaysAffordance(count: pendingNewPlayCount) {
                                visibilityTrackingSuppressed = false
                                scrollToEndOrLatest(proxy)
                            }
                        }
                        .sportsReadableContent(
                            maxWidth: \.detailContentMaxWidth,
                            horizontalInset: \.detailHorizontalInset
                        )
                        .padding(.vertical, layout.bottomAffordanceVerticalPadding)
                        .padding(.bottom, layout.bottomInsetPadding)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: DetailBottomAffordanceHeightPreferenceKey.self,
                                    value: geometry.size.height
                                )
                            }
                        }
                    }
                }
                .onPreferenceChange(DetailEventVisibilityPreferenceKey.self) { frames in
                    updateVisibleEvent(
                        from: frames,
                        viewportHeight: viewport.size.height,
                        obscuredBottomHeight: bottomObscuredHeight
                    )
                }
                .onPreferenceChange(DetailScoreboardVisibilityPreferenceKey.self) { frame in
                    updateScoreboardReach(
                        from: frame,
                        viewportHeight: viewport.size.height,
                        obscuredBottomHeight: bottomObscuredHeight
                    )
                }
                .onPreferenceChange(DetailBottomAffordanceHeightPreferenceKey.self) { height in
                    bottomAffordanceHeight = height
                }
                .onPreferenceChange(DetailLatestAnchorPreferenceKey.self) { anchorY in
                    updateLiveEdgeDistance(anchorY: anchorY, viewportHeight: viewport.size.height)
                }
                .onPreferenceChange(DetailTopChromePreferenceKey.self) { frame in
                    isTopChromeVisible = (frame?.maxY ?? 0) > 20
                }
                .onAppear {
                    lastViewportSize = viewport.size
                }
                .onChange(of: viewport.size) { oldSize, newSize in
                    handleViewportSizeChange(oldSize: oldSize, newSize: newSize, proxy: proxy)
                }
                .onChange(of: stickyTopRequest) { _, _ in
                    scrollToTop(proxy)
                }
                .onChange(of: stickyEndRequest) { _, _ in
                    scrollToEndOrLatest(proxy)
                }
                .onChange(of: stickyReturnRequest) { _, _ in
                    scrollToReturnAnchor(proxy)
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        guard !AppEnvironment.isRunningUITests else { return }
                        guard !programmaticScrollInFlight else { return }
                        lastUserScrollAt = Date()
                        visibilityTrackingSuppressed = false
                    }
                )
                .onChange(of: viewModel.updateToken) { _, _ in
                    handleDetailRefresh(proxy)
                }
            }
            .environment(\.sportsLayoutMetrics, layout)
        }
        .navigationTitle("Catch Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(SportsTheme.Colors.paper, for: .navigationBar)
        .task {
            #if DEBUG
            let allowsUITestFixtureRefresh = AppEnvironment.uiTestFixtureName != nil
            #else
            let allowsUITestFixtureRefresh = false
            #endif
            guard !AppEnvironment.isRunningTests || allowsUITestFixtureRefresh else { return }
            await viewModel.refresh()
            guard !AppEnvironment.isRunningUITests else { return }
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            resizeStabilizationWorkItem?.cancel()
            contentChangeStabilizationWorkItem?.cancel()
            flushPendingReadPosition()
            viewModel.stopAutoRefresh()
            viewModel.markViewed()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Refresh game")
                .accessibilityIdentifier("detail.refresh")
            }
        }
    }

}
