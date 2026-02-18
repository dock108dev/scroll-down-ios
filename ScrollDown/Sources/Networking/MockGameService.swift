import Foundation

/// Mock implementation of GameService that generates realistic game data
/// Uses AppDate.now() to create games relative to the dev clock
final class MockGameService: GameService {

    // MARK: - Cache for loaded data
    private var gameCache: [Int: GameDetailResponse] = [:]
    private var generatedGames: [GameSummary]?

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        if let cached = gameCache[id] {
            return cached
        }

        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        guard let gameSummary = generatedGames?.first(where: { $0.id == id }) else {
            throw GameServiceError.notFound
        }

        let response = MockDataGenerator.generateGameDetail(from: gameSummary)
        gameCache[id] = response
        return response
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        var games = generatedGames ?? []

        if let league = league {
            games = games.filter { $0.league == league.rawValue }
        }

        games = filterGames(games, for: range)

        return GameListResponse(
            games: games,
            range: range.rawValue,
            lastUpdatedAt: ISO8601DateFormatter().string(from: AppDate.now())
        )
    }

    /// Client-side range filtering
    /// Uses EST timezone for game date categorization (consistent with RealGameService)
    private func filterGames(_ games: [GameSummary], for range: GameRange) -> [GameSummary] {
        let now = AppDate.now()

        // Use EST for categorization - game dates represent US game calendar dates
        var estCalendar = Calendar(identifier: .gregorian)
        estCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        let todayStart = estCalendar.startOfDay(for: now)
        let todayEnd = estCalendar.date(byAdding: .day, value: 1, to: todayStart)!.addingTimeInterval(-1)
        let yesterdayStart = estCalendar.date(byAdding: .day, value: -1, to: todayStart)!
        let earlierEnd = yesterdayStart

        switch range {
        case .earlier:
            let historyStart = estCalendar.date(byAdding: .day, value: -2, to: todayStart)!
            return games.filter { game in
                guard let gameDate = gameCalendarDate(game, calendar: estCalendar) else { return false }
                return gameDate >= historyStart && gameDate < earlierEnd
            }
        case .yesterday:
            return games.filter { game in
                guard let gameDate = gameCalendarDate(game, calendar: estCalendar) else { return false }
                return gameDate >= yesterdayStart && gameDate < todayStart
            }
        case .current:
            return games.filter { game in
                guard let gameDate = gameCalendarDate(game, calendar: estCalendar) else { return false }
                return gameDate >= todayStart && gameDate <= todayEnd
            }
        case .tomorrow:
            let tomorrowStart = estCalendar.date(byAdding: .day, value: 1, to: todayStart)!
            let tomorrowEnd = estCalendar.date(byAdding: .day, value: 2, to: todayStart)!.addingTimeInterval(-1)
            return games.filter { game in
                guard let gameDate = gameCalendarDate(game, calendar: estCalendar) else { return false }
                return gameDate >= tomorrowStart && gameDate <= tomorrowEnd
            }
        case .next24:
            let windowEnd = now.addingTimeInterval(24 * 60 * 60)
            return games.filter { game in
                guard let gameDate = gameCalendarDate(game, calendar: estCalendar) else { return false }
                return gameDate > now && gameDate <= windowEnd
            }
        }
    }

    /// Extract the game's calendar date, treating the timestamp as the game's local date (EST)
    private func gameCalendarDate(_ game: GameSummary, calendar: Calendar) -> Date? {
        let dateString = game.startTime.prefix(10)  // Extract YYYY-MM-DD
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: String(dateString))
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        if let detail = gameCache[gameId] {
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }

        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }

        return try MockLoader.load("pbp-001")
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        if let detail = gameCache[gameId] {
            let posts = detail.socialPosts.map { entry in
                SocialPostResponse(
                    id: entry.id,
                    gameId: gameId,
                    teamId: entry.teamAbbreviation,
                    postUrl: entry.postUrl,
                    postedAt: entry.postedAt,
                    hasVideo: entry.hasVideo,
                    videoUrl: entry.videoUrl,
                    imageUrl: entry.imageUrl,
                    tweetText: entry.tweetText,
                    sourceHandle: entry.sourceHandle,
                    mediaType: entry.mediaType,
                    revealLevel: .pre,
                    gamePhase: entry.gamePhase,
                    likesCount: entry.likesCount,
                    retweetsCount: entry.retweetsCount,
                    repliesCount: entry.repliesCount
                )
            }
            return SocialPostListResponse(posts: posts, total: posts.count)
        }

        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return try await fetchSocialPosts(gameId: gameId)
        }

        return try MockLoader.load("social-posts")
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        let summaryJson: AnyCodable?
        let timelineJson: AnyCodable

        if let gameSummary = findGameSummary(for: gameId),
           let detail = gameCache[gameId] {
            let summaryText = "\(gameSummary.awayTeamName) and \(gameSummary.homeTeamName) squared off in a competitive matchup. The game featured momentum swings on both sides with key plays defining the outcome."
            summaryJson = AnyCodable(["overall": summaryText])
            timelineJson = AnyCodable(generateUnifiedTimeline(from: detail))
        } else {
            summaryJson = nil
            timelineJson = AnyCodable([])
        }

        return TimelineArtifactResponse(
            gameId: gameId,
            sport: "NBA",
            timelineVersion: "mock-1.0",
            generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
            timelineJson: timelineJson,
            gameAnalysisJson: nil,
            summaryJson: summaryJson
        )
    }

    private func generateUnifiedTimeline(from detail: GameDetailResponse) -> [[String: Any]] {
        var events: [[String: Any]] = []

        for (index, play) in detail.plays.enumerated() {
            var event: [String: Any] = [
                "event_type": "pbp",
                "synthetic_timestamp": "2026-01-13T19:\(String(format: "%02d", index)):00Z"
            ]

            if let quarter = play.quarter { event["period"] = quarter }
            if let clock = play.gameClock { event["game_clock"] = clock }
            if let desc = play.description { event["description"] = desc }
            if let team = play.teamAbbreviation { event["team"] = team }
            if let player = play.playerName { event["player_name"] = player }
            if let home = play.homeScore { event["home_score"] = home }
            if let away = play.awayScore { event["away_score"] = away }

            events.append(event)

            // Interleave tweets at key moments
            if index > 0 && index % 20 == 0 && index / 20 <= detail.socialPosts.count {
                let postIndex = (index / 20) - 1
                if postIndex < detail.socialPosts.count {
                    let post = detail.socialPosts[postIndex]
                    var tweetEvent: [String: Any] = [
                        "event_type": "tweet",
                        "synthetic_timestamp": post.postedAt,
                        "tweet_text": post.tweetText ?? "",
                        "source_handle": post.sourceHandle ?? "team",
                        "tweet_url": post.postUrl
                    ]
                    if let imageUrl = post.imageUrl {
                        tweetEvent["image_url"] = imageUrl
                    }
                    events.append(tweetEvent)
                }
            }
        }

        return events
    }

    func fetchFlow(gameId: Int) async throws -> GameFlowResponse {
        // Mock service doesn't generate flow data - use real API
        throw GameServiceError.notFound
    }

    func fetchTeamColors() async throws -> [TeamSummary] {
        return []
    }

    // MARK: - Helpers

    func findGameSummary(for gameId: Int) -> GameSummary? {
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }
        return generatedGames?.first(where: { $0.id == gameId })
    }

    private func mapPlaysToEvents(_ plays: [PlayEntry], gameId: Int) -> [PbpEvent] {
        plays.map { play in
            PbpEvent(
                id: .int(play.playIndex),
                gameId: .int(gameId),
                period: play.quarter,
                gameClock: play.gameClock,
                elapsedSeconds: nil,
                eventType: play.playType?.rawValue,
                description: play.description,
                team: play.teamAbbreviation,
                teamId: nil,
                playerName: play.playerName,
                playerId: nil,
                homeScore: play.homeScore,
                awayScore: play.awayScore
            )
        }
    }
}
