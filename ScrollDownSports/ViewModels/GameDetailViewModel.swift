import Combine
import Foundation
import OSLog

@MainActor
final class GameDetailViewModel: ObservableObject {
    static let liveAutoRefreshInterval: Duration = .seconds(30)
    static let finalAutoRefreshInterval: Duration = .seconds(5 * 60)

    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "GameDetailViewModel"
    )
    @Published var detail: GameDetail?
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published private(set) var localProgress: GameProgressRecord?
    @Published private(set) var isGamePinned = false
    @Published private(set) var selectedStreamMode: DetailStreamMode = .key
    @Published private(set) var isFollowingLiveEdge = false
    @Published private(set) var eventDiff = GameEventListDiff.unchanged
    @Published private(set) var updateToken = UUID()
    @Published private(set) var feedGenerationStatus: GameFeedGenerationStatus = .unknown
    @Published private(set) var feedFallbackState: GameFeedFallbackState = .none
    @Published private(set) var isRevealAvailable = false

    let gameId: Int
    let openingNewEventCount: Int
    private let apiClient: SDAApiClient
    private let gameStateStore: any GameStateStore
    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        gameId: Int,
        apiClient: SDAApiClient = .shared,
        gameStateStore: any GameStateStore
    ) {
        self.gameId = gameId
        self.apiClient = apiClient
        self.gameStateStore = gameStateStore
        self.openingNewEventCount = gameStateStore.progress(for: gameId)?.newEventCount ?? 0
        self.localProgress = gameStateStore.progress(for: gameId)
        self.isGamePinned = gameStateStore.isPinned(gameId: gameId)
        self.selectedStreamMode = DetailStreamMode(storageMode: localProgress?.selectedMode ?? .timeline)
        self.isFollowingLiveEdge = localProgress?.followLivePreference.isFollowingLiveEdge == true
        hydrateFromPersistedPinnedState()
        gameStateStore.markViewed(gameId: gameId)
        observeLocalProgress()
    }

    func refresh(silent: Bool = false) async {
        if !silent {
            loading = true
        }
        errorMessage = nil
        do {
            let refreshedDetail = try await apiClient.fetchGame(id: gameId)
            let diff = detail.map { previousDetail in
                GameEventListDiffer.diff(
                    previous: previousDetail.events,
                    current: refreshedDetail.events,
                    baseline: localProgress?.eventIdentityBaseline
                )
            } ?? .unchanged
            detail = refreshedDetail
            applyFeedMetadata(from: refreshedDetail)
            eventDiff = diff
            lastUpdated = Date()
            gameStateStore.updatePinnedGameDetail(refreshedDetail, fetchedAt: lastUpdated ?? Date())
            gameStateStore.recordEventRefresh(gameId: gameId, events: refreshedDetail.events, diff: diff)
            updateToken = UUID()
        } catch {
            errorMessage = error.localizedDescription
            Self.logger.warning(
                "Game detail refresh failed id=\(self.gameId, privacy: .public) silent=\(silent, privacy: .public): \(error.localizedDescription, privacy: .private)"
            )
        }
        loading = false
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval = self?.autoRefreshInterval ?? Self.liveAutoRefreshInterval
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    Self.logger.info("Game detail auto-refresh loop cancelled")
                    break
                }
                await self?.refresh(silent: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func recordReadEvent(eventIndex: Int, eventID: String?, knownEventCount: Int?) {
        gameStateStore.recordReadEvent(
            gameId: gameId,
            eventID: eventID,
            eventIndex: eventIndex,
            knownEventCount: knownEventCount
        )
    }

    func recordLatestEventRead(events: [GameEvent]) {
        let canonicalEvents = DetailStreamMode.dedupedEvents(from: events)
        let duplicateSourceEventIDs = GameEventIdentityBaseline.duplicateSourceEventIDs(in: canonicalEvents)
        guard let latestEvent = canonicalEvents.last else { return }
        gameStateStore.recordReadEvent(
            gameId: gameId,
            eventID: GameEventIdentityResolver.readCursorID(
                for: latestEvent,
                duplicateSourceEventIDs: duplicateSourceEventIDs
            ),
            eventIndex: max(0, canonicalEvents.count - 1),
            knownEventCount: canonicalEvents.count
        )
    }

    func recordScrollFallback(eventSequence: Int?, approximateOffset: Double?) {
        gameStateStore.setScrollFallback(
            gameId: gameId,
            fallback: GameScrollFallbackRecord(
                eventSequence: eventSequence,
                approximateOffset: approximateOffset
            )
        )
    }

    func markViewed() {
        gameStateStore.markViewed(gameId: gameId)
    }

    func clearReadPosition() {
        gameStateStore.clearReadPosition(gameId: gameId)
    }

    func setReachedScoreboard(_ reached: Bool) {
        gameStateStore.setReachedScoreboard(gameId: gameId, reached: reached)
    }

    func setExpandedSection(_ sectionID: String, isExpanded: Bool) {
        var sectionIDs = localProgress?.expandedSectionIDs ?? []
        if isExpanded {
            sectionIDs.insert(sectionID)
        } else {
            sectionIDs.remove(sectionID)
        }
        gameStateStore.setExpandedSectionIDs(gameId: gameId, sectionIDs: sectionIDs)
    }

    func setRawFeedExpanded(key: String, isExpanded: Bool) {
        gameStateStore.setRawFeedExpanded(gameId: gameId, key: key, isExpanded: isExpanded)
    }

    func setFollowLivePreference(_ preference: FollowLivePreference) {
        gameStateStore.setFollowLivePreference(gameId: gameId, preference: preference)
    }

    func setFollowingLiveEdge(_ enabled: Bool) {
        setFollowLivePreference(enabled ? .followingLiveEdge : .readingAwayFromLiveEdge)
    }

    func setSelectedStreamMode(_ mode: DetailStreamMode) {
        gameStateStore.setSelectedMode(gameId: gameId, mode: mode.storageMode)
    }

    func toggleGamePin(_ game: Game) {
        gameStateStore.togglePin(game)
    }

    private func observeLocalProgress() {
        gameStateStore.snapshots
            .map { [gameId] snapshot in
                (
                    snapshot.progressByGameId[gameId],
                    snapshot.pinnedGamesById[gameId]?.isPinned == true
                )
            }
            .sink { [weak self] progress, isGamePinned in
                self?.localProgress = progress
                self?.isGamePinned = isGamePinned
                self?.selectedStreamMode = DetailStreamMode(storageMode: progress?.selectedMode ?? .timeline)
                self?.isFollowingLiveEdge = progress?.followLivePreference.isFollowingLiveEdge == true
            }
            .store(in: &cancellables)
    }

    private func hydrateFromPersistedPinnedState() {
        guard let record = gameStateStore.snapshot.pinnedGamesById[gameId],
              let latestDetail = record.latestDetail else {
            return
        }
        detail = latestDetail
        applyFeedMetadata(from: latestDetail)
        lastUpdated = record.lastBackgroundRefreshAt ?? record.lastSummaryRefreshAt
    }

    private func applyFeedMetadata(from detail: GameDetail) {
        feedGenerationStatus = detail.feedMetadata.generationStatus
        feedFallbackState = detail.feedMetadata.fallbackState
        isRevealAvailable = detail.feedMetadata.revealAvailable
    }

    private var autoRefreshInterval: Duration {
        detail?.game.status.isLive == true ? Self.liveAutoRefreshInterval : Self.finalAutoRefreshInterval
    }
}

private extension FollowLivePreference {
    var isFollowingLiveEdge: Bool {
        switch self {
        case .followingLiveEdge, .pinnedToLiveEdge:
            return true
        case .automatic, .readingAwayFromLiveEdge:
            return false
        }
    }
}
