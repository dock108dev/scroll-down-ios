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
    let anchorRole: HomeTimelineAnchorRole
    let isToday: Bool
    let games: [HomeGameItem]
}

enum HomeTimelineAnchorRole: Equatable {
    case olderCatchUp
    case yesterday
    case today
    case live
    case laterToday
    case upcoming
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
    case timeline(HomeTimelineFeedSection)

    var id: String {
        switch self {
        case .pinned:
            return "pinned"
        case .timeline:
            return "timeline"
        }
    }

    var gameCount: Int {
        switch self {
        case .pinned(let section):
            return section.games.count
        case .timeline(let section):
            return section.dateSections.reduce(0) { $0 + $1.games.count }
        }
    }
}

struct HomePinnedSection: Equatable {
    let title: String
    let games: [HomeGameItem]
}

struct HomeTimelineFeedSection: Equatable {
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
        "timeline-today"
    }

    var initialHomeAnchorID: String? {
        homeAnchorID(for: filteredHomeSections)
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
        games.sorted { left, right in
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
        let visibleGames = games.filter(isVisibleInDefaultHomeTimeline)

        let pinned = visibleGames
            .filter { pinnedGameIds.contains($0.id) }
            .map(homeItem(for:))
            .sorted(by: sortPinnedItems)
        let pinnedIDs = Set(pinned.map(\.id))

        let timelineGames = visibleGames
            .filter { !pinnedIDs.contains($0.id) }
        let timeline = timelineSections(for: timelineGames, today: today)

        var sections: [HomeSection] = []
        if !pinned.isEmpty {
            sections.append(.pinned(HomePinnedSection(title: "Pinned", games: pinned)))
        }
        sections.append(
            .timeline(
                HomeTimelineFeedSection(
                    title: "Timeline",
                    dateSections: timeline
                )
            )
        )
        return sections
    }

    private func timelineSections(for games: [Game], today: Date) -> [HomeTimelineSection] {
        let yesterday = Calendar.sda.date(byAdding: .day, value: -1, to: today) ?? today.addingTimeInterval(-24 * 60 * 60)
        let tomorrow = Calendar.sda.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(24 * 60 * 60)
        let now = nowProvider()

        let older = games.filter { $0.scheduledStart < yesterday && !$0.status.isPregame }
        let yesterdayGames = games.filter { Calendar.sda.isDate($0.scheduledStart, inSameDayAs: yesterday) && !$0.status.isPregame }
        let todayCatchUp = games.filter {
            Calendar.sda.isDate($0.scheduledStart, inSameDayAs: today)
                && !$0.status.isLive
                && !$0.status.isPregame
        }
        let live = games.filter(\.status.isLive)
        let laterToday = games.filter {
            Calendar.sda.isDate($0.scheduledStart, inSameDayAs: today)
                && $0.status.isPregame
                && $0.scheduledStart >= now
        }
        let upcoming = games.filter { $0.scheduledStart >= tomorrow && $0.status.isPregame }

        return [
            makeTimelineSection(
                id: "timeline-older",
                title: "Older Catch-Up",
                subtitle: "Last 72 Hours",
                date: yesterday,
                anchorRole: .olderCatchUp,
                games: older
            ),
            makeTimelineSection(
                id: "timeline-yesterday",
                title: "Yesterday",
                subtitle: DateFormatters.daySubtitle.string(from: yesterday),
                date: yesterday,
                anchorRole: .yesterday,
                games: yesterdayGames
            ),
            makeTimelineSection(
                id: todaySectionID,
                title: "Today",
                subtitle: DateFormatters.daySubtitle.string(from: today),
                date: today,
                anchorRole: .today,
                games: todayCatchUp
            ),
            makeTimelineSection(
                id: "timeline-live",
                title: "Live Now",
                subtitle: DateFormatters.daySubtitle.string(from: today),
                date: today,
                anchorRole: .live,
                games: live
            ),
            makeTimelineSection(
                id: "timeline-later-today",
                title: "Later Today",
                subtitle: DateFormatters.daySubtitle.string(from: today),
                date: today,
                anchorRole: .laterToday,
                games: laterToday
            ),
            makeTimelineSection(
                id: "timeline-upcoming",
                title: "Upcoming",
                subtitle: DateFormatters.daySubtitle.string(from: tomorrow),
                date: tomorrow,
                anchorRole: .upcoming,
                games: upcoming
            )
        ]
        .compactMap { $0 }
    }

    private func makeTimelineSection(
        id: String,
        title: String,
        subtitle: String,
        date: Date,
        anchorRole: HomeTimelineAnchorRole,
        games: [Game]
    ) -> HomeTimelineSection? {
        let items = games
            .sorted(by: sortTimelineGames)
            .map(homeItem(for:))

        guard !items.isEmpty else { return nil }

        return HomeTimelineSection(
            id: id,
            date: date,
            title: title,
            subtitle: subtitle,
            anchorRole: anchorRole,
            isToday: Calendar.sda.isDate(date, inSameDayAs: startOfDay(nowProvider())),
            games: items
        )
    }

    private func homeAnchorID(for sections: [HomeSection]) -> String? {
        let pinnedSection: HomePinnedSection? = sections.compactMap { section in
            if case .pinned(let pinned) = section {
                return pinned
            }
            return nil
        }.first

        if pinnedSection?.games.contains(where: { $0.newEventCount > 0 }) == true {
            return "pinned"
        }

        let timelineSections = sections.compactMap { section in
            if case .timeline(let timeline) = section {
                return timeline.dateSections
            }
            return nil
        }.flatMap { $0 }

        if let yesterday = timelineSections.first(where: { $0.anchorRole == .yesterday }) {
            return yesterday.id
        }

        let finalSections = timelineSections.filter { section in
            section.games.contains { $0.game.status.isFinal }
        }
        if let recentFinal = finalSections.max(by: { left, right in
            let leftDate = left.games.filter { $0.game.status.isFinal }.map(\.game.scheduledStart).max() ?? left.date
            let rightDate = right.games.filter { $0.game.status.isFinal }.map(\.game.scheduledStart).max() ?? right.date
            return leftDate < rightDate
        }) {
            return recentFinal.id
        }

        if pinnedSection?.games.isEmpty == false {
            return "pinned"
        }

        for role in [HomeTimelineAnchorRole.live, .today, .laterToday, .upcoming, .olderCatchUp] {
            if let section = timelineSections.first(where: { $0.anchorRole == role }) {
                return section.id
            }
        }

        return nil
    }

    private func isVisibleInDefaultHomeTimeline(_ game: Game) -> Bool {
        guard hasConcreteParticipants(game) else { return false }
        if game.status.isPregame {
            return game.scheduledStart >= nowProvider() && hasUsefulPregamePreview(game)
        }
        if game.status.isLive {
            return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
        }
        if game.status.isFinal {
            return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
        }
        return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
    }

    private func hasConcreteParticipants(_ game: Game) -> Bool {
        guard let away = game.awayParticipant,
              let home = game.homeParticipant else {
            return false
        }
        return isConcreteParticipant(away) && isConcreteParticipant(home)
    }

    private func isConcreteParticipant(_ participant: GameParticipant) -> Bool {
        let name = participant.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let abbreviation = participant.abbreviation?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let placeholderNames: Set<String> = ["", "tbd", "to be determined"]
        let placeholderAbbreviations: Set<String> = ["", "tbd", "tt"]
        if placeholderNames.contains(name) {
            return false
        }
        if let abbreviation,
           placeholderAbbreviations.contains(abbreviation) {
            return false
        }
        return true
    }

    private func hasUsefulPregamePreview(_ game: Game) -> Bool {
        if game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore {
            return true
        }
        if let presentation = game.presentation {
            return [
                presentation.headline,
                presentation.shortHeadline,
                presentation.subheadline,
                presentation.primaryActionLabel,
                presentation.secondaryContextLabel
            ].contains { $0?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
        }
        return false
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

    private func sortTimelineGames(_ left: Game, _ right: Game) -> Bool {
        if left.scheduledStart != right.scheduledStart {
            return left.scheduledStart < right.scheduledStart
        }
        return left.id < right.id
    }

    private func matchesSelectedLeague(_ game: Game) -> Bool {
        guard league != .all else { return true }
        return game.leagueCode.caseInsensitiveCompare(league.rawValue) == .orderedSame
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.sda.startOfDay(for: date)
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
