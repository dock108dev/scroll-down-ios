import Foundation

// MARK: - Mock Data Generator

enum MockDataGenerator {

    static func generateGames() -> [GameSummary] {
        var games: [GameSummary] = []
        var idCounter = 10000

        let calendar = Calendar.current

        // Earlier: Nov 10-11 (2 days ago, 1 day ago) - all final
        for daysAgo in [2, 1] {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: AppDate.startOfToday) else {
                continue
            }
            let gamesForDay = generateDayGames(
                baseDate: date,
                count: Int.random(in: 4...6),
                idStart: &idCounter,
                allFinal: true
            )
            games.append(contentsOf: gamesForDay)
        }

        // Today: Nov 12 - mix of statuses
        let todayGames = generateTodayGames(idStart: &idCounter)
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
            guard let gameDate = calendar.date(bySettingHour: hours[i], minute: 30, second: 0, of: baseDate) else {
                continue
            }

            let matchup = randomMatchup(for: idStart)
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

    private static func generateTodayGames(idStart: inout Int) -> [GameSummary] {
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
            guard let gameDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) else {
                continue
            }

            let matchup = randomMatchup(for: idStart)
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

    private static func randomMatchup(for id: Int) -> (league: String, home: String, away: String) {
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
            ("MLB", "Los Angeles Dodgers", "San Francisco Giants")
        ]

        // Deterministic selection based on ID to prevent "mixing and matching"
        return matchups[abs(id) % matchups.count]
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
            leagueCode: summary.league,
            season: 2024,
            seasonType: "regular",
            gameDate: summary.startTime,
            homeTeam: summary.homeTeamName,
            awayTeam: summary.awayTeamName,
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

        let plays = hasData ? generatePlays(home: summary.homeTeamName, away: summary.awayTeamName, isComplete: isCompleted) : []

        return GameDetailResponse(
            game: game,
            teamStats: hasData ? generateTeamStats(home: summary.homeTeamName, away: summary.awayTeamName) : [],
            playerStats: hasData ? generatePlayerStats(home: summary.homeTeamName, away: summary.awayTeamName) : [],
            odds: generateOdds(),
            socialPosts: generateSocialPosts(home: summary.homeTeamName, away: summary.awayTeamName),
            plays: plays,
            derivedMetrics: [:],
            rawPayloads: [:],
            nhlSkaters: nil,
            nhlGoalies: nil,
            dataHealth: nil
        )
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
            )
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
                    "points": AnyCodable(Int.random(in: 95...125)),
                    "rebounds": AnyCodable(Int.random(in: 35...60)),
                    "assists": AnyCodable(Int.random(in: 15...30))
                ],
                source: "mock",
                updatedAt: formatDate(Date())
            ),
            TeamStat(
                team: away,
                isHome: false,
                stats: [
                    "points": AnyCodable(Int.random(in: 95...125)),
                    "rebounds": AnyCodable(Int.random(in: 35...60)),
                    "assists": AnyCodable(Int.random(in: 15...30))
                ],
                source: "mock",
                updatedAt: formatDate(Date())
            )
        ]
    }

    private static func generateSocialPosts(home: String, away: String) -> [SocialPostEntry] {
        [
            SocialPostEntry(
                id: Int.random(in: 1000...9999),
                postUrl: "https://x.com/\(home.lowercased())/status/\(UUID().uuidString)",
                postedAt: formatDate(Date()),
                hasVideo: false,
                teamAbbreviation: home,
                tweetText: "\(home) open with crisp ball movement.",
                videoUrl: nil,
                imageUrl: nil,
                sourceHandle: "FanHub",
                mediaType: .none
            ),
            SocialPostEntry(
                id: Int.random(in: 1000...9999),
                postUrl: "https://x.com/\(away.lowercased())/status/\(UUID().uuidString)",
                postedAt: formatDate(Date()),
                hasVideo: false,
                teamAbbreviation: away,
                tweetText: "\(away) punch back with a quick run.",
                videoUrl: nil,
                imageUrl: nil,
                sourceHandle: "FanHub",
                mediaType: .none
            ),
            SocialPostEntry(
                id: Int.random(in: 1000...9999),
                postUrl: "https://x.com/fanhub/status/\(UUID().uuidString)",
                postedAt: formatDate(Date()),
                hasVideo: false,
                teamAbbreviation: home,
                tweetText: "Momentum swings set up the second half.",
                videoUrl: nil,
                imageUrl: nil,
                sourceHandle: "FanHub",
                mediaType: .none
            )
        ]
    }

    private static func generatePlays(home: String, away: String, isComplete: Bool) -> [PlayEntry] {
        let playCount = isComplete ? Int.random(in: 200...300) : Int.random(in: 30...80)
        var plays: [PlayEntry] = []

        var homeScore = 0
        var awayScore = 0

        for index in 1...playCount {
            let isHomePlay = Bool.random()
            let team = isHomePlay ? home : away

            let points = [0, 2, 3].randomElement() ?? 0
            if isHomePlay {
                homeScore += points
            } else {
                awayScore += points
            }

            let quarter = Int.random(in: 1...4)
            let minute = Int.random(in: 0...11)
            let second = Int.random(in: 0...59)

            let play = PlayEntry(
                playIndex: index,
                quarter: quarter,
                gameClock: String(format: "%d:%02d", minute, second),
                playType: .shot,
                teamAbbreviation: team,
                playerName: "Player \(index % 10 + 1)",
                description: "\(team) makes a shot.",
                homeScore: homeScore,
                awayScore: awayScore
            )
            plays.append(play)
        }

        return plays
    }
}
