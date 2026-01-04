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
    
    func fetchGames(league: LeagueCode?, limit: Int, offset: Int) async throws -> GameListResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Generate games if not cached
        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }
        
        var games = generatedGames ?? []
        
        // Apply league filter if specified
        if let league = league {
            games = games.filter { $0.leagueCode == league.rawValue }
        }
        
        return GameListResponse(
            games: games,
            total: games.count,
            nextOffset: nil,
            withBoxscoreCount: games.filter { $0.hasBoxscore == true }.count,
            withPlayerStatsCount: games.filter { $0.hasPlayerStats == true }.count,
            withOddsCount: games.filter { $0.hasOdds == true }.count,
            withSocialCount: games.filter { $0.hasSocial == true }.count,
            withPbpCount: games.filter { $0.hasPbp == true }.count
        )
    }
    
    func fetchPbp(gameId: Int) async throws -> PbpResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
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
        
        return MockLoader.load("social-posts")
    }

    func fetchSummary(gameId: Int) async throws -> AISummaryResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 180_000_000) // 180ms

        if generatedGames == nil {
            generatedGames = MockDataGenerator.generateGames()
        }

        let homeTeam: String?
        let awayTeam: String?
        if let cachedGame = gameCache[gameId]?.game {
            homeTeam = cachedGame.homeTeam
            awayTeam = cachedGame.awayTeam
        } else if let summary = generatedGames?.first(where: { $0.id == gameId }) {
            homeTeam = summary.homeTeam
            awayTeam = summary.awayTeam
        } else {
            homeTeam = nil
            awayTeam = nil
        }

        guard let homeTeam, let awayTeam else {
            throw GameServiceError.notFound
        }

        return AISummaryResponse(summary: MockDataGenerator.generateSummary(homeTeam: homeTeam, awayTeam: awayTeam))
    }
}

// MARK: - Mock Data Generator

private enum MockDataGenerator {
    
    static func generateGames() -> [GameSummary] {
        var games: [GameSummary] = []
        var idCounter = 10000
        
        let calendar = Calendar.current
        let now = AppDate.now()
        
        // Earlier: Nov 10-11 (2 days ago, 1 day ago) - all final
        for daysAgo in [2, 1] {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: AppDate.startOfToday) else { continue }
            let gamesForDay = generateDayGames(
                baseDate: date,
                count: Int.random(in: 4...6),
                idStart: &idCounter,
                allFinal: true
            )
            games.append(contentsOf: gamesForDay)
        }
        
        // Today: Nov 12 - mix of statuses
        let todayGames = generateTodayGames(idStart: &idCounter, currentTime: now)
        games.append(contentsOf: todayGames)
        
        // Upcoming: Nov 13 - all scheduled
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: AppDate.startOfToday) else {
            return games
        }
        let upcomingGames = generateDayGames(
            baseDate: tomorrow,
            count: Int.random(in: 3...5),
            idStart: &idCounter,
            allFinal: false,
            allScheduled: true
        )
        games.append(contentsOf: upcomingGames)
        
        return games
    }

    static func generateSummary(homeTeam: String, awayTeam: String) -> String {
        let opening = "\(awayTeam) and \(homeTeam) kept the pace steady early."
        let middle = "Momentum shifted with timely plays on both ends."
        let close = "Scan the timeline to uncover the defining moments."
        return [opening, middle, close].joined(separator: " ")
    }
    
    private static func generateDayGames(
        baseDate: Date,
        count: Int,
        idStart: inout Int,
        allFinal: Bool,
        allScheduled: Bool = false
    ) -> [GameSummary] {
        var games: [GameSummary] = []
        let calendar = Calendar.current
        
        // Generate games at different times throughout the day
        let hours = [13, 16, 19, 20, 21, 22] // 1pm, 4pm, 7pm, 8pm, 9pm, 10pm
        
        for i in 0..<min(count, hours.count) {
            guard let gameDate = calendar.date(bySettingHour: hours[i], minute: 30, second: 0, of: baseDate) else { continue }
            
            let matchup = randomMatchup()
            let status: GameStatus = allScheduled ? .scheduled : (allFinal ? .completed : .scheduled)
            let hasScores = status == .completed
            
            let game = GameSummary(
                id: idStart,
                leagueCode: matchup.league,
                gameDate: formatDate(gameDate),
                status: status,
                homeTeam: matchup.home,
                awayTeam: matchup.away,
                homeScore: hasScores ? Int.random(in: 85...125) : nil,
                awayScore: hasScores ? Int.random(in: 85...125) : nil,
                hasBoxscore: hasScores,
                hasPlayerStats: hasScores,
                hasOdds: true,
                hasSocial: true,
                hasPbp: hasScores,
                playCount: hasScores ? Int.random(in: 200...400) : 0,
                socialPostCount: Int.random(in: 5...20),
                hasRequiredData: hasScores,
                scrapeVersion: 2,
                lastScrapedAt: hasScores ? formatDate(Date()) : nil
            )
            games.append(game)
            idStart += 1
        }
        
        return games
    }
    
    private static func generateTodayGames(idStart: inout Int, currentTime: Date) -> [GameSummary] {
        var games: [GameSummary] = []
        let calendar = Calendar.current
        let today = AppDate.startOfToday
        
        // Game schedule for today with mixed statuses
        let schedule: [(hour: Int, status: GameStatus)] = [
            (11, .completed),   // Morning game - finished
            (14, .completed),   // Afternoon game - finished
            (17, .inProgress),  // Early evening - live
            (19, .scheduled),   // Evening - not started
            (20, .scheduled),   // Evening - not started
            (22, .scheduled),   // Late - not started
        ]
        
        for (hour, status) in schedule {
            guard let gameDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) else { continue }
            
            let matchup = randomMatchup()
            let hasScores = status == .completed
            let isLive = status == .inProgress
            
            let game = GameSummary(
                id: idStart,
                leagueCode: matchup.league,
                gameDate: formatDate(gameDate),
                status: status,
                homeTeam: matchup.home,
                awayTeam: matchup.away,
                homeScore: (hasScores || isLive) ? Int.random(in: 85...125) : nil,
                awayScore: (hasScores || isLive) ? Int.random(in: 85...125) : nil,
                hasBoxscore: hasScores,
                hasPlayerStats: hasScores,
                hasOdds: true,
                hasSocial: true,
                hasPbp: hasScores || isLive,
                playCount: isLive ? Int.random(in: 100...200) : (hasScores ? Int.random(in: 200...400) : 0),
                socialPostCount: Int.random(in: 5...20),
                hasRequiredData: hasScores,
                scrapeVersion: 2,
                lastScrapedAt: hasScores ? formatDate(Date()) : nil
            )
            games.append(game)
            idStart += 1
        }
        
        return games
    }
    
    private static func randomMatchup() -> (league: String, home: String, away: String) {
        let matchups: [(String, String, String)] = [
            ("NBA", "Boston Celtics", "Los Angeles Lakers"),
            ("NBA", "Miami Heat", "Chicago Bulls"),
            ("NBA", "Golden State Warriors", "Phoenix Suns"),
            ("NBA", "New York Knicks", "Brooklyn Nets"),
            ("NBA", "Denver Nuggets", "Dallas Mavericks"),
            ("NBA", "Milwaukee Bucks", "Philadelphia 76ers"),
            ("NBA", "Atlanta Hawks", "Cleveland Cavaliers"),
            ("NBA", "Memphis Grizzlies", "New Orleans Pelicans"),
            ("NFL", "Kansas City Chiefs", "Buffalo Bills"),
            ("NFL", "San Francisco 49ers", "Dallas Cowboys"),
            ("NFL", "Philadelphia Eagles", "New York Giants"),
            ("NFL", "Miami Dolphins", "New England Patriots"),
            ("NCAAB", "Duke Blue Devils", "North Carolina Tar Heels"),
            ("NCAAB", "Kentucky Wildcats", "Kansas Jayhawks"),
            ("MLB", "New York Yankees", "Boston Red Sox"),
            ("MLB", "Los Angeles Dodgers", "San Francisco Giants"),
        ]
        return matchups.randomElement()!
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
    
    // MARK: - Game Detail Generator
    
    static func generateGameDetail(from summary: GameSummary) -> GameDetailResponse {
        let status = summary.status ?? .scheduled
        let isCompleted = status == .completed
        let isLive = status == .inProgress
        let hasData = isCompleted || isLive
        
        // Build the full Game object
        let game = Game(
            id: summary.id,
            leagueCode: summary.leagueCode,
            season: 2024,
            seasonType: "regular",
            gameDate: summary.gameDate,
            homeTeam: summary.homeTeam,
            awayTeam: summary.awayTeam,
            homeScore: summary.homeScore,
            awayScore: summary.awayScore,
            status: status,
            scrapeVersion: summary.scrapeVersion,
            lastScrapedAt: summary.lastScrapedAt,
            hasBoxscore: summary.hasBoxscore,
            hasPlayerStats: summary.hasPlayerStats,
            hasOdds: summary.hasOdds,
            hasSocial: summary.hasSocial,
            hasPbp: summary.hasPbp,
            playCount: summary.playCount,
            socialPostCount: summary.socialPostCount,
            homeTeamXHandle: nil,
            awayTeamXHandle: nil
        )
        
        let plays = hasData ? generatePlays(home: summary.homeTeam, away: summary.awayTeam, isComplete: isCompleted) : []
        let compactMoments = makeCompactMoments(from: plays)

        return GameDetailResponse(
            game: game,
            teamStats: hasData ? generateTeamStats(home: summary.homeTeam, away: summary.awayTeam) : [],
            playerStats: hasData ? generatePlayerStats(home: summary.homeTeam, away: summary.awayTeam) : [],
            odds: generateOdds(),
            socialPosts: generateSocialPosts(home: summary.homeTeam, away: summary.awayTeam),
            plays: plays,
            compactMoments: compactMoments,
            derivedMetrics: [:],
            rawPayloads: [:]
        )
    }

    private static func makeCompactMoments(from plays: [PlayEntry]) -> [CompactMoment] {
        guard !plays.isEmpty else {
            return []
        }

        let targetMomentCount = 4
        let strideCount = max(1, plays.count / targetMomentCount)
        return plays.enumerated().compactMap { index, play in
            guard index.isMultiple(of: strideCount) else {
                return nil
            }
            return CompactMoment(play: play)
        }
    }
    
    private static func generateOdds() -> [OddsEntry] {
        [
            OddsEntry(
                book: "DraftKings",
                marketType: .spread,
                side: "home",
                line: Double.random(in: -7...7),
                price: -110,
                isClosingLine: true,
                observedAt: formatDate(Date())
            ),
            OddsEntry(
                book: "FanDuel",
                marketType: .total,
                side: "over",
                line: Double.random(in: 210...235),
                price: -110,
                isClosingLine: true,
                observedAt: formatDate(Date())
            ),
        ]
    }
    
    private static func generatePlayerStats(home: String, away: String) -> [PlayerStat] {
        var stats: [PlayerStat] = []
        
        // Generate 5 players per team
        let homeNames = ["J. Smith", "M. Johnson", "A. Williams", "R. Brown", "D. Davis"]
        let awayNames = ["C. Miller", "K. Wilson", "T. Moore", "L. Taylor", "P. Anderson"]
        
        for name in homeNames {
            stats.append(PlayerStat(
                team: home,
                playerName: name,
                minutes: Double.random(in: 20...38),
                points: Int.random(in: 5...28),
                rebounds: Int.random(in: 2...12),
                assists: Int.random(in: 1...10),
                yards: nil,
                touchdowns: nil,
                rawStats: [:],
                source: "mock",
                updatedAt: formatDate(Date())
            ))
        }
        
        for name in awayNames {
            stats.append(PlayerStat(
                team: away,
                playerName: name,
                minutes: Double.random(in: 20...38),
                points: Int.random(in: 5...28),
                rebounds: Int.random(in: 2...12),
                assists: Int.random(in: 1...10),
                yards: nil,
                touchdowns: nil,
                rawStats: [:],
                source: "mock",
                updatedAt: formatDate(Date())
            ))
        }
        
        return stats
    }
    
    private static func generateTeamStats(home: String, away: String) -> [TeamStat] {
        [
            TeamStat(
                team: home,
                isHome: true,
                stats: [
                    "fgPct": AnyCodable(Double.random(in: 42...52)),
                    "threePct": AnyCodable(Double.random(in: 30...42)),
                    "ftPct": AnyCodable(Double.random(in: 70...90)),
                    "rebounds": AnyCodable(Int.random(in: 38...52)),
                    "assists": AnyCodable(Int.random(in: 18...30)),
                ],
                source: "mock",
                updatedAt: formatDate(Date())
            ),
            TeamStat(
                team: away,
                isHome: false,
                stats: [
                    "fgPct": AnyCodable(Double.random(in: 42...52)),
                    "threePct": AnyCodable(Double.random(in: 30...42)),
                    "ftPct": AnyCodable(Double.random(in: 70...90)),
                    "rebounds": AnyCodable(Int.random(in: 38...52)),
                    "assists": AnyCodable(Int.random(in: 18...30)),
                ],
                source: "mock",
                updatedAt: formatDate(Date())
            ),
        ]
    }
    
    private static func generateSocialPosts(home: String, away: String) -> [SocialPostEntry] {
        let homeAbbrev = String(home.prefix(3)).uppercased()
        let awayAbbrev = String(away.prefix(3)).uppercased()
        return [
            SocialPostEntry(
                id: Int.random(in: 1000...9999),
                postUrl: "https://twitter.com/nba/status/123456789",
                postedAt: formatDate(Date()),
                hasVideo: false,
                teamAbbreviation: homeAbbrev,
                tweetText: "Great matchup between \(away) and \(home) tonight!",
                videoUrl: nil,
                imageUrl: nil,
                sourceHandle: "@nba",
                mediaType: nil
            ),
            SocialPostEntry(
                id: Int.random(in: 1000...9999),
                postUrl: "https://twitter.com/espn/status/987654321",
                postedAt: formatDate(Date()),
                hasVideo: true,
                teamAbbreviation: awayAbbrev,
                tweetText: "Incredible play by \(away)!",
                videoUrl: "https://example.com/highlight.mp4",
                imageUrl: nil,
                sourceHandle: "@espn",
                mediaType: .video
            ),
        ]
    }
    
    private static func generatePlays(home: String, away: String, isComplete: Bool) -> [PlayEntry] {
        var plays: [PlayEntry] = []
        let quarters = isComplete ? 4 : Int.random(in: 2...3)
        
        let playTypes: [PlayType] = [.madeShot, .missedShot, .rebound, .turnover, .steal, .foul, .freeThrow]
        
        var playIndex = 0
        var homeScore = 0
        var awayScore = 0
        
        for quarter in 1...quarters {
            let playsInQuarter = Int.random(in: 40...60)
            for i in 0..<playsInQuarter {
                let isHome = Bool.random()
                let team = isHome ? home : away
                let teamAbbrev = String(team.prefix(3)).uppercased()
                let playType = playTypes.randomElement()!
                let minutes = 12 - (i * 12 / playsInQuarter)
                let seconds = Int.random(in: 0...59)
                
                // Update scores for made shots
                if playType == .madeShot {
                    let points = Bool.random() ? 2 : 3
                    if isHome { homeScore += points } else { awayScore += points }
                }
                
                plays.append(PlayEntry(
                    playIndex: playIndex,
                    quarter: quarter,
                    gameClock: "\(minutes):\(String(format: "%02d", seconds))",
                    playType: playType,
                    teamAbbreviation: teamAbbrev,
                    playerName: "Player \(Int.random(in: 1...15))",
                    description: "\(teamAbbrev) \(playType.rawValue.replacingOccurrences(of: "_", with: " "))",
                    homeScore: homeScore,
                    awayScore: awayScore
                ))
                playIndex += 1
            }
        }
        
        return plays
    }
}
