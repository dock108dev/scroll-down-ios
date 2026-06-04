import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    private static let logger = Logger(
        subsystem: "com.dock108.scrolldownsports",
        category: "HomeViewModel"
    )
    static let activeAutoRefreshInterval: Duration = .seconds(30)
    static let defaultAutoRefreshInterval: Duration = .seconds(5 * 60)
    private static let activeRefreshLeadTime: TimeInterval = 15 * 60
    private static let activeRefreshGraceTime: TimeInterval = 4 * 60 * 60

    @Published var games: [Game] = []
    @Published var league: LeagueFilter = .all
    @Published var teamQuery = ""
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published private(set) var pinnedGameIds: Set<Int> = []
    @Published private(set) var pinnedGameRecords: [PinnedGameRecord] = []
    @Published private(set) var progressByGameId: [Int: GameProgressRecord] = [:]
    @Published private(set) var separatelyFetchedPinnedGames: [Game] = []
    @Published private(set) var favoriteTeamIds: Set<String> = []

    let gameStateStore: any GameStateStore
    let apiClient: SDAApiClient
    let nowProvider: () -> Date
    let maxMissingPinnedFetches = 8
    private let homePageLimit = 200
    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        apiClient: SDAApiClient = .shared,
        now: @escaping () -> Date = Date.init,
        gameStateStore: any GameStateStore
    ) {
        self.apiClient = apiClient
        self.nowProvider = now
        self.gameStateStore = gameStateStore
        observeLocalGameState()
        hydrateFromPersistedHomeSnapshot()
    }

    var todaySectionID: String {
        "timeline-today"
    }

    var initialHomeAnchorID: String? {
        #if DEBUG
        if let anchor = AppEnvironment.uiTestHomeInitialAnchor {
            return anchor
        }
        #endif
        return homeAnchorID(for: filteredHomeSections)
    }

    var filteredHomeSections: [HomeSection] {
        let query = teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let leagueFiltered = mergedGames.filter { game in
            self.matchesSelectedLeague(game)
        }
        let filtered = query.isEmpty ? leagueFiltered : leagueFiltered.filter { game in
            game.matchesTeamQuery(query)
        }
        return homeSections(for: filtered)
    }

    var hasActiveFilters: Bool {
        league != .all || !teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredVisibleGameCount: Int {
        filteredHomeSections.reduce(0) { $0 + $1.gameCount }
    }

    var hasAnyHomeSourceGames: Bool {
        !mergedGames.isEmpty
    }

    var showsFilteredEmptyState: Bool {
        hasActiveFilters && hasAnyHomeSourceGames && filteredVisibleGameCount == 0
    }

    var showsNoGamesEmptyState: Bool {
        !loading && errorMessage == nil && !hasAnyHomeSourceGames
    }

    private var sortedGames: [Game] {
        games.sorted { left, right in
            if left.scheduledStart != right.scheduledStart {
                return left.scheduledStart < right.scheduledStart
            }
            return left.id < right.id
        }
    }

    private var mergedGames: [Game] {
        let homeGameIds = Set(games.map(\.id))
        let pinnedOnlyGames = separatelyFetchedPinnedGames.filter {
            pinnedGameIds.contains($0.id) && !homeGameIds.contains($0.id)
        }
        return (games + pinnedOnlyGames).sorted { left, right in
            if left.scheduledStart != right.scheduledStart {
                return left.scheduledStart < right.scheduledStart
            }
            return left.id < right.id
        }
    }

    var pinnedGamesInCurrentResults: [Game] {
        sortedGames.filter { pinnedGameIds.contains($0.id) }
    }

    var pinnedRecordsMissingFromCurrentResults: [PinnedGameRecord] {
        let fetchedIds = Set(games.map(\.id))
        return pinnedGameRecords.filter { !fetchedIds.contains($0.gameId) }
    }

    func refresh(silent: Bool = false) async {
        if !silent {
            loading = true
        }
        errorMessage = nil
        do {
            let window = GameWindow.home(now: nowProvider())
            games = try await fetchHomeGames(window: window)
            let fetchedAt = Date()
            separatelyFetchedPinnedGames = []
            if league == .all {
                gameStateStore.saveHomeSnapshot(games: games, windowKey: window.stableKey, fetchedAt: fetchedAt)
            }
            games.forEach { gameStateStore.updatePinnedGame($0) }
            separatelyFetchedPinnedGames = await self.fetchMissingPinnedGames(currentGames: games, fetchedAt: fetchedAt)
            lastUpdated = fetchedAt
        } catch {
            errorMessage = error.localizedDescription
            Self.logger.warning(
                "Home refresh failed silent=\(silent, privacy: .public): \(error.localizedDescription, privacy: .private)"
            )
        }
        loading = false
    }

    private func fetchHomeGames(window: GameWindow) async throws -> [Game] {
        var allGames: [Game] = []
        var offset = 0
        var expectedTotal: Int?

        repeat {
            let page = try await apiClient.fetchGamePage(
                window: window,
                league: league.apiValue,
                limit: homePageLimit,
                offset: offset
            )
            allGames.append(contentsOf: page.games)
            expectedTotal = page.total
            offset += page.returnedCount

            guard page.returnedCount == homePageLimit else { break }
        } while offset < (expectedTotal ?? Int.max)

        return Dictionary(grouping: allGames, by: \.id)
            .compactMap { $0.value.first }
            .sorted { left, right in
                if left.scheduledStart != right.scheduledStart {
                    return left.scheduledStart < right.scheduledStart
                }
                return left.id < right.id
            }
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let interval = self?.autoRefreshInterval ?? Self.activeAutoRefreshInterval
                do {
                    try await Task.sleep(for: interval)
                } catch {
                    Self.logger.info("Home auto-refresh loop cancelled")
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

    var autoRefreshInterval: Duration {
        let now = nowProvider()
        if mergedGames.contains(where: { game in
            guard !game.status.isFinal else { return false }
            if game.status.isLive { return true }
            let timeUntilStart = game.scheduledStart.timeIntervalSince(now)
            return timeUntilStart <= Self.activeRefreshLeadTime
                && timeUntilStart >= -Self.activeRefreshGraceTime
        }) {
            return Self.activeAutoRefreshInterval
        }
        return Self.defaultAutoRefreshInterval
    }

    func isPinned(_ game: Game) -> Bool {
        pinnedGameIds.contains(game.id)
    }

    func togglePin(_ game: Game) {
        gameStateStore.togglePin(game)
    }

    func isFavoriteTeam(_ participant: GameParticipant) -> Bool {
        guard let teamID = participant.favoriteTeamID else { return false }
        return favoriteTeamIds.contains(teamID)
    }

    func toggleFavoriteTeam(_ participant: GameParticipant) {
        guard let teamID = participant.favoriteTeamID else { return }
        gameStateStore.toggleFavoriteTeam(teamId: teamID)
    }

    func clearFilters() {
        league = .all
        teamQuery = ""
    }

    private func observeLocalGameState() {
        gameStateStore.snapshots
            .map { snapshot in
                (
                    snapshot.favoriteTeamIds,
                    Set(snapshot.pinnedGamesById.values.filter(\.isPinned).map(\.gameId)),
                    snapshot.pinnedGamesById.values.sorted { left, right in
                        if left.gameDate != right.gameDate {
                            return left.gameDate < right.gameDate
                        }
                        return left.gameId < right.gameId
                    },
                    snapshot.progressByGameId
                )
            }
            .sink { [weak self] favoriteTeamIds, pinnedIds, pinnedRecords, progressByGameId in
                self?.favoriteTeamIds = favoriteTeamIds
                self?.pinnedGameIds = pinnedIds
                self?.pinnedGameRecords = pinnedRecords
                self?.progressByGameId = progressByGameId
            }
            .store(in: &cancellables)
    }

    private func hydrateFromPersistedHomeSnapshot() {
        guard let snapshot = gameStateStore.snapshot.homeSnapshot,
              snapshot.windowKey == GameWindow.home(now: nowProvider()).stableKey else {
            return
        }
        games = snapshot.games
        lastUpdated = snapshot.fetchedAt
    }
}
