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

    func fetchCompactMomentPbp(momentId: StringOrInt) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 120_000_000) // 120ms

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

    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        return MockLoader.load("related-posts")
    }

    func fetchMoments(gameId: Int) async throws -> MomentsResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Generate moments from game detail if available
        if let detail = gameCache[gameId] {
            return generateMoments(from: detail, gameId: gameId)
        }
        
        // Try to generate detail if not in cache
        if let gameSummary = findGameSummary(for: gameId) {
            let detail = MockDataGenerator.generateGameDetail(from: gameSummary)
            gameCache[gameId] = detail
            return generateMoments(from: detail, gameId: gameId)
        }
        
        // Fallback to empty moments
        return MomentsResponse(
            gameId: gameId,
            generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
            moments: [],
            totalCount: 0,
            highlightCount: 0
        )
    }
    
    /// Generate moments from game detail
    /// Partitions plays into meaningful segments based on scoring patterns
    private func generateMoments(from detail: GameDetailResponse, gameId: Int) -> MomentsResponse {
        let plays = detail.plays
        guard !plays.isEmpty else {
            return MomentsResponse(
                gameId: gameId,
                generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
                moments: [],
                totalCount: 0,
                highlightCount: 0
            )
        }
        
        var moments: [Moment] = []
        let playsByQuarter = Dictionary(grouping: plays, by: { $0.quarter ?? 1 })
        let sortedQuarters = playsByQuarter.keys.sorted()
        
        for quarter in sortedQuarters {
            guard let quarterPlays = playsByQuarter[quarter]?.sorted(by: { $0.playIndex < $1.playIndex }) else {
                continue
            }
            
            // Generate 2-4 moments per quarter
            let momentCount = min(4, max(2, quarterPlays.count / 15))
            let playsPerMoment = quarterPlays.count / momentCount
            
            for momentIndex in 0..<momentCount {
                let startIndex = momentIndex * playsPerMoment
                let endIndex = (momentIndex == momentCount - 1) ? quarterPlays.count - 1 : (momentIndex + 1) * playsPerMoment - 1
                
                guard startIndex <= endIndex && startIndex < quarterPlays.count else { continue }
                
                let momentPlays = Array(quarterPlays[startIndex...min(endIndex, quarterPlays.count - 1)])
                guard let firstPlay = momentPlays.first, let lastPlay = momentPlays.last else { continue }
                
                // Determine moment type based on scoring pattern
                let (momentType, isNotable, note) = determineMomentType(
                    plays: momentPlays,
                    quarter: quarter,
                    momentIndex: momentIndex,
                    isLastMoment: momentIndex == momentCount - 1
                )
                
                // Extract player contributions
                let players = extractPlayerContributions(from: momentPlays)
                
                // Build clock string
                let startClock = firstPlay.gameClock ?? "12:00"
                let endClock = lastPlay.gameClock ?? "0:00"
                let clockString = "Q\(quarter) \(startClock)-\(endClock)"
                
                // Build score strings
                let scoreStart = formatScore(home: firstPlay.homeScore, away: firstPlay.awayScore)
                let scoreEnd = formatScore(home: lastPlay.homeScore, away: lastPlay.awayScore)
                
                // Get teams involved
                let teams = Array(Set(momentPlays.compactMap { $0.teamAbbreviation }))
                
                let moment = Moment(
                    id: "m_q\(quarter)_\(momentIndex)",
                    type: momentType,
                    startPlay: firstPlay.playIndex,
                    endPlay: lastPlay.playIndex,
                    playCount: momentPlays.count,
                    teams: teams,
                    players: players,
                    scoreStart: scoreStart,
                    scoreEnd: scoreEnd,
                    clock: clockString,
                    isNotable: isNotable,
                    note: note,
                    runInfo: nil,
                    ladderTierBefore: nil,
                    ladderTierAfter: nil,
                    teamInControl: nil,
                    keyPlayIds: nil
                )
                moments.append(moment)
            }
        }
        
        let highlightCount = moments.filter { $0.isNotable }.count
        
        return MomentsResponse(
            gameId: gameId,
            generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
            moments: moments,
            totalCount: moments.count,
            highlightCount: highlightCount
        )
    }
    
    private func determineMomentType(
        plays: [PlayEntry],
        quarter: Int,
        momentIndex: Int,
        isLastMoment: Bool
    ) -> (MomentType, Bool, String?) {
        // Last moment of Q4 or OT is CLOSING_CONTROL
        if (quarter >= 4) && isLastMoment {
            return (.closingControl, true, "Closing time")
        }
        
        // First moment of a period is OPENER
        if momentIndex == 0 {
            return (.opener, quarter == 1, quarter == 1 ? "Game starts" : nil)
        }
        
        // Check for lead changes (FLIP)
        var leadChanges = 0
        var lastLead: Int? = nil
        for play in plays {
            if let home = play.homeScore, let away = play.awayScore {
                let currentLead = home - away
                if let last = lastLead, (last > 0 && currentLead < 0) || (last < 0 && currentLead > 0) {
                    leadChanges += 1
                }
                lastLead = currentLead
            }
        }
        
        if leadChanges >= 1 {
            return (.flip, true, "Lead changes hands")
        }
        
        // Check for scoring runs (8+ point swing)
        var homeRun = 0
        var awayRun = 0
        var lastHomeScore = plays.first?.homeScore ?? 0
        var lastAwayScore = plays.first?.awayScore ?? 0
        
        for play in plays {
            if let home = play.homeScore, let away = play.awayScore {
                let homeDelta = home - lastHomeScore
                let awayDelta = away - lastAwayScore
                
                if homeDelta > 0 && awayDelta == 0 {
                    homeRun += homeDelta
                    awayRun = 0
                } else if awayDelta > 0 && homeDelta == 0 {
                    awayRun += awayDelta
                    homeRun = 0
                }
                
                lastHomeScore = home
                lastAwayScore = away
            }
        }
        
        if homeRun >= 8 || awayRun >= 8 {
            let runPoints = max(homeRun, awayRun)
            // Determine if building lead or cutting deficit
            if let firstHome = plays.first?.homeScore, let firstAway = plays.first?.awayScore {
                let leadingTeamScoring = (homeRun >= 8 && firstHome > firstAway) || (awayRun >= 8 && firstAway > firstHome)
                if leadingTeamScoring {
                    return (.leadBuild, true, "\(runPoints)-0 run extends lead")
                } else {
                    return (.cut, true, "\(runPoints)-0 run cuts deficit")
                }
            }
            return (.leadBuild, true, "\(runPoints)-0 run")
        }
        
        // Check for tie
        if let lastHome = plays.last?.homeScore, let lastAway = plays.last?.awayScore, lastHome == lastAway {
            if let firstHome = plays.first?.homeScore, let firstAway = plays.first?.awayScore, firstHome != firstAway {
                return (.tie, true, "Game tied")
            }
        }
        
        // Default to NEUTRAL
        return (.neutral, false, nil)
    }
    
    private func extractPlayerContributions(from plays: [PlayEntry]) -> [PlayerContribution] {
        var playerStats: [String: [String: Int]] = [:]
        
        for play in plays {
            guard let playerName = play.playerName else { continue }
            
            if playerStats[playerName] == nil {
                playerStats[playerName] = [:]
            }
            
            // Check if this was a scoring play based on description
            if let desc = play.description?.lowercased() {
                if desc.contains("makes") {
                    if desc.contains("3-pt") || desc.contains("three") {
                        playerStats[playerName]?["pts", default: 0] += 3
                    } else if desc.contains("free throw") {
                        playerStats[playerName]?["pts", default: 0] += 1
                    } else {
                        playerStats[playerName]?["pts", default: 0] += 2
                    }
                }
                if desc.contains("assist") {
                    playerStats[playerName]?["ast", default: 0] += 1
                }
                if desc.contains("steal") {
                    playerStats[playerName]?["stl", default: 0] += 1
                }
                if desc.contains("block") {
                    playerStats[playerName]?["blk", default: 0] += 1
                }
            }
        }
        
        // Convert to PlayerContribution and sort by points
        return playerStats
            .map { name, stats in
                let summary = formatPlayerSummary(stats)
                return PlayerContribution(name: name, stats: stats, summary: summary)
            }
            .sorted { ($0.stats["pts"] ?? 0) > ($1.stats["pts"] ?? 0) }
            .prefix(3)
            .map { $0 }
    }
    
    private func formatPlayerSummary(_ stats: [String: Int]) -> String? {
        var parts: [String] = []
        if let pts = stats["pts"], pts > 0 { parts.append("\(pts) pts") }
        if let ast = stats["ast"], ast > 0 { parts.append("\(ast) ast") }
        if let stl = stats["stl"], stl > 0 { parts.append("\(stl) stl") }
        if let blk = stats["blk"], blk > 0 { parts.append("\(blk) blk") }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    private func formatScore(home: Int?, away: Int?) -> String {
        let h = home ?? 0
        let a = away ?? 0
        return "\(a)-\(h)"
    }

    // MARK: - Helpers

    private func findGameSummary(for gameId: Int) -> GameSummary? {
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

private enum Constants {
    static let emptyTimeline: [Any] = []
}
