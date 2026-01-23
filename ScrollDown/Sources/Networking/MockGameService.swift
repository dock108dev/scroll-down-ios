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

    func fetchRelatedPosts(gameId: Int) async throws -> RelatedPostListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        return MockLoader.load("related-posts")
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
            hasCompactStory: false,
            metadata: nil
        )
    }

    /// Generate game story from game detail (Chapters-First Story API)
    private func generateStory(from detail: GameDetailResponse, gameId: Int) -> GameStoryResponse {
        let plays = detail.plays
        let game = detail.game

        // Generate chapters from plays (group by period boundaries)
        let chapters = generateChapters(from: plays)

        // Generate sections from chapters (3-10 narrative beats)
        let sections = generateSections(from: chapters, game: game)

        // Generate compact story narrative
        let compactStory = generateCompactStory(sections: sections, game: game)
        let wordCount = compactStory?.split(separator: " ").count

        // Determine quality based on game characteristics
        let quality: StoryQuality = {
            let highlightCount = sections.filter { $0.isHighlight }.count
            if highlightCount >= 4 { return .high }
            if highlightCount >= 2 { return .medium }
            return .low
        }()

        return GameStoryResponse(
            gameId: gameId,
            sport: game.leagueCode,
            storyVersion: "2.0.0",
            chapters: chapters,
            chapterCount: chapters.count,
            totalPlays: plays.count,
            sections: sections,
            sectionCount: sections.count,
            compactStory: compactStory,
            wordCount: wordCount,
            targetWordCount: quality.targetWordCount,
            quality: quality,
            readingTimeEstimateMinutes: Double(wordCount ?? 0) / 200.0,
            generatedAt: ISO8601DateFormatter().string(from: AppDate.now()),
            hasCompactStory: compactStory != nil,
            metadata: nil
        )
    }

    /// Generate chapters from plays (structural divisions by period)
    private func generateChapters(from plays: [PlayEntry]) -> [ChapterEntry] {
        guard !plays.isEmpty else { return [] }

        var chapters: [ChapterEntry] = []
        let playsByQuarter = Dictionary(grouping: plays, by: { $0.quarter ?? 1 })
        let sortedQuarters = playsByQuarter.keys.sorted()

        for quarter in sortedQuarters {
            guard let quarterPlays = playsByQuarter[quarter]?.sorted(by: { $0.playIndex < $1.playIndex }) else {
                continue
            }

            // Create 2-3 chapters per quarter (split by timeouts/breaks)
            let chapterCount = min(3, max(2, quarterPlays.count / 20))
            let playsPerChapter = quarterPlays.count / chapterCount

            for chapterIndex in 0..<chapterCount {
                let startIndex = chapterIndex * playsPerChapter
                let endIndex = (chapterIndex == chapterCount - 1) ? quarterPlays.count - 1 : (chapterIndex + 1) * playsPerChapter - 1

                guard startIndex <= endIndex && startIndex < quarterPlays.count else { continue }

                let chapterPlays = Array(quarterPlays[startIndex...min(endIndex, quarterPlays.count - 1)])
                guard let firstPlay = chapterPlays.first, let lastPlay = chapterPlays.last else { continue }

                let reasonCodes: [String] = {
                    var codes: [String] = []
                    if chapterIndex == 0 { codes.append("period_start") }
                    if chapterIndex == chapterCount - 1 { codes.append("period_end") }
                    if chapterPlays.count > 15 { codes.append("timeout") }
                    return codes
                }()

                let timeRange: TimeRange? = {
                    if let start = firstPlay.gameClock, let end = lastPlay.gameClock {
                        return TimeRange(start: start, end: end)
                    }
                    return nil
                }()

                let chapter = ChapterEntry(
                    chapterId: "ch_q\(quarter)_\(chapterIndex)",
                    index: chapters.count,
                    playStartIdx: firstPlay.playIndex,
                    playEndIdx: lastPlay.playIndex,
                    playCount: chapterPlays.count,
                    reasonCodes: reasonCodes,
                    period: quarter,
                    timeRange: timeRange,
                    plays: chapterPlays
                )
                chapters.append(chapter)
            }
        }

        return chapters
    }

    /// Generate sections from chapters (3-10 narrative beats)
    private func generateSections(from chapters: [ChapterEntry], game: Game) -> [SectionEntry] {
        guard !chapters.isEmpty else { return [] }

        var sections: [SectionEntry] = []
        let homeTeam = game.homeTeam
        let awayTeam = game.awayTeam

        // Group chapters into 3-8 sections based on scoring patterns
        let targetSectionCount = min(8, max(3, chapters.count / 2))
        let chaptersPerSection = max(1, chapters.count / targetSectionCount)

        for sectionIndex in 0..<targetSectionCount {
            let startChapterIndex = sectionIndex * chaptersPerSection
            let endChapterIndex = min((sectionIndex + 1) * chaptersPerSection - 1, chapters.count - 1)

            guard startChapterIndex <= endChapterIndex else { continue }

            let sectionChapters = Array(chapters[startChapterIndex...endChapterIndex])
            let chapterIds = sectionChapters.map { $0.chapterId }

            // Get all plays in this section
            let sectionPlays = sectionChapters.flatMap { $0.plays }
            guard let firstPlay = sectionPlays.first, let lastPlay = sectionPlays.last else { continue }

            // Calculate scores
            let startScore = ScoreSnapshot(
                home: firstPlay.homeScore ?? 0,
                away: firstPlay.awayScore ?? 0
            )
            let endScore = ScoreSnapshot(
                home: lastPlay.homeScore ?? 0,
                away: lastPlay.awayScore ?? 0
            )

            // Determine beat type and generate header/notes
            let (beatType, header, notes) = determineBeatType(
                plays: sectionPlays,
                sectionIndex: sectionIndex,
                totalSections: targetSectionCount,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                startScore: startScore,
                endScore: endScore
            )

            let section = SectionEntry(
                sectionIndex: sectionIndex,
                beatType: beatType,
                header: header,
                chaptersIncluded: chapterIds,
                startScore: startScore,
                endScore: endScore,
                notes: notes
            )
            sections.append(section)
        }

        return sections
    }

    /// Determine beat type, header, and notes for a section
    private func determineBeatType(
        plays: [PlayEntry],
        sectionIndex: Int,
        totalSections: Int,
        homeTeam: String,
        awayTeam: String,
        startScore: ScoreSnapshot,
        endScore: ScoreSnapshot
    ) -> (BeatType, String, [String]) {
        var notes: [String] = []

        // Calculate scoring differential
        let homeScored = endScore.home - startScore.home
        let awayScored = endScore.away - startScore.away
        let scoringTeam = homeScored > awayScored ? homeTeam : awayTeam
        let leadingTeam = endScore.home > endScore.away ? homeTeam : awayTeam

        // Check for lead changes
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

        // Check for scoring runs
        var maxRun = 0
        var currentRun = 0
        var runTeam = ""
        var lastHome = startScore.home
        var lastAway = startScore.away

        for play in plays {
            if let home = play.homeScore, let away = play.awayScore {
                let homeDelta = home - lastHome
                let awayDelta = away - lastAway

                if homeDelta > 0 && awayDelta == 0 {
                    if runTeam == homeTeam {
                        currentRun += homeDelta
                    } else {
                        currentRun = homeDelta
                        runTeam = homeTeam
                    }
                } else if awayDelta > 0 && homeDelta == 0 {
                    if runTeam == awayTeam {
                        currentRun += awayDelta
                    } else {
                        currentRun = awayDelta
                        runTeam = awayTeam
                    }
                } else {
                    currentRun = 0
                }

                maxRun = max(maxRun, currentRun)
                lastHome = home
                lastAway = away
            }
        }

        // Determine beat type based on patterns
        let beatType: BeatType
        var header: String

        // Last section is CLOSING_SEQUENCE
        if sectionIndex == totalSections - 1 {
            beatType = .closingSequence
            header = "\(leadingTeam) close out the game."
            notes.append("Final stretch of play")
        }
        // High lead changes = BACK_AND_FORTH
        else if leadChanges >= 2 {
            beatType = .backAndForth
            header = "Teams trade the lead in competitive stretch."
            notes.append("\(leadChanges) lead changes")
        }
        // Big scoring run = RUN
        else if maxRun >= 8 {
            beatType = .run
            header = "\(runTeam) go on a \(maxRun)-0 run."
            notes.append("\(maxRun) unanswered points")
        }
        // Early section with fast scoring = FAST_START
        else if sectionIndex == 0 && (homeScored + awayScored) > 20 {
            beatType = .fastStart
            header = "Both teams come out firing."
            notes.append("High-scoring start")
        }
        // Tied score = BACK_AND_FORTH
        else if endScore.home == endScore.away {
            beatType = .backAndForth
            header = "Score tied after back-and-forth play."
            notes.append("Even matchup")
        }
        // One team clearly winning segment = EARLY_CONTROL
        else if abs(homeScored - awayScored) >= 8 {
            beatType = .earlyControl
            header = "\(scoringTeam) take control."
            notes.append("\(scoringTeam) outscore opponents \(max(homeScored, awayScored))-\(min(homeScored, awayScored))")
        }
        // Low scoring = STALL
        else if (homeScored + awayScored) < 10 {
            beatType = .stall
            header = "Scoring slows as defenses tighten."
            notes.append("Defensive stretch")
        }
        // Default = BACK_AND_FORTH
        else {
            beatType = .backAndForth
            header = "Teams trade baskets."
            notes.append("Competitive play continues")
        }

        // Add score note
        notes.append("Score: \(endScore.away)-\(endScore.home)")

        return (beatType, header, notes)
    }

    /// Generate compact story narrative from sections
    private func generateCompactStory(sections: [SectionEntry], game: Game) -> String? {
        guard !sections.isEmpty else { return nil }

        var story = "\(game.awayTeam) visited \(game.homeTeam) in a "

        let highlightCount = sections.filter { $0.isHighlight }.count
        if highlightCount >= 3 {
            story += "thrilling contest"
        } else if highlightCount >= 1 {
            story += "competitive matchup"
        } else {
            story += "regular season game"
        }

        story += ". "

        // Add section summaries
        for section in sections {
            switch section.beatType {
            case .fastStart:
                story += "The game started fast with both teams trading baskets early. "
            case .run:
                story += "\(section.header) "
            case .closingSequence:
                story += "In the closing minutes, the outcome was decided. "
            case .backAndForth:
                if section.sectionIndex == sections.count / 2 {
                    story += "The middle portion saw neither team able to pull away. "
                }
            case .crunchSetup:
                story += "Late in the game, the tension mounted. "
            default:
                break
            }
        }

        if let lastSection = sections.last {
            story += "Final: \(lastSection.endScore.away)-\(lastSection.endScore.home)."
        }

        return story
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
