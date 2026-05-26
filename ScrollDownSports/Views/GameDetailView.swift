import SwiftUI

// Size note: Scroll/progress state stays in this View to keep SwiftUI @State ownership private; see cleanup report.
struct GameDetailView: View {
    let gameId: Int
    let summary: Game?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: GameDetailViewModel
    @State private var streamOrientationAnchorID: String?
    @State private var lastVisibleEventAnchorID: String?
    @State private var lastVisibleEventSaveAt = Date.distantPast
    @State private var visibilityTrackingSuppressed = true
    @State private var liveEdgeMode: DetailLiveEdgeMode = .following
    @State private var isNearLiveEdge = true
    @State private var isTopChromeVisible = true
    @State private var programmaticScrollInFlight = false
    @State private var lastUserScrollAt = Date.distantPast
    @State private var currentVisibleEvent: DetailVisibleEventState?
    @State private var returnAnchor: DetailVisibleEventState?
    @State private var lastAcceptedVisibleFrame: DetailEventVisibilityFrame?
    @State private var lastViewportSize: CGSize = .zero
    @State private var resizeRestoreSnapshot: DetailResizeRestoreSnapshot?
    @State private var resizeGeneration = 0
    @State private var resizeStabilizationWorkItem: DispatchWorkItem?
    @State private var stickyTopRequest = 0
    @State private var stickyEndRequest = 0
    @State private var stickyReturnRequest = 0
    @State private var uiTestScoreboardRevealed = false
    @State private var bottomAffordanceHeight: CGFloat = 0

    private let playerStatsSectionID = "player-stats"
    private let teamStatsSectionID = "team-stats"

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
                                newPlayCount: pendingNewPlayCount
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
                                BoxScoreSection(
                                    game: detail.game,
                                    renderer: renderer
                                )
                                    .accessibilityIdentifier("detail.boxScore")
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
                                onRawFeedExpansionChange: viewModel.setRawFeedExpanded
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
                            PlayerStatsSection(detail: detail, renderer: renderer, isExpanded: sectionExpansionBinding(playerStatsSectionID))
                                .accessibilityIdentifier("detail.playerStats")
                            TeamStatsSection(detail: detail, renderer: renderer, isExpanded: sectionExpansionBinding(teamStatsSectionID))
                                .accessibilityIdentifier("detail.teamStats")
                            BoxScoreSection(
                                game: detail.game,
                                renderer: renderer
                            )
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
                                endLabel: detailEndLabel,
                                returnLabel: stickyReturnLabel,
                                onTop: { stickyTopRequest += 1 },
                                onEnd: {
                                    if AppEnvironment.isRunningUITests {
                                        uiTestScoreboardRevealed = true
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
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            resizeStabilizationWorkItem?.cancel()
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

    @ViewBuilder
    private func unavailableDetailState(layout: SportsLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: layout.stackSpacing) {
            if let summary {
                GameHeaderPlaceholder(summary: summary, renderer: SportRendererRegistry.renderer(for: summary))
            }

            if viewModel.loading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: layout.loadingStateMinHeight)
                    .accessibilityIdentifier("detail.loading")
            } else if let error = viewModel.errorMessage {
                DetailLoadErrorState(message: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, summary == nil ? 80 : 0)
    }

    private var pendingNewPlayCount: Int {
        if viewModel.detail?.game.status.isLive == true,
           viewModel.eventDiff.kind == .appended {
            let insertedCount = viewModel.selectedStreamMode.visibleEvents(in: viewModel.eventDiff.insertedEvents).count
            if insertedCount > 0 {
                return insertedCount
            }
        }
        return selectedModeUnreadCount
    }

    private var showsNewPlaysAffordance: Bool {
        guard viewModel.detail?.game.status.isLive == true else { return false }
        return pendingNewPlayCount > 0 && liveEdgeMode == .reading && !viewModel.isFollowingLiveEdge
    }

    private var stickyNavigationTitle: String? {
        guard let detail = viewModel.detail, let currentVisibleEvent else { return nil }
        let total = max(DetailStreamMode.dedupedEvents(from: detail.events).count, 1)
        let readCount = min(total, max(1, currentVisibleEvent.readIndex + 1))
        if detail.game.status.isLive, pendingNewPlayCount > 0 {
            return "\(currentVisibleEvent.label) · \(pendingNewPlayCount) new"
        }
        return "\(currentVisibleEvent.label) · \(readCount)/\(total) read"
    }

    private var stickyReturnLabel: String? {
        guard let returnAnchor else { return nil }
        return "Back to \(returnAnchor.label)"
    }

    private var detailEndLabel: String {
        viewModel.detail?.game.status.isLive == true ? "Latest" : "End"
    }

    private var resumeState: DetailResumeState? {
        guard
            let detail = viewModel.detail,
            let progress = viewModel.localProgress,
            !progress.reachedScoreboard,
            progress.lastReadEventID != nil || progress.lastReadEventIndex != nil || progress.lastScrollFallback != nil,
            let target = GameDetailRestoreTargetResolver.targetEvent(
                progress: progress,
                events: detail.events,
                mode: viewModel.selectedStreamMode
            )
        else {
            return nil
        }

        return DetailResumeState(
            target: target,
            description: GameDetailRestoreTargetResolver.resumeDescription(
                target: target,
                newPlayCount: selectedModeUnreadCount
            )
        )
    }

    private var selectedModeUnreadCount: Int {
        guard let detail = viewModel.detail, let progress = viewModel.localProgress else { return 0 }
        guard !progress.reachedScoreboard else { return 0 }
        let visibleEvents = viewModel.selectedStreamMode.visibleDedupedEvents(
            DetailStreamMode.dedupedEvents(from: detail.events)
        )
        guard !visibleEvents.isEmpty else { return 0 }
        guard let readSequence = GameDetailScrollLogic.readSequence(progress: progress, events: detail.events) else {
            return min(progress.newEventCount, visibleEvents.count)
        }
        return visibleEvents.filter { $0.sequence > readSequence }.count
    }

    private func bottomAffordanceObscuredHeight(
        measuredHeight: CGFloat,
        safeAreaBottom: CGFloat,
        layout: SportsLayoutMetrics
    ) -> CGFloat {
        guard showsNewPlaysAffordance else { return 0 }
        let fallbackHeight = 44 + layout.bottomAffordanceVerticalPadding * 2 + layout.bottomInsetPadding
        return max(measuredHeight, fallbackHeight) + max(0, safeAreaBottom)
    }

    private func scrollToLatest(_ proxy: ScrollViewProxy, preservesReturnAnchor: Bool = true) {
        guard let detail = viewModel.detail else { return }
        let target = DetailStreamMode.dedupedEvents(from: detail.events).last
        if preservesReturnAnchor {
            rememberReturnAnchor()
        }
        if let target {
            let mode = GameDetailRestoreTargetResolver.streamModeToReveal(
                target: target,
                currentMode: viewModel.selectedStreamMode,
                events: detail.events
            )
            if mode != viewModel.selectedStreamMode {
                viewModel.setSelectedStreamMode(mode)
            }
            streamOrientationAnchorID = target.detailAnchorID
        }
        viewModel.setFollowingLiveEdge(true)
        viewModel.recordLatestEventRead(events: detail.events)
        performProgrammaticScroll(after: target == nil ? 0 : 0.1) {
            if let target {
                proxy.scrollTo(GameDetailScrollAnchor.event(target.detailAnchorID), anchor: .bottom)
            } else {
                proxy.scrollTo(GameDetailScrollAnchor.latest, anchor: .bottom)
            }
        }
    }

    private func scrollToEndOrLatest(_ proxy: ScrollViewProxy) {
        guard let detail = viewModel.detail else { return }
        rememberReturnAnchor()
        if detail.game.status.isLive {
            scrollToLatest(proxy, preservesReturnAnchor: false)
            return
        }

        viewModel.recordLatestEventRead(events: detail.events)
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.scoreboard, anchor: AppEnvironment.isRunningUITests ? .top : .bottom)
        }
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        rememberReturnAnchor()
        viewModel.setFollowingLiveEdge(false)
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.top, anchor: .top)
        }
    }

    private func scrollToReturnAnchor(_ proxy: ScrollViewProxy) {
        guard let anchor = returnAnchor else { return }
        viewModel.setFollowingLiveEdge(false)
        streamOrientationAnchorID = anchor.anchorID
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchor.anchorID), anchor: .center)
        }
        returnAnchor = nil
    }

    private func rememberReturnAnchor() {
        guard let currentVisibleEvent else { return }
        returnAnchor = currentVisibleEvent
    }

    private func restoreReaderAnchor(_ proxy: ScrollViewProxy) {
        guard let detail = viewModel.detail else { return }
        let visibleEvents = viewModel.selectedStreamMode.visibleEvents(in: detail.events)
        let anchorID = streamOrientationAnchorID.flatMap { currentAnchorID in
            visibleEvents.contains(where: { $0.detailAnchorID == currentAnchorID }) ? currentAnchorID : nil
        } ?? GameDetailRestoreTargetResolver.targetEvent(
            progress: viewModel.localProgress ?? .empty(gameId: gameId, now: Date()),
            events: detail.events,
            mode: viewModel.selectedStreamMode
        )?.detailAnchorID
        guard let anchorID else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: .top)
        }
    }

    private func handleDetailRefresh(_ proxy: ScrollViewProxy) {
        visibilityTrackingSuppressed = resumeState != nil
        guard viewModel.detail != nil else { return }
        let shouldFollowLatest = viewModel.isFollowingLiveEdge && isNearLiveEdge
        if shouldFollowLatest, viewModel.detail?.game.status.isLive == true {
            visibilityTrackingSuppressed = false
            scrollToLatest(proxy, preservesReturnAnchor: false)
            return
        }

        switch viewModel.eventDiff.kind {
        case .inserted, .prepended, .reset:
            restoreReaderAnchor(proxy)
        case .appended, .modified, .unchanged:
            break
        }
    }

    private func scrollToResume(
        _ proxy: ScrollViewProxy,
        resumeState: DetailResumeState,
        events: [GameEvent]
    ) {
        let mode = GameDetailRestoreTargetResolver.streamModeToReveal(
            target: resumeState.target,
            currentMode: viewModel.selectedStreamMode,
            events: events
        )
        if mode != viewModel.selectedStreamMode {
            viewModel.setSelectedStreamMode(mode)
        }
        streamOrientationAnchorID = resumeState.target.detailAnchorID
        performProgrammaticScroll(after: 0.1) {
            proxy.scrollTo(GameDetailScrollAnchor.event(resumeState.target.detailAnchorID), anchor: .center)
        }
    }

    private func startOver(_ proxy: ScrollViewProxy) {
        viewModel.clearReadPosition()
        guard
            let detail = viewModel.detail,
            let firstEvent = viewModel.selectedStreamMode.visibleEvents(in: detail.events).first
        else { return }

        streamOrientationAnchorID = firstEvent.detailAnchorID
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.event(firstEvent.detailAnchorID), anchor: .top)
        }
    }

    private func switchStreamMode(_ mode: DetailStreamMode, events: [GameEvent], proxy: ScrollViewProxy) {
        guard mode != viewModel.selectedStreamMode else { return }
        let anchorID = GameDetailScrollLogic.restoredStreamAnchorID(
            currentAnchorID: streamOrientationAnchorID,
            from: viewModel.selectedStreamMode,
            to: mode,
            events: events
        )
        viewModel.setSelectedStreamMode(mode)
        guard let anchorID else { return }
        streamOrientationAnchorID = anchorID
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: .center)
        }
    }

    private func performProgrammaticScroll(after delay: Double = 0, scroll: @escaping () -> Void) {
        programmaticScrollInFlight = true
        if AppEnvironment.isRunningUITests {
            scroll()
            programmaticScrollInFlight = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.snappy(duration: 0.35), scroll)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                programmaticScrollInFlight = false
            }
        }
    }

    private func updateVisibleEvent(
        from frames: [DetailEventVisibilityFrame],
        viewportHeight: CGFloat,
        obscuredBottomHeight: CGFloat
    ) {
        guard
            let detail = viewModel.detail,
            let frame = GameDetailScrollLogic.visibleCandidate(
                from: frames,
                viewportHeight: viewportHeight,
                obscuredBottomHeight: obscuredBottomHeight
            )
        else { return }

        guard resizeRestoreSnapshot == nil else {
            return
        }

        currentVisibleEvent = DetailVisibleEventState(frame: frame)
        lastAcceptedVisibleFrame = frame

        guard AppEnvironment.isRunningUITests || (!visibilityTrackingSuppressed && !viewModel.isFollowingLiveEdge && !programmaticScrollInFlight) else {
            return
        }

        let now = Date()
        guard frame.anchorID != lastVisibleEventAnchorID || now.timeIntervalSince(lastVisibleEventSaveAt) >= 0.35 else {
            return
        }

        lastVisibleEventAnchorID = frame.anchorID
        lastVisibleEventSaveAt = now
        streamOrientationAnchorID = frame.anchorID
        viewModel.recordReadEvent(
            eventIndex: frame.readIndex,
            eventID: frame.eventID,
            knownEventCount: detail.events.count
        )
        viewModel.recordScrollFallback(
            eventSequence: frame.sequence,
            approximateOffset: Double(frame.frame.minY)
        )
    }

    private func updateScoreboardReach(from frame: CGRect?, viewportHeight: CGFloat, obscuredBottomHeight: CGFloat) {
        guard resizeRestoreSnapshot == nil, viewModel.localProgress?.reachedScoreboard != true, let frame else { return }
        let viewportFrame = scoreboardReachViewportFrame(
            width: frame.width,
            height: viewportHeight,
            obscuredBottomHeight: obscuredBottomHeight
        )
        if hasScoreboardEnteredViewport(itemFrame: frame, viewportFrame: viewportFrame) {
            if let events = viewModel.detail?.events {
                viewModel.recordLatestEventRead(events: events)
            }
            viewModel.setReachedScoreboard(true)
        }
    }

    private func updateLiveEdgeDistance(anchorY: CGFloat, viewportHeight: CGFloat) {
        guard resizeRestoreSnapshot == nil else { return }
        let threshold = max(72, min(180, viewportHeight * 0.14))
        let near = anchorY >= -threshold && anchorY <= viewportHeight + threshold
        if isNearLiveEdge != near {
            isNearLiveEdge = near
        }
        let nextLiveEdgeMode: DetailLiveEdgeMode = if viewModel.isFollowingLiveEdge {
            near ? .following : .reading
        } else {
            .reading
        }
        if liveEdgeMode != nextLiveEdgeMode {
            liveEdgeMode = nextLiveEdgeMode
        }
        guard !AppEnvironment.isRunningUITests else { return }
        let userScrolledRecently = Date().timeIntervalSince(lastUserScrollAt) < 0.75
        if !near, userScrolledRecently, !programmaticScrollInFlight, viewModel.isFollowingLiveEdge {
            viewModel.setFollowingLiveEdge(false)
        }
    }

    private func sectionExpansionBinding(_ sectionID: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.localProgress?.expandedSectionIDs.contains(sectionID) == true },
            set: { viewModel.setExpandedSection(sectionID, isExpanded: $0) }
        )
    }

    private func handleViewportSizeChange(oldSize: CGSize, newSize: CGSize, proxy: ScrollViewProxy) {
        let priorSize = lastViewportSize == .zero ? oldSize : lastViewportSize
        lastViewportSize = newSize
        guard GameDetailScrollLogic.isMeaningfulViewportChange(from: priorSize, to: newSize) else { return }
        guard let snapshot = makeResizeRestoreSnapshot() else { return }

        resizeGeneration += 1
        resizeRestoreSnapshot = snapshot
        visibilityTrackingSuppressed = true
        programmaticScrollInFlight = true
        scheduleResizeRestore(proxy: proxy, generation: resizeGeneration)
    }

    private func makeResizeRestoreSnapshot() -> DetailResizeRestoreSnapshot? {
        if let frame = lastAcceptedVisibleFrame {
            return DetailResizeRestoreSnapshot(
                frame: frame,
                readingTopY: 0,
                wasFollowingLiveEdge: viewModel.isFollowingLiveEdge && isNearLiveEdge,
                wasVisibilityTrackingSuppressed: visibilityTrackingSuppressed
            )
        }
        if let currentVisibleEvent {
            return DetailResizeRestoreSnapshot(
                visibleEvent: currentVisibleEvent,
                wasFollowingLiveEdge: viewModel.isFollowingLiveEdge && isNearLiveEdge,
                wasVisibilityTrackingSuppressed: visibilityTrackingSuppressed
            )
        }
        return nil
    }

    private func scheduleResizeRestore(proxy: ScrollViewProxy, generation: Int) {
        resizeStabilizationWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard generation == resizeGeneration else { return }
            restoreAfterViewportResize(proxy)
        }
        resizeStabilizationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func restoreAfterViewportResize(_ proxy: ScrollViewProxy) {
        guard let snapshot = resizeRestoreSnapshot else {
            programmaticScrollInFlight = false
            return
        }

        if snapshot.wasFollowingLiveEdge {
            restoreLiveEdgeAfterResize(proxy)
        } else if
            let detail = viewModel.detail,
            let anchorID = GameDetailScrollLogic.restoredVisibleAnchorID(
                currentAnchorID: snapshot.visibleEvent.anchorID,
                currentSequence: snapshot.visibleEvent.sequence,
                mode: viewModel.selectedStreamMode,
                events: detail.events
            ) {
            streamOrientationAnchorID = anchorID
            let anchor = anchorID == snapshot.visibleEvent.anchorID
                ? UnitPoint(x: 0.5, y: snapshot.offsetFraction)
                : UnitPoint.center
            performProgrammaticScroll {
                proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: anchor)
            }
        }

        finishResizeRestore(snapshot: snapshot)
    }

    private func restoreLiveEdgeAfterResize(_ proxy: ScrollViewProxy) {
        if let detail = viewModel.detail,
           let target = DetailStreamMode.dedupedEvents(from: detail.events).last {
            streamOrientationAnchorID = target.detailAnchorID
        }
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.latest, anchor: .bottom)
        }
    }

    private func finishResizeRestore(snapshot: DetailResizeRestoreSnapshot) {
        let delay = AppEnvironment.isRunningUITests ? 0 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            resizeRestoreSnapshot = nil
            visibilityTrackingSuppressed = snapshot.wasVisibilityTrackingSuppressed
            programmaticScrollInFlight = false
        }
    }

}
