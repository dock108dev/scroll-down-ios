import Foundation

/// Mock implementation of GameService that generates realistic game data
/// Uses AppDate.now() to create games relative to the dev clock
final class MockGameService: GameService {

    // MARK: - Cache for loaded data
    private var gameCache: [Int: GameDetailResponse] = [:]
    private var generatedGames: [GameSummary]?

    // MARK: - GameService Implementation

    func fetchGame(id: Int) async throws -> GameDetailResponse {
        // Simulate network delay for realistic feel
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Check cache first
        if let cached = gameCache[id] {
            return cached
        }

        // Ensure games are generated
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        // Find the game summary for this ID
        guard let gameSummary = generatedGames?.first(where: { $0.id == id }) else {
            throw GameServiceError.notFound
        }

        // Generate a detail response for this specific game
        let response = MockDataGenerator.generateGameDetail(from: gameSummary)
        gameCache[id] = response
        return response
    }

    func fetchGames(range: GameRange, league: LeagueCode?) async throws -> GameListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Generate games if not cached
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        var games = generatedGames ?? []

        // Apply league filter if specified
        if let league = league {
            games = games.filter { $0.league == league.rawValue }
        }

        games = filterGames(games, for: range)

        return GameListResponse(
            range: range.rawValue,
            games: games,
            total: games.count,
            nextOffset: nil,
            withBoxscoreCount: games.filter { $0.hasBoxscore == true }.count,
            withPlayerStatsCount: games.filter { $0.hasPlayerStats == true }.count,
            withOddsCount: games.filter { $0.hasOdds == true }.count,
            withSocialCount: games.filter { $0.hasSocial == true }.count,
            withPbpCount: games.filter { $0.hasPbp == true }.count,
            lastUpdatedAt: ISO8601DateFormatter().string(from: AppDate.now())
        )
    }

    private func filterGames(_ games: [GameSummary], for range: GameRange) -> [GameSummary] {
        let calendar = Calendar.current
        let todayStart = AppDate.startOfToday
        let todayEnd = AppDate.endOfToday
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let earlierEnd = yesterdayStart

        switch range {
        case .earlier:
            // 2+ days ago
            let historyStart = AppDate.historyWindowStart
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= historyStart && date < earlierEnd
            }
        case .yesterday:
            // 1 day ago
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= yesterdayStart && date < todayStart
            }
        case .current:
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date >= todayStart && date <= todayEnd
            }
        case .next24:
            let now = AppDate.now()
            let windowEnd = now.addingTimeInterval(24 * 60 * 60)
            return games.filter { game in
                guard let date = game.parsedGameDate else { return false }
                return date > now && date <= windowEnd
            }
        }
    }

    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // Use cached detail if available to ensure consistency
        if let detail = gameCache[gameId] {
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }

        // Try to generate detail if not in cache
        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return PbpResponse(events: mapPlaysToEvents(detail.plays, gameId: gameId))
        }

        return MockLoader.load("pbp-001")
    }

    func fetchSocialPosts(gameId: Int) async throws -> SocialPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // Use cached detail if available
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
                    revealLevel: .pre
                )
            }
            return SocialPostListResponse(
                posts: posts,
                total: posts.count
            )
        }

        // Try to generate detail if not in cache
        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return try await fetchSocialPosts(gameId: gameId)
        }

        return MockLoader.load("social-posts")
    }

    func fetchTimeline(gameId: Int) async throws -> TimelineArtifactResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // Generate timeline and summary from game data if available
        let summaryJson: AnyCodable?
        let timelineJson: AnyCodable

        if let gameSummary = findGameSummary(for: gameId),
           let detail = gameCache[gameId] {
            let summaryText = "\(gameSummary.awayTeamName) and \(gameSummary.homeTeamName) squared off in a competitive matchup. The game featured momentum swings on both sides with key plays defining the outcome."
            summaryJson = AnyCodable(["overall": summaryText])

            // Generate unified timeline events from plays and social posts
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

    /// Generate unified timeline events in chronological order
    /// Interleaves PBP plays with tweets — server-provided order
    private func generateUnifiedTimeline(from detail: GameDetailResponse) -> [[String: Any]] {
        var events: [[String: Any]] = []

        // Add PBP events
        for (index, play) in detail.plays.enumerated() {
            var event: [String: Any] = [
                "event_type": "pbp",
                "synthetic_timestamp": "2026-01-13T19:\(String(format: "%02d", index)):00Z"
            ]

            if let quarter = play.quarter {
                event["period"] = quarter
            }
            if let clock = play.gameClock {
                event["game_clock"] = clock
            }
            if let desc = play.description {
                event["description"] = desc
            }
            if let team = play.teamAbbreviation {
                event["team"] = team
            }
            if let player = play.playerName {
                event["player_name"] = player
            }
            if let home = play.homeScore {
                event["home_score"] = home
            }
            if let away = play.awayScore {
                event["away_score"] = away
            }

            events.append(event)

            // Interleave tweets at key moments (every 20 plays)
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

    func fetchStory(gameId: Int) async throws -> GameStoryResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        // Generate story from game detail if available
        if let detail = gameCache[gameId] {
            return generateStory(from: detail, gameId: gameId)
        }

        // Try to generate detail if not in cache
        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return generateStory(from: detail, gameId: gameId)
        }

        // Return minimal response if no game data
        return GameStoryResponse(
            gameId: gameId,
            sport: "NBA",
            storyVersion: "2.0.0",
            chapters: [],
            chapterCount: 0,
            totalPlays: 0,
            sections: [],
            sectionCount: 0,
            compactStory: nil,
            wordCount: nil,
            targetWordCount: nil,
            quality: nil,
            readingTimeEstimateMinutes: nil,
            generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
            hasStory: false,
            hasCompactStory: false,
            metadata: nil
        )
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
