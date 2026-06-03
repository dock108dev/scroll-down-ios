import SwiftUI

extension GameDetailView {
    var isReaderRestoreActive: Bool {
        resizeRestoreSnapshot != nil || contentChangeRestoreSnapshot != nil
    }

    func sectionExpansionBinding(_ sectionID: String, proxy: ScrollViewProxy) -> Binding<Bool> {
        Binding(
            get: { viewModel.localProgress?.expandedSectionIDs.contains(sectionID) == true },
            set: { isExpanded in
                preserveReaderAnchor(proxy: proxy) {
                    viewModel.setExpandedSection(sectionID, isExpanded: isExpanded)
                }
            }
        )
    }

    func handleViewportSizeChange(oldSize: CGSize, newSize: CGSize, proxy: ScrollViewProxy) {
        let priorSize = lastViewportSize == .zero ? oldSize : lastViewportSize
        lastViewportSize = newSize
        guard GameDetailScrollLogic.isMeaningfulViewportChange(from: priorSize, to: newSize) else { return }
        guard let snapshot = makeResizeRestoreSnapshot() else { return }

        resizeGeneration += 1
        resizeRestoreSnapshot = snapshot
        visibilityTrackingSuppressed = true
        programmaticScrollInFlight = true
        programmaticScrollTargetAnchorID = snapshot.visibleEvent.anchorID
        scheduleResizeRestore(proxy: proxy, generation: resizeGeneration)
    }

    func preserveReaderAnchor(proxy: ScrollViewProxy, mutate: () -> Void) {
        guard let snapshot = makeContentChangeRestoreSnapshot() else {
            mutate()
            return
        }

        prepareContentChangeRestore(snapshot: snapshot)
        mutate()
        scheduleContentChangeRestore(proxy: proxy, generation: contentChangeGeneration)
    }

    func prepareContentChangeRestore(snapshot: DetailContentChangeRestoreSnapshot) {
        contentChangeGeneration += 1
        contentChangeRestoreSnapshot = snapshot
        visibilityTrackingSuppressed = true
        programmaticScrollInFlight = true
        programmaticScrollTargetAnchorID = snapshot.visibleEvent.anchorID
    }

    func makeContentChangeRestoreSnapshot() -> DetailContentChangeRestoreSnapshot? {
        if let frame = lastAcceptedVisibleFrame {
            return DetailContentChangeRestoreSnapshot(
                frame: frame,
                readingTopY: 0,
                wasVisibilityTrackingSuppressed: visibilityTrackingSuppressed
            )
        }
        if let currentVisibleEvent {
            return DetailContentChangeRestoreSnapshot(
                visibleEvent: currentVisibleEvent,
                wasVisibilityTrackingSuppressed: visibilityTrackingSuppressed
            )
        }
        return nil
    }

    func scheduleContentChangeRestore(proxy: ScrollViewProxy, generation: Int) {
        contentChangeStabilizationWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard generation == contentChangeGeneration else { return }
            restoreAfterContentChange(proxy)
        }
        contentChangeStabilizationWorkItem = workItem
        let delay: DispatchTimeInterval = AppEnvironment.isRunningUITests ? .milliseconds(1) : .milliseconds(90)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func restoreAfterContentChange(_ proxy: ScrollViewProxy) {
        guard let snapshot = contentChangeRestoreSnapshot else {
            programmaticScrollInFlight = false
            return
        }

        if
            let detail = viewModel.detail,
            let anchorID = GameDetailScrollLogic.restoredContentChangeAnchorID(
                snapshot: snapshot,
                mode: viewModel.selectedStreamMode,
                events: detail.events
            ) {
            streamOrientationAnchorID = anchorID
            let anchor = anchorID == snapshot.visibleEvent.anchorID
                ? UnitPoint(x: 0.5, y: snapshot.offsetFraction)
                : UnitPoint.center
            performProgrammaticScroll(targetAnchorID: anchorID) {
                proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: anchor)
            }
        }

        finishContentChangeRestore(snapshot: snapshot)
    }

    func finishContentChangeRestore(snapshot: DetailContentChangeRestoreSnapshot) {
        let delay = AppEnvironment.isRunningUITests ? 0 : 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            contentChangeRestoreSnapshot = nil
            visibilityTrackingSuppressed = snapshot.wasVisibilityTrackingSuppressed
            programmaticScrollInFlight = false
            programmaticScrollTargetAnchorID = nil
        }
    }

    func makeResizeRestoreSnapshot() -> DetailResizeRestoreSnapshot? {
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

    func scheduleResizeRestore(proxy: ScrollViewProxy, generation: Int) {
        resizeStabilizationWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard generation == resizeGeneration else { return }
            restoreAfterViewportResize(proxy)
        }
        resizeStabilizationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    func restoreAfterViewportResize(_ proxy: ScrollViewProxy) {
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
            performProgrammaticScroll(targetAnchorID: anchorID) {
                proxy.scrollTo(GameDetailScrollAnchor.event(anchorID), anchor: anchor)
            }
        }

        finishResizeRestore(snapshot: snapshot)
    }

    func restoreLiveEdgeAfterResize(_ proxy: ScrollViewProxy) {
        let target = viewModel.detail.flatMap { DetailStreamMode.dedupedEvents(from: $0.events).last }
        if let target {
            streamOrientationAnchorID = target.detailAnchorID
        }
        performProgrammaticScroll(targetAnchorID: target?.detailAnchorID) {
            proxy.scrollTo(GameDetailScrollAnchor.latest, anchor: .bottom)
        }
    }

    func finishResizeRestore(snapshot: DetailResizeRestoreSnapshot) {
        let delay = AppEnvironment.isRunningUITests ? 0 : 0.55
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            resizeRestoreSnapshot = nil
            visibilityTrackingSuppressed = snapshot.wasVisibilityTrackingSuppressed
            programmaticScrollInFlight = false
            programmaticScrollTargetAnchorID = nil
        }
    }
}
