import Combine
import Foundation
import SwiftUI

enum LeagueFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case mlb = "MLB"
    case nba = "NBA"
    case nhl = "NHL"
    case nfl = "NFL"
    case ncaab = "NCAAB"
    case ncaaf = "NCAAF"

    var id: String { rawValue }
    var apiValue: String? { self == .all ? nil : rawValue.lowercased() }
}

struct HomeTimelineSection: Identifiable, Equatable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
    let isToday: Bool
    let games: [HomeGameItem]
}

struct HomeGameItem: Identifiable, Equatable {
    let game: Game
    let isPinned: Bool
    let pinnedRecord: PinnedGameRecord?
    let progress: GameProgressRecord?

    var id: Int { game.id }

    var newEventCount: Int {
        progress?.newEventCount ?? pinnedRecord?.newEventCount ?? 0
    }

    var hasResumeState: Bool {
        guard let progress else { return false }
        return progress.lastReadEventIndex != nil
            || progress.lastReadEventID != nil
            || progress.reachedScoreboard
            || progress.selectedMode != .timeline
    }

    var reachedScoreboard: Bool {
        progress?.reachedScoreboard ?? false
    }
}

enum HomeSection: Identifiable, Equatable {
    case pinned(HomePinnedSection)
    case today(HomeTodaySection)
    case earlier(HomeEarlierSection)

    var id: String {
        switch self {
        case .pinned:
            return "pinned"
        case .today:
            return "today"
        case .earlier:
            return "earlier"
        }
    }

    var gameCount: Int {
        switch self {
        case .pinned(let section):
            return section.games.count
        case .today(let section):
            return section.games.count
        case .earlier(let section):
            return section.dateSections.reduce(0) { $0 + $1.games.count }
        }
    }
}

struct HomePinnedSection: Equatable {
    let title: String
    let games: [HomeGameItem]
}

struct HomeTodaySection: Equatable {
    let id: String
    let date: Date
    let title: String
    let subtitle: String
    let games: [HomeGameItem]
}

struct HomeEarlierSection: Equatable {
    let title: String
    let dateSections: [HomeTimelineSection]
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var league: LeagueFilter = .all
    @Published var teamQuery = ""
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published private(set) var pinnedGameIds: Set<Int> = []
    @Published private(set) var pinnedGameRecords: [PinnedGameRecord] = []
    @Published private(set) var progressByGameId: [Int: GameProgressRecord] = [:]

    let gameStateStore: any GameStateStore
    private let apiClient: SDAApiClient
    private let nowProvider: () -> Date
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
        "today"
    }

    var filteredHomeSections: [HomeSection] {
        let query = teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let leagueFiltered = mergedGames.filter { game in
            matchesSelectedLeague(game)
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

    private var sortedGames: [Game] {
        games.sorted { left, right in
            if left.scheduledStart != right.scheduledStart {
                return left.scheduledStart < right.scheduledStart
            }
            return left.id < right.id
        }
    }

    private var mergedGames: [Game] {
        var gamesById = Dictionary(uniqueKeysWithValues: games.map { ($0.id, $0) })
        for record in pinnedGameRecords where gamesById[record.gameId] == nil {
            gamesById[record.gameId] = Game(pinnedRecord: record)
        }
        return Array(gamesById.values).sorted { left, right in
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
            games = try await apiClient.fetchGames(
                window: window,
                league: league.apiValue,
                limit: 200
            )
            let fetchedAt = Date()
            if league == .all {
                gameStateStore.saveHomeSnapshot(games: games, windowKey: window.stableKey, fetchedAt: fetchedAt)
            }
            games.forEach { gameStateStore.updatePinnedGame($0) }
            lastUpdated = fetchedAt
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5 * 60))
                await self?.refresh(silent: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func isPinned(_ game: Game) -> Bool {
        pinnedGameIds.contains(game.id)
    }

    func togglePin(_ game: Game) {
        gameStateStore.togglePin(game)
    }

    func clearFilters() {
        league = .all
        teamQuery = ""
    }

    private func observeLocalGameState() {
        gameStateStore.snapshots
            .map { snapshot in
                (
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
            .sink { [weak self] pinnedIds, pinnedRecords, progressByGameId in
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

    private func homeSections(for games: [Game]) -> [HomeSection] {
        let today = startOfDay(nowProvider())
        let tomorrow = Calendar.sda.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(24 * 60 * 60)

        let pinned = games
            .filter { pinnedGameIds.contains($0.id) }
            .map(homeItem(for:))
            .sorted(by: sortPinnedItems)
        let pinnedIDs = Set(pinned.map(\.id))

        let nonFutureGames = games.filter { $0.scheduledStart < tomorrow }
        let todayGames = nonFutureGames
            .filter { Calendar.sda.isDate($0.scheduledStart, inSameDayAs: today) }
            .filter { !pinnedIDs.contains($0.id) }
            .sorted(by: sortTodayGames)
            .map(homeItem(for:))

        let earlierGames = nonFutureGames
            .filter { $0.scheduledStart < today }
            .filter { !pinnedIDs.contains($0.id) }
        let earlier = earlierSections(for: earlierGames, today: today)

        var sections: [HomeSection] = []
        if !pinned.isEmpty {
            sections.append(.pinned(HomePinnedSection(title: "Pinned", games: pinned)))
        }
        sections.append(
            .today(
                HomeTodaySection(
                    id: todaySectionID,
                    date: today,
                    title: "Today",
                    subtitle: DateFormatters.daySubtitle.string(from: today),
                    games: todayGames
                )
            )
        )
        if !earlier.isEmpty {
            sections.append(.earlier(HomeEarlierSection(title: "Earlier", dateSections: earlier)))
        }
        return sections
    }

    private func earlierSections(for games: [Game], today: Date) -> [HomeTimelineSection] {
        let grouped = Dictionary(grouping: games) { game in
            startOfDay(game.scheduledStart)
        }

        return grouped.keys.sorted(by: >).map { date in
            let gamesForDate = (grouped[date] ?? [])
                .sorted { left, right in
                    if left.scheduledStart != right.scheduledStart {
                        return left.scheduledStart > right.scheduledStart
                    }
                    return left.id < right.id
                }
                .map(homeItem(for:))

            return HomeTimelineSection(
                id: "earlier-\(sectionID(for: date))",
                date: date,
                title: title(for: date, today: today),
                subtitle: DateFormatters.daySubtitle.string(from: date),
                isToday: false,
                games: gamesForDate
            )
        }
    }

    private func homeItem(for game: Game) -> HomeGameItem {
        HomeGameItem(
            game: game,
            isPinned: pinnedGameIds.contains(game.id),
            pinnedRecord: pinnedGameRecords.first { $0.gameId == game.id },
            progress: progressByGameId[game.id]
        )
    }

    private func sortPinnedItems(_ left: HomeGameItem, _ right: HomeGameItem) -> Bool {
        let now = nowProvider()
        let today = startOfDay(now)
        let leftScore = pinnedScore(left, today: today, now: now)
        let rightScore = pinnedScore(right, today: today, now: now)

        if leftScore != rightScore {
            return leftScore > rightScore
        }
        if left.game.scheduledStart != right.game.scheduledStart {
            return left.game.scheduledStart > right.game.scheduledStart
        }
        return left.id < right.id
    }

    private func pinnedScore(_ item: HomeGameItem, today: Date, now: Date) -> Double {
        let hoursSinceStart = max(0, now.timeIntervalSince(item.game.scheduledStart) / 3600)
        let liveWeight = item.game.status.isLive ? 1_000.0 : 0.0
        let todayWeight = Calendar.sda.isDate(item.game.scheduledStart, inSameDayAs: today) ? 200.0 : 0.0
        let catchupWeight = item.game.status.isPregame ? 0.0 : 120.0
        let recencyWeight = max(0.0, 96.0 - hoursSinceStart)
        let unreadWeight = min(Double(item.newEventCount), 20.0) * 5.0
        return liveWeight + todayWeight + catchupWeight + recencyWeight + unreadWeight
    }

    private func sortTodayGames(_ left: Game, _ right: Game) -> Bool {
        let leftRank = todayRank(left)
        let rightRank = todayRank(right)

        if leftRank != rightRank {
            return leftRank < rightRank
        }

        switch leftRank {
        case 0, 2:
            if left.scheduledStart != right.scheduledStart {
                return left.scheduledStart < right.scheduledStart
            }
        default:
            if left.scheduledStart != right.scheduledStart {
                return left.scheduledStart > right.scheduledStart
            }
        }

        return left.id < right.id
    }

    private func todayRank(_ game: Game) -> Int {
        if game.status.isLive {
            return 0
        }
        if !game.status.isPregame {
            return 1
        }
        return 2
    }

    private func matchesSelectedLeague(_ game: Game) -> Bool {
        guard league != .all else { return true }
        return game.leagueCode.caseInsensitiveCompare(league.rawValue) == .orderedSame
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.sda.startOfDay(for: date)
    }

    private func sectionID(for date: Date) -> String {
        DateFormatters.queryDate.string(from: startOfDay(date))
    }

    private func title(for date: Date, today: Date) -> String {
        if Calendar.sda.isDate(date, inSameDayAs: today) {
            return "Today"
        }
        if let tomorrow = Calendar.sda.date(byAdding: .day, value: 1, to: today),
           Calendar.sda.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        if let yesterday = Calendar.sda.date(byAdding: .day, value: -1, to: today),
           Calendar.sda.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        return DateFormatters.dayTitle.string(from: date)
    }
}

private extension Game {
    func matchesTeamQuery(_ query: String) -> Bool {
        participants
            .flatMap { [$0.name, $0.abbreviation ?? ""] }
        .contains { $0.lowercased().contains(query) }
    }

    init(pinnedRecord: PinnedGameRecord) {
        self.init(
            id: pinnedRecord.gameId,
            sport: Sport(leagueCode: pinnedRecord.sportCode),
            leagueCode: pinnedRecord.leagueCode,
            scheduledStart: pinnedRecord.gameDate,
            localDateLabel: DateFormatters.queryDate.string(from: pinnedRecord.gameDate),
            status: GameStatus(rawValue: pinnedRecord.statusRawValue, isLiveOverride: nil, isFinalOverride: nil),
            participants: [
                GameParticipant(
                    id: "away-\(pinnedRecord.gameId)",
                    role: .away,
                    name: pinnedRecord.awayTeam,
                    abbreviation: pinnedRecord.awayTeamAbbr
                ),
                GameParticipant(
                    id: "home-\(pinnedRecord.gameId)",
                    role: .home,
                    name: pinnedRecord.homeTeam,
                    abbreviation: pinnedRecord.homeTeamAbbr
                )
            ],
            scoreState: ScoreState(
                participantScores: [
                    ParticipantScore(participantID: "away-\(pinnedRecord.gameId)", participantRole: .away, score: pinnedRecord.awayScore),
                    ParticipantScore(participantID: "home-\(pinnedRecord.gameId)", participantRole: .home, score: pinnedRecord.homeScore)
                ]
            ),
            presentation: nil,
            scoreboard: nil,
            progress: GameProgress(
                selectedMode: .timeline,
                periodOrdinal: nil,
                periodLabel: nil,
                clockLabel: nil,
                eventCount: pinnedRecord.summaryPlayCountBaseline,
                lastReadEventID: pinnedRecord.lastReadEventID,
                scrollFallback: nil,
                reachedScoreboard: false,
                updatedAt: pinnedRecord.lastSummaryRefreshAt,
                restoredAt: pinnedRecord.lastViewedAt,
                persistence: nil
            ),
            availableFeatures: GameAvailableFeatures(
                hasTimeline: pinnedRecord.summaryPlayCountBaseline != nil,
                hasStats: true,
                hasScoreboard: true
            )
        )
    }
}
