import SwiftUI

extension GameDetailView {
    @ViewBuilder
    func unavailableDetailState(layout: SportsLayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: layout.stackSpacing) {
            if let summary {
                GameHeaderPlaceholder(summary: summary, renderer: SportRendererRegistry.renderer(for: summary))
            }

            if viewModel.loading {
                DetailLoadingState()
            } else if let error = viewModel.errorMessage {
                DetailLoadErrorState(message: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, summary == nil ? 80 : 0)
    }

    var pendingNewPlayCount: Int {
        if viewModel.detail?.game.status.isLive == true,
           viewModel.eventDiff.kind == .appended {
            let insertedCount = viewModel.selectedStreamMode.visibleEvents(in: viewModel.eventDiff.insertedEvents).count
            if insertedCount > 0 {
                return insertedCount
            }
        }
        return selectedModeUnreadCount
    }

    var showsNewPlaysAffordance: Bool {
        guard viewModel.detail?.game.status.isLive == true else { return false }
        return pendingNewPlayCount > 0 && liveEdgeMode == .reading && !viewModel.isFollowingLiveEdge
    }

    var stickyNavigationTitle: String? {
        guard viewModel.detail != nil else { return nil }
        guard let currentVisibleEvent else {
            return AppEnvironment.isRunningUITests ? "Game controls" : nil
        }
        return currentVisibleEvent.label
    }

    var stickyNavigationProgressLabel: String? {
        guard let detail = viewModel.detail, let currentVisibleEvent else { return nil }
        let total = max(DetailStreamMode.dedupedEvents(from: detail.events).count, 1)
        let readCount = min(total, max(1, currentVisibleEvent.readIndex + 1))
        if detail.game.status.isLive, pendingNewPlayCount > 0 {
            return "\(pendingNewPlayCount) new"
        }
        return "\(readCount)/\(total) read"
    }

    var stickyReturnLabel: String? {
        guard let returnAnchor else { return nil }
        return "Back to \(returnAnchor.label)"
    }

    var detailEndLabel: String {
        viewModel.detail?.game.status.isLive == true ? "Latest" : "End"
    }

    var resumeState: DetailResumeState? {
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

    var selectedModeUnreadCount: Int {
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

    func bottomAffordanceObscuredHeight(
        measuredHeight: CGFloat,
        safeAreaBottom: CGFloat,
        layout: SportsLayoutMetrics
    ) -> CGFloat {
        guard showsNewPlaysAffordance else { return 0 }
        let fallbackHeight = 44 + layout.bottomAffordanceVerticalPadding * 2 + layout.bottomInsetPadding
        return max(measuredHeight, fallbackHeight) + max(0, safeAreaBottom)
    }

    func scrollToLatest(_ proxy: ScrollViewProxy, preservesReturnAnchor: Bool = true) {
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
        performProgrammaticScroll(targetAnchorID: target?.detailAnchorID, after: target == nil ? 0 : 0.1) {
            if let target {
                proxy.scrollTo(GameDetailScrollAnchor.event(target.detailAnchorID), anchor: .bottom)
            } else {
                proxy.scrollTo(GameDetailScrollAnchor.latest, anchor: .bottom)
            }
        }
    }

    func scrollToEndOrLatest(_ proxy: ScrollViewProxy) {
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

    func scrollToTop(_ proxy: ScrollViewProxy) {
        rememberReturnAnchor()
        viewModel.setFollowingLiveEdge(false)
        performProgrammaticScroll {
            proxy.scrollTo(GameDetailScrollAnchor.top, anchor: .top)
        }
    }

    func scrollToReturnAnchor(_ proxy: ScrollViewProxy) {
        guard let anchor = returnAnchor else { return }
        if AppEnvironment.isRunningUITests {
            uiTestScoreboardRevealed = false
        }
        viewModel.setFollowingLiveEdge(false)
        streamOrientationAnchorID = anchor.anchorID
        performProgrammaticScroll(targetAnchorID: anchor.anchorID) {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchor.anchorID), anchor: .center)
        }
        returnAnchor = nil
    }

    func rememberReturnAnchor() {
        returnAnchor = explicitStreamReturnAnchor()
            ?? lastAcceptedVisibleFrame.map(DetailVisibleEventState.init(frame:))
            ?? currentVisibleEvent
    }

    func explicitStreamReturnAnchor() -> DetailVisibleEventState? {
        guard
            let detail = viewModel.detail,
            let streamOrientationAnchorID
        else { return nil }

        let dedupedEvents = DetailStreamMode.dedupedEvents(from: detail.events)
        guard
            let readIndex = dedupedEvents.firstIndex(where: { $0.detailAnchorID == streamOrientationAnchorID }),
            viewModel.selectedStreamMode.visibleDedupedEvents(dedupedEvents).contains(where: { $0.detailAnchorID == streamOrientationAnchorID })
        else { return nil }

        let event = dedupedEvents[readIndex]
        return DetailVisibleEventState(
            anchorID: event.detailAnchorID,
            readIndex: readIndex,
            sequence: event.sequence,
            label: event.resumePositionText
        )
    }

    func restoreReaderAnchor(_ proxy: ScrollViewProxy) {
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
        streamOrientationAnchorID = anchorID
        performProgrammaticScroll(targetAnchorID: anchorID) {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: .top)
        }
    }

    func handleDetailRefresh(_ proxy: ScrollViewProxy) {
        visibilityTrackingSuppressed = resumeState != nil
        guard viewModel.detail != nil else { return }
        let shouldFollowLatest = GameDetailScrollLogic.shouldFollowLiveRefresh(
            isLive: viewModel.detail?.game.status.isLive == true,
            isFollowingLiveEdge: viewModel.isFollowingLiveEdge,
            isNearLiveEdge: isNearLiveEdge
        )
        if shouldFollowLatest {
            visibilityTrackingSuppressed = false
            scrollToLatest(proxy, preservesReturnAnchor: false)
            return
        }

        if GameDetailScrollLogic.shouldRestoreReaderAfterRefresh(viewModel.eventDiff.kind) {
            restoreReaderAfterRefresh(proxy)
        }
    }

    func restoreReaderAfterRefresh(_ proxy: ScrollViewProxy) {
        guard let snapshot = makeContentChangeRestoreSnapshot() else {
            restoreReaderAnchor(proxy)
            return
        }

        prepareContentChangeRestore(snapshot: snapshot)
        scheduleContentChangeRestore(proxy: proxy, generation: contentChangeGeneration)
    }

    func scrollToResume(
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
        performProgrammaticScroll(targetAnchorID: resumeState.target.detailAnchorID, after: 0.1) {
            proxy.scrollTo(GameDetailScrollAnchor.event(resumeState.target.detailAnchorID), anchor: .center)
        }
    }

    func startOver(_ proxy: ScrollViewProxy) {
        viewModel.clearReadPosition()
        guard
            let detail = viewModel.detail,
            let firstEvent = viewModel.selectedStreamMode.visibleEvents(in: detail.events).first
        else { return }

        streamOrientationAnchorID = firstEvent.detailAnchorID
        performProgrammaticScroll(targetAnchorID: firstEvent.detailAnchorID) {
            proxy.scrollTo(GameDetailScrollAnchor.event(firstEvent.detailAnchorID), anchor: .top)
        }
    }

    func switchStreamMode(_ mode: DetailStreamMode, events: [GameEvent], proxy: ScrollViewProxy) {
        guard mode != viewModel.selectedStreamMode else { return }
        let anchorID = GameDetailScrollLogic.restoredStreamAnchorID(
            currentAnchorID: currentStreamAnchorID(for: events),
            from: viewModel.selectedStreamMode,
            to: mode,
            events: events
        )
        viewModel.setSelectedStreamMode(mode)
        guard let anchorID else { return }
        streamOrientationAnchorID = anchorID
        performProgrammaticScroll(targetAnchorID: anchorID) {
            proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: .center)
        }
    }

    func currentStreamAnchorID(for events: [GameEvent]) -> String? {
        let dedupedEvents = DetailStreamMode.dedupedEvents(from: events)
        let visibleEvents = viewModel.selectedStreamMode.visibleDedupedEvents(dedupedEvents)
        if let streamOrientationAnchorID,
           visibleEvents.contains(where: { $0.detailAnchorID == streamOrientationAnchorID }) {
            return streamOrientationAnchorID
        }
        if let lastAcceptedVisibleFrame,
           visibleEvents.contains(where: { $0.detailAnchorID == lastAcceptedVisibleFrame.anchorID }) {
            return lastAcceptedVisibleFrame.anchorID
        }
        if let currentVisibleEvent,
           visibleEvents.contains(where: { $0.detailAnchorID == currentVisibleEvent.anchorID }) {
            return currentVisibleEvent.anchorID
        }
        return nil
    }

    func performProgrammaticScroll(
        targetAnchorID: String? = nil,
        after delay: Double = 0,
        scroll: @escaping () -> Void
    ) {
        programmaticScrollInFlight = true
        programmaticScrollTargetAnchorID = targetAnchorID
        if AppEnvironment.isRunningUITests {
            scroll()
            programmaticScrollInFlight = false
            programmaticScrollTargetAnchorID = nil
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.snappy(duration: 0.35), scroll)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                programmaticScrollInFlight = false
                programmaticScrollTargetAnchorID = nil
            }
        }
    }

    func updateVisibleEvent(
        from frames: [DetailEventVisibilityFrame],
        viewportHeight: CGFloat,
        obscuredBottomHeight: CGFloat
    ) {
        guard
            let detail = viewModel.detail,
            let orientationFrame = GameDetailScrollLogic.visibleCandidate(
                from: frames,
                viewportHeight: viewportHeight,
                obscuredBottomHeight: obscuredBottomHeight
            ),
            let readFrame = GameDetailScrollLogic.readCandidate(
                from: frames,
                viewportHeight: viewportHeight,
                obscuredBottomHeight: obscuredBottomHeight
            )
        else { return }

        guard !isReaderRestoreActive else {
            return
        }

        let reachedProgrammaticTarget = programmaticScrollTargetAnchorID.flatMap { targetAnchorID in
            orientationFrame.anchorID == targetAnchorID || readFrame.anchorID == targetAnchorID ? targetAnchorID : nil
        }
        if programmaticScrollInFlight,
           programmaticScrollTargetAnchorID != nil,
           reachedProgrammaticTarget == nil {
            return
        }
        if reachedProgrammaticTarget != nil {
            programmaticScrollTargetAnchorID = nil
            if AppEnvironment.isRunningUITests {
                programmaticScrollInFlight = false
            }
        }

        let nextVisibleEvent = DetailVisibleEventState(frame: readFrame)
        if currentVisibleEvent != nextVisibleEvent {
            currentVisibleEvent = nextVisibleEvent
        }
        if shouldAcceptVisibleFrameUpdate(orientationFrame) {
            lastAcceptedVisibleFrame = orientationFrame
        }
        streamOrientationAnchorID = reachedProgrammaticTarget ?? orientationFrame.anchorID

        let canRecordRead: Bool
        if AppEnvironment.isRunningUITests {
            canRecordRead = !programmaticScrollInFlight || reachedProgrammaticTarget != nil
        } else {
            canRecordRead = !visibilityTrackingSuppressed
                && !viewModel.isFollowingLiveEdge
                && (!programmaticScrollInFlight || reachedProgrammaticTarget != nil)
        }
        guard canRecordRead else {
            return
        }

        let now = Date()
        guard readFrame.anchorID != lastVisibleEventAnchorID || now.timeIntervalSince(lastVisibleEventSaveAt) >= 0.35 else {
            return
        }

        lastVisibleEventAnchorID = readFrame.anchorID
        lastVisibleEventSaveAt = now
        viewModel.recordReadEvent(
            eventIndex: readFrame.readIndex,
            eventID: readFrame.eventID,
            knownEventCount: DetailStreamMode.dedupedEvents(from: detail.events).count
        )
        viewModel.recordScrollFallback(
            eventSequence: readFrame.sequence,
            approximateOffset: Double(readFrame.frame.minY)
        )
    }

    func shouldAcceptVisibleFrameUpdate(_ frame: DetailEventVisibilityFrame) -> Bool {
        guard let previous = lastAcceptedVisibleFrame else { return true }
        if previous.anchorID != frame.anchorID || previous.sequence != frame.sequence {
            return true
        }
        return abs(previous.frame.minY - frame.frame.minY) >= 24
    }

    func updateScoreboardReach(from frame: CGRect?, viewportHeight: CGFloat, obscuredBottomHeight: CGFloat) {
        guard !isReaderRestoreActive, viewModel.localProgress?.reachedScoreboard != true, let frame else { return }
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

    func updateLiveEdgeDistance(anchorY: CGFloat, viewportHeight: CGFloat) {
        guard !isReaderRestoreActive else { return }
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
}
