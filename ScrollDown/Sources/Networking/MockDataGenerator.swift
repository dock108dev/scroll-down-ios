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
        let compactMoments = makeCompactMoments(from: plays)
        let moments = hasData ? generateMoments(from: plays) : []

        return GameDetailResponse(
            game: game,
            teamStats: hasData ? generateTeamStats(home: summary.homeTeamName, away: summary.awayTeamName) : [],
            playerStats: hasData ? generatePlayerStats(home: summary.homeTeamName, away: summary.awayTeamName) : [],
            odds: generateOdds(),
            socialPosts: generateSocialPosts(home: summary.homeTeamName, away: summary.awayTeamName),
            plays: plays,
            moments: moments,
            compactMoments: compactMoments,
            derivedMetrics: [:],
            rawPayloads: [:]
        )
    }
    
    /// Generate moments from plays using Lead Ladder-style types
    private static func generateMoments(from plays: [PlayEntry]) -> [Moment] {
        guard !plays.isEmpty else { return [] }
        
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
                
                // Determine moment type based on position and scoring
                let (momentType, isNotable, note) = determineMomentTypeV2(
                    plays: momentPlays,
                    quarter: quarter,
                    momentIndex: momentIndex,
                    isLastMoment: momentIndex == momentCount - 1
                )
                
                // Extract player contributions
                let players = extractMomentPlayers(from: momentPlays)
                
                // Build clock string
                let startClock = firstPlay.gameClock ?? "12:00"
                let endClock = lastPlay.gameClock ?? "0:00"
                let clockString = "Q\(quarter) \(startClock)–\(endClock)"
                
                // Build score strings
                let scoreStart = formatMomentScore(home: firstPlay.homeScore, away: firstPlay.awayScore)
                let scoreEnd = formatMomentScore(home: lastPlay.homeScore, away: lastPlay.awayScore)
                
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
        
        return moments
    }
    
    private static func determineMomentTypeV2(
        plays: [PlayEntry],
        quarter: Int,
        momentIndex: Int,
        isLastMoment: Bool
    ) -> (MomentType, Bool, String?) {
        // Last moment of Q4 or OT is CLOSING_CONTROL
        if quarter >= 4 && isLastMoment {
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
        
        // Check for scoring runs (LEAD_BUILD or CUT)
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
    
    private static func extractMomentPlayers(from plays: [PlayEntry]) -> [PlayerContribution] {
        var playerStats: [String: [String: Int]] = [:]
        
        for play in plays {
            guard let playerName = play.playerName else { continue }
            
            if playerStats[playerName] == nil {
                playerStats[playerName] = [:]
            }
            
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
        
        return playerStats
            .map { name, stats in
                let summary = formatPlayerStatsSummary(stats)
                return PlayerContribution(name: name, stats: stats, summary: summary)
            }
            .sorted { ($0.stats["pts"] ?? 0) > ($1.stats["pts"] ?? 0) }
            .prefix(3)
            .map { $0 }
    }
    
    private static func formatPlayerStatsSummary(_ stats: [String: Int]) -> String? {
        var parts: [String] = []
        if let pts = stats["pts"], pts > 0 { parts.append("\(pts) pts") }
        if let ast = stats["ast"], ast > 0 { parts.append("\(ast) ast") }
        if let stl = stats["stl"], stl > 0 { parts.append("\(stl) stl") }
        if let blk = stats["blk"], blk > 0 { parts.append("\(blk) blk") }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    private static func formatMomentScore(home: Int?, away: Int?) -> String {
        let h = home ?? 0
        let a = away ?? 0
        return "\(a)–\(h)"
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
