import Foundation
import SwiftUI

// MARK: - Data Loading

extension HomeView {

    func loadGames(scrollToToday: Bool = true) async {
        errorMessage = nil
        earlierSection.errorMessage = nil
        yesterdaySection.errorMessage = nil
        todaySection.errorMessage = nil
        tomorrowSection.errorMessage = nil

        // 1. Load cached data first (instant UI, no spinners)
        let cache = HomeGameCache.shared
        let hasCachedData = loadCachedSections(from: cache)

        // Show subtle updating indicator when we have cached data
        if hasCachedData {
            isUpdating = true
        }

        // 2. Only show loading spinners if no cached data exists
        if !hasCachedData {
            earlierSection.isLoading = true
            yesterdaySection.isLoading = true
            todaySection.isLoading = true
            tomorrowSection.isLoading = true
        }

        // 3. Fetch fresh data from network
        let service = appConfig.gameService

        async let earlierResult = loadSection(range: .earlier, service: service)
        async let yesterdayResult = loadSection(range: .yesterday, service: service)
        async let todayResult = loadSection(range: .current, service: service)
        async let tomorrowResult = loadSection(range: .tomorrow, service: service)

        let results = await [earlierResult, yesterdayResult, todayResult, tomorrowResult]

        // Bail out if this load was superseded by a newer one
        guard !Task.isCancelled else {
            isUpdating = false
            return
        }

        // 4. Silent swap — apply results + save to cache
        applyHomeSectionResults(results)
        injectTeamMetadataFromSummaries(results)
        updateLastUpdatedAt(from: results)
        saveSectionsToCache(results, cache: cache)

        isUpdating = false

        // 5. Only show global error if ALL sections failed AND no data to display
        let hasAnyData = !earlierSection.games.isEmpty || !yesterdaySection.games.isEmpty
            || !todaySection.games.isEmpty || !tomorrowSection.games.isEmpty
        if results.allSatisfy({ $0.errorMessage != nil }) && !hasAnyData {
            errorMessage = HomeStrings.globalErrorMessage
        }

        if scrollToToday {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .scrollToYesterday, object: nil)
            }
        }
    }

    func loadSection(range: GameRange, service: GameService) async -> HomeSectionResult {
        do {
            let response = try await service.fetchGames(range: range, league: selectedLeague)

            // Beta Admin: Apply snapshot mode filtering if active
            // This excludes live/in-progress games to ensure deterministic replay
            let filteredGames = appConfig.filterGamesForSnapshotMode(response.games)

            return HomeSectionResult(range: range, games: filteredGames, lastUpdatedAt: response.lastUpdatedAt, errorMessage: nil)
        } catch {
            return HomeSectionResult(range: range, games: [], lastUpdatedAt: nil, errorMessage: error.localizedDescription)
        }
    }

    func applyHomeSectionResults(_ results: [HomeSectionResult]) {
        for result in results {
            // Sort games by start time, then league, then away team name
            let sortedGames = result.games.sorted { lhs, rhs in
                // 1. Start time (tip time / puck drop)
                let lhsDate = lhs.parsedGameDate ?? .distantFuture
                let rhsDate = rhs.parsedGameDate ?? .distantFuture
                if lhsDate != rhsDate { return lhsDate < rhsDate }
                // 2. League code
                if lhs.leagueCode != rhs.leagueCode { return lhs.leagueCode < rhs.leagueCode }
                // 3. Away team name
                return lhs.awayTeam < rhs.awayTeam
            }

            switch result.range {
            case .earlier:
                if result.errorMessage == nil {
                    earlierSection.games = sortedGames.reversed()
                }
                earlierSection.errorMessage = earlierSection.games.isEmpty ? result.errorMessage : nil
                earlierSection.isLoading = false
            case .yesterday:
                if result.errorMessage == nil {
                    yesterdaySection.games = sortedGames
                }
                yesterdaySection.errorMessage = yesterdaySection.games.isEmpty ? result.errorMessage : nil
                yesterdaySection.isLoading = false
            case .current:
                if result.errorMessage == nil {
                    todaySection.games = sortedGames
                }
                todaySection.errorMessage = todaySection.games.isEmpty ? result.errorMessage : nil
                todaySection.isLoading = false
            case .tomorrow:
                if result.errorMessage == nil {
                    tomorrowSection.games = sortedGames
                }
                tomorrowSection.errorMessage = tomorrowSection.games.isEmpty ? result.errorMessage : nil
                tomorrowSection.isLoading = false
            case .next24:
                break
            }
        }
    }

    func updateLastUpdatedAt(from results: [HomeSectionResult]) {
        let dates = results.compactMap { parseLastUpdatedAt($0.lastUpdatedAt) }
        lastUpdatedAt = dates.max()
    }

    func parseLastUpdatedAt(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = homeDateFormatterWithFractional.date(from: value) {
            return date
        }
        return homeDateFormatter.date(from: value)
    }

    /// Load cached sections. Returns true if at least one section had cached data.
    /// Skips sections whose cache was written on a different calendar day (US/Eastern),
    /// since time-relative labels like "today" would be wrong.
    func loadCachedSections(from cache: HomeGameCache) -> Bool {
        var hasCachedData = false

        if cache.isSameCalendarDay(range: .earlier, league: selectedLeague),
           let cached = cache.load(range: .earlier, league: selectedLeague) {
            earlierSection.games = cached.games
            earlierSection.isLoading = false
            hasCachedData = true
        }
        if cache.isSameCalendarDay(range: .yesterday, league: selectedLeague),
           let cached = cache.load(range: .yesterday, league: selectedLeague) {
            yesterdaySection.games = cached.games
            yesterdaySection.isLoading = false
            hasCachedData = true
        }
        if cache.isSameCalendarDay(range: .current, league: selectedLeague),
           let cached = cache.load(range: .current, league: selectedLeague) {
            todaySection.games = cached.games
            todaySection.isLoading = false
            hasCachedData = true
        }
        if cache.isSameCalendarDay(range: .tomorrow, league: selectedLeague),
           let cached = cache.load(range: .tomorrow, league: selectedLeague) {
            tomorrowSection.games = cached.games
            tomorrowSection.isLoading = false
            hasCachedData = true
        }

        return hasCachedData
    }

    /// Save successful results to disk cache.
    func saveSectionsToCache(_ results: [HomeSectionResult], cache: HomeGameCache) {
        for result in results where result.errorMessage == nil {
            cache.save(games: result.games, lastUpdatedAt: result.lastUpdatedAt,
                       range: result.range, league: selectedLeague)
        }
    }

    /// Push API-provided team colors and abbreviations from game summaries into shared caches.
    private func injectTeamMetadataFromSummaries(_ results: [HomeSectionResult]) {
        let colorCache = TeamColorCache.shared
        for result in results {
            for game in result.games {
                if let light = game.homeTeamColorLight, let dark = game.homeTeamColorDark {
                    colorCache.inject(teamName: game.homeTeam, lightHex: light, darkHex: dark)
                }
                if let light = game.awayTeamColorLight, let dark = game.awayTeamColorDark {
                    colorCache.inject(teamName: game.awayTeam, lightHex: light, darkHex: dark)
                }
                if let abbr = game.homeTeamAbbr {
                    TeamAbbreviations.inject(teamName: game.homeTeam, abbreviation: abbr)
                }
                if let abbr = game.awayTeamAbbr {
                    TeamAbbreviations.inject(teamName: game.awayTeam, abbreviation: abbr)
                }
            }
        }
    }
}
