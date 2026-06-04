import Foundation

extension HomeViewModel {
    func homeSections(for games: [Game]) -> [HomeSection] {
        let today = self.startOfDay(nowProvider())
        let visibleGames = games.filter { self.isVisibleInDefaultHomeTimeline($0) }

        let pinned = visibleGames
            .filter { pinnedGameIds.contains($0.id) }
            .map { self.homeItem(for: $0) }
            .sorted(by: self.sortPinnedItems)
        let pinnedIDs = Set(pinned.map(\.id))

        let timelineGames = visibleGames
            .filter { !pinnedIDs.contains($0.id) }
        let timeline = self.timelineSections(for: timelineGames, today: today)

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

    func timelineSections(for games: [Game], today: Date) -> [HomeTimelineSection] {
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
        let showsFutureEmptyStates = laterToday.isEmpty && upcoming.isEmpty

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
                games: laterToday,
                emptyState: showsFutureEmptyStates ? .laterToday : nil
            ),
            makeTimelineSection(
                id: "timeline-upcoming",
                title: "Upcoming",
                subtitle: DateFormatters.daySubtitle.string(from: tomorrow),
                date: tomorrow,
                anchorRole: .upcoming,
                games: upcoming,
                emptyState: showsFutureEmptyStates ? .upcoming : nil
            )
        ]
        .compactMap { $0 }
    }

    func makeTimelineSection(
        id: String,
        title: String,
        subtitle: String,
        date: Date,
        anchorRole: HomeTimelineAnchorRole,
        games: [Game],
        emptyState: HomeTimelineEmptyState? = nil
    ) -> HomeTimelineSection? {
        let items = games
            .sorted(by: self.sortTimelineGames)
            .map { self.homeItem(for: $0) }

        guard !items.isEmpty || emptyState != nil else { return nil }

        return HomeTimelineSection(
            id: id,
            date: date,
            title: title,
            subtitle: subtitle,
            anchorRole: anchorRole,
            isToday: Calendar.sda.isDate(date, inSameDayAs: self.startOfDay(nowProvider())),
            games: items,
            emptyState: items.isEmpty ? emptyState : nil
        )
    }

    func homeAnchorID(for sections: [HomeSection]) -> String? {
        let renderedAnchorIDs = sections.renderedAnchorIDs
        func renderedAnchor(_ anchorID: String) -> String? {
            renderedAnchorIDs.contains(anchorID) ? anchorID : nil
        }

        let pinnedSection: HomePinnedSection? = sections.compactMap { section in
            if case .pinned(let pinned) = section {
                return pinned
            }
            return nil
        }.first

        if pinnedSection?.games.contains(where: { $0.newEventCount > 0 }) == true {
            return renderedAnchor("pinned")
        }

        let timelineSections = sections.compactMap { section in
            if case .timeline(let timeline) = section {
                return timeline.dateSections
            }
            return nil
        }.flatMap { $0 }

        for role in [HomeTimelineAnchorRole.live, .laterToday, .upcoming] {
            if let section = timelineSections.first(where: { $0.anchorRole == role }),
               let firstGame = section.games.first,
               let anchor = renderedAnchor(firstGame.homeAnchorID) {
                return anchor
            }
        }

        if let section = timelineSections.first(where: { $0.anchorRole == .today }),
           let latestTodayGame = section.games.last,
           let anchor = renderedAnchor(latestTodayGame.homeAnchorID) {
            return anchor
        }

        if pinnedSection?.games.isEmpty == false {
            return renderedAnchor("pinned")
        }

        for role in [HomeTimelineAnchorRole.yesterday, .olderCatchUp] {
            if let section = timelineSections.first(where: { $0.anchorRole == role }),
               let latestPastGame = section.games.last,
               let anchor = renderedAnchor(latestPastGame.homeAnchorID) {
                return anchor
            }
        }

        return nil
    }

    func isVisibleInDefaultHomeTimeline(_ game: Game) -> Bool {
        guard GameParticipantVisibility.hasConcreteParticipants(game) else { return false }
        if game.status.isPregame {
            return game.scheduledStart >= nowProvider()
        }
        if game.status.isLive {
            return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
        }
        if game.status.isFinal {
            return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
        }
        return game.availableFeatures.hasTimeline || game.availableFeatures.hasScoreboard || game.scoreState.hasAnyScore
    }

    func fetchMissingPinnedGames(currentGames: [Game], fetchedAt: Date) async -> [Game] {
        let fetchedIds = Set(currentGames.map(\.id))
        let records = pinnedGameRecords
            .filter { $0.isPinned && !fetchedIds.contains($0.gameId) }
            .prefix(maxMissingPinnedFetches)

        var fetchedGames: [Game] = []
        for record in records {
            do {
                let detail = try await apiClient.fetchGame(id: record.gameId)
                guard gameStateStore.isPinned(gameId: record.gameId) else { continue }
                gameStateStore.updatePinnedGameDetail(detail, fetchedAt: fetchedAt)
                gameStateStore.updatePinnedGame(detail.game)
                fetchedGames.append(detail.game)
            } catch {
                gameStateStore.recordPinnedGameRefreshFailure(
                    gameId: record.gameId,
                    message: error.localizedDescription,
                    at: fetchedAt
                )
            }
        }
        return fetchedGames
    }

    func homeItem(for game: Game) -> HomeGameItem {
        HomeGameItem(
            game: game,
            isPinned: pinnedGameIds.contains(game.id),
            pinnedRecord: pinnedGameRecords.first { $0.gameId == game.id },
            progress: progressByGameId[game.id],
            favoriteTeamIds: favoriteTeamIds
        )
    }

    func sortPinnedItems(_ left: HomeGameItem, _ right: HomeGameItem) -> Bool {
        let now = nowProvider()
        let today = self.startOfDay(now)
        let leftScore = self.pinnedScore(left, today: today, now: now)
        let rightScore = self.pinnedScore(right, today: today, now: now)

        if leftScore != rightScore {
            return leftScore > rightScore
        }
        if left.game.scheduledStart != right.game.scheduledStart {
            return left.game.scheduledStart > right.game.scheduledStart
        }
        return left.id < right.id
    }

    func pinnedScore(_ item: HomeGameItem, today: Date, now: Date) -> Double {
        let hoursSinceStart = max(0, now.timeIntervalSince(item.game.scheduledStart) / 3600)
        let liveWeight = item.game.status.isLive ? 1_000.0 : 0.0
        let todayWeight = Calendar.sda.isDate(item.game.scheduledStart, inSameDayAs: today) ? 200.0 : 0.0
        let catchupWeight = item.game.status.isPregame ? 0.0 : 120.0
        let recencyWeight = max(0.0, 96.0 - hoursSinceStart)
        let unreadWeight = min(Double(item.newEventCount), 20.0) * 5.0
        return liveWeight + todayWeight + catchupWeight + recencyWeight + unreadWeight
    }

    func sortTimelineGames(_ left: Game, _ right: Game) -> Bool {
        let leftFavorite = left.isFavoriteMatch(favoriteTeamIds: favoriteTeamIds)
        let rightFavorite = right.isFavoriteMatch(favoriteTeamIds: favoriteTeamIds)
        if leftFavorite != rightFavorite {
            return leftFavorite
        }
        if left.scheduledStart != right.scheduledStart {
            return left.scheduledStart < right.scheduledStart
        }
        return left.id < right.id
    }

    func matchesSelectedLeague(_ game: Game) -> Bool {
        guard league != .all else { return true }
        return game.leagueCode.caseInsensitiveCompare(league.rawValue) == .orderedSame
    }

    func startOfDay(_ date: Date) -> Date {
        Calendar.sda.startOfDay(for: date)
    }

    func title(for date: Date, today: Date) -> String {
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

extension Game {
    func matchesTeamQuery(_ query: String) -> Bool {
        participants
            .flatMap { [$0.name, $0.abbreviation ?? ""] }
        .contains { $0.lowercased().contains(query) }
    }

    func isFavoriteMatch(favoriteTeamIds: Set<String>) -> Bool {
        participants.contains { participant in
            guard let teamID = participant.favoriteTeamID else { return false }
            return favoriteTeamIds.contains(teamID)
        }
    }
}
