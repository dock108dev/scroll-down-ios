import Foundation

struct GameSummaryCapability {
    let canOpenPlayableStream: Bool
    let canCatchUp: Bool
    let canResume: Bool
    let canShowNewPlayCount: Bool
    let canShowScoreRows: Bool
    let shouldHideScoreBehindCue: Bool
    let hasOpenedRecap: Bool
    let readEventCount: Int?
    let knownEventCount: Int
    let estimatedReadingMinutes: Int?
    let remainingReadingMinutes: Int?

    init(
        game: Game,
        phase: HomeGameCardPhase,
        progress: GameProgressRecord?,
        pinnedSummaryPlayCount: Int?,
        reachedScoreboard: Bool
    ) {
        let knownEventCount = max(
            game.progress.eventCount ?? 0,
            progress?.lastKnownEventCount ?? 0,
            pinnedSummaryPlayCount ?? 0
        )
        let hasLocalProgress: Bool
        if let progress {
            hasLocalProgress = progress.lastViewedAt != nil
                || progress.lastReadEventIndex != nil
                || progress.lastReadEventID != nil
                || progress.reachedScoreboard
                || progress.selectedMode != .timeline
        } else {
            hasLocalProgress = false
        }
        let hasPriorPlayableContent = hasLocalProgress && knownEventCount > 0
        let hasTimelineContent = game.availableFeatures.hasTimeline || knownEventCount > 0
        let isPregameWithoutPriorContent = phase == .scheduled && !hasPriorPlayableContent
        let canCatchUp = !isPregameWithoutPriorContent && hasTimelineContent
        let hasOpenedRecap = phase == .final && reachedScoreboard

        self.canOpenPlayableStream = phase == .live && canCatchUp
        self.canCatchUp = phase != .scheduled && canCatchUp
        self.canResume = hasLocalProgress && canCatchUp && !hasOpenedRecap
        self.canShowNewPlayCount = phase != .scheduled || hasPriorPlayableContent
        self.hasOpenedRecap = hasOpenedRecap
        self.shouldHideScoreBehindCue = game.scoreState.hasAnyScore && !reachedScoreboard && (phase == .final || canCatchUp)
        self.canShowScoreRows = game.scoreState.hasAnyScore && !shouldHideScoreBehindCue
        self.readEventCount = progress?.readEventCount
        self.knownEventCount = knownEventCount
        self.estimatedReadingMinutes = Self.readingMinutes(for: knownEventCount)
        let unreadEventCount = max(0, knownEventCount - (progress?.readEventCount ?? 0))
        self.remainingReadingMinutes = progress == nil ? nil : Self.readingMinutes(for: unreadEventCount)
    }

    private static func readingMinutes(for eventCount: Int) -> Int? {
        guard eventCount > 0 else { return nil }
        return max(1, Int(ceil(Double(eventCount) / 12.0)))
    }
}
