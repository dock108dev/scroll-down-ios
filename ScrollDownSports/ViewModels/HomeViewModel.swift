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
    let games: [GameSummary]
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var league: LeagueFilter = .all
    @Published var teamQuery = ""
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published private(set) var anchorToken = UUID()

    private let apiClient: SDAApiClient
    private let nowProvider: () -> Date
    private var refreshTask: Task<Void, Never>?

    init(apiClient: SDAApiClient = .shared, now: @escaping () -> Date = Date.init) {
        self.apiClient = apiClient
        self.nowProvider = now
    }

    var todaySectionID: String {
        sectionID(for: nowProvider())
    }

    var filteredTimelineSections: [HomeTimelineSection] {
        let query = teamQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = query.isEmpty ? sortedGames : sortedGames.filter { game in
            game.matchesTeamQuery(query)
        }
        return timelineSections(for: filtered)
    }

    private var sortedGames: [GameSummary] {
        games.sorted { left, right in
            if left.gameDate != right.gameDate {
                return left.gameDate < right.gameDate
            }
            return left.id < right.id
        }
    }

    func refresh(silent: Bool = false) async {
        if !silent {
            loading = true
        }
        errorMessage = nil
        do {
            games = try await apiClient.fetchGames(
                window: GameWindow.current(now: nowProvider()),
                league: league.apiValue,
                limit: 200
            )
            lastUpdated = Date()
            if !silent {
                anchorToken = UUID()
            }
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

    private func timelineSections(for games: [GameSummary]) -> [HomeTimelineSection] {
        let today = startOfDay(nowProvider())
        let grouped = Dictionary(grouping: games) { game in
            startOfDay(game.gameDate)
        }
        var dates = Set(grouped.keys)
        dates.insert(today)

        return dates.sorted().map { date in
            HomeTimelineSection(
                id: sectionID(for: date),
                date: date,
                title: title(for: date, today: today),
                subtitle: DateFormatters.daySubtitle.string(from: date),
                isToday: Calendar.sda.isDate(date, inSameDayAs: today),
                games: grouped[date] ?? []
            )
        }
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

private extension Calendar {
    static var sda: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return calendar
    }
}

private extension GameSummary {
    func matchesTeamQuery(_ query: String) -> Bool {
        [
            homeTeam,
            awayTeam,
            homeTeamAbbr ?? "",
            awayTeamAbbr ?? ""
        ]
        .contains { $0.lowercased().contains(query) }
    }
}
