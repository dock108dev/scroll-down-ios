import Foundation

// MARK: - Story Generation Extension

extension MockGameService {
    /// Generate game story from game detail (Chapters-First Story API)
    func generateStory(from detail: GameDetailResponse, gameId: Int) -> GameStoryResponse {
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
            hasStory: compactStory != nil,
            hasCompactStory: compactStory != nil,
            metadata: nil
        )
    }

    /// Generate chapters from plays (structural divisions by period)
    func generateChapters(from plays: [PlayEntry]) -> [ChapterEntry] {
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
    func generateSections(from chapters: [ChapterEntry], game: Game) -> [SectionEntry] {
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
    func determineBeatType(
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
        let leadChanges = countLeadChanges(plays: plays)

        // Check for scoring runs
        let (maxRun, runTeam) = findMaxScoringRun(
            plays: plays,
            startScore: startScore,
            homeTeam: homeTeam,
            awayTeam: awayTeam
        )

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

    /// Count lead changes in a sequence of plays
    private func countLeadChanges(plays: [PlayEntry]) -> Int {
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
        return leadChanges
    }

    /// Find the maximum scoring run in a sequence of plays
    private func findMaxScoringRun(
        plays: [PlayEntry],
        startScore: ScoreSnapshot,
        homeTeam: String,
        awayTeam: String
    ) -> (Int, String) {
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

        return (maxRun, runTeam)
    }

    /// Generate compact story narrative from sections
    func generateCompactStory(sections: [SectionEntry], game: Game) -> String? {
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

    // MARK: - V2 Story Generation

    /// Generate V2 story response with moments-based structure
    func generateStoryV2(from detail: GameDetailResponse, gameId: Int) -> GameStoryResponseV2 {
        let plays = detail.plays
        let game = detail.game

        // Convert PlayEntry to StoryPlay
        let storyPlays = plays.enumerated().map { index, play in
            StoryPlay(
                playId: play.playIndex,
                playIndex: index,
                period: play.quarter ?? 1,
                clock: play.gameClock,
                playType: play.playType?.rawValue,
                description: play.description,
                homeScore: play.homeScore,
                awayScore: play.awayScore
            )
        }

        // Group plays into moments (3-8 per game)
        let moments = generateMoments(from: plays, game: game)

        let storyContent = StoryContent(moments: moments)

        return GameStoryResponseV2(
            gameId: gameId,
            story: storyContent,
            plays: storyPlays,
            validationPassed: true,
            validationErrors: []
        )
    }

    /// Generate moments by grouping plays
    private func generateMoments(from plays: [PlayEntry], game: Game) -> [StoryMoment] {
        guard !plays.isEmpty else { return [] }

        var moments: [StoryMoment] = []
        let homeTeam = game.homeTeam
        let awayTeam = game.awayTeam

        // Target 3-8 moments based on play count
        let targetMomentCount = min(8, max(3, plays.count / 25))
        let playsPerMoment = max(1, plays.count / targetMomentCount)

        for momentIndex in 0..<targetMomentCount {
            let startIdx = momentIndex * playsPerMoment
            let endIdx = (momentIndex == targetMomentCount - 1) ? plays.count - 1 : (momentIndex + 1) * playsPerMoment - 1

            guard startIdx <= endIdx && startIdx < plays.count else { continue }

            let momentPlays = Array(plays[startIdx...min(endIdx, plays.count - 1)])
            guard let firstPlay = momentPlays.first, let lastPlay = momentPlays.last else { continue }

            // Extract play IDs
            let playIds = momentPlays.map { $0.playIndex }

            // Find scoring plays to mark as explicitly narrated
            let scoringPlayIds = momentPlays.compactMap { play -> Int? in
                guard let home = play.homeScore, let away = play.awayScore else { return nil }
                let prevPlay = plays.first { $0.playIndex == play.playIndex - 1 }
                let prevHome = prevPlay?.homeScore ?? 0
                let prevAway = prevPlay?.awayScore ?? 0
                if home != prevHome || away != prevAway {
                    return play.playIndex
                }
                return nil
            }

            // Extract scores
            let scoreBefore = [firstPlay.awayScore ?? 0, firstPlay.homeScore ?? 0]
            let scoreAfter = [lastPlay.awayScore ?? 0, lastPlay.homeScore ?? 0]

            // Generate narrative
            let narrative = generateMomentNarrative(
                plays: momentPlays,
                momentIndex: momentIndex,
                totalMoments: targetMomentCount,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter
            )

            let moment = StoryMoment(
                playIds: playIds,
                explicitlyNarratedPlayIds: scoringPlayIds,
                period: firstPlay.quarter ?? 1,
                startClock: firstPlay.gameClock,
                endClock: lastPlay.gameClock,
                scoreBefore: scoreBefore,
                scoreAfter: scoreAfter,
                narrative: narrative
            )
            moments.append(moment)
        }

        return moments
    }

    /// Generate narrative text for a moment
    private func generateMomentNarrative(
        plays: [PlayEntry],
        momentIndex: Int,
        totalMoments: Int,
        homeTeam: String,
        awayTeam: String,
        scoreBefore: [Int],
        scoreAfter: [Int]
    ) -> String {
        let homeScored = scoreAfter[1] - scoreBefore[1]
        let awayScored = scoreAfter[0] - scoreBefore[0]
        let leadingTeam = scoreAfter[1] > scoreAfter[0] ? homeTeam : awayTeam
        let scoringTeam = homeScored > awayScored ? homeTeam : awayTeam

        // Last moment
        if momentIndex == totalMoments - 1 {
            return "\(leadingTeam) close out the game with a strong finish."
        }

        // First moment
        if momentIndex == 0 {
            if homeScored + awayScored > 20 {
                return "Both teams come out firing in a high-scoring start."
            }
            return "The game gets underway with both teams finding their rhythm."
        }

        // Big run
        let diff = abs(homeScored - awayScored)
        if diff >= 8 {
            return "\(scoringTeam) go on a \(max(homeScored, awayScored))-\(min(homeScored, awayScored)) run to take control."
        }

        // Tied or close
        if scoreAfter[0] == scoreAfter[1] {
            return "Teams trade baskets as the score remains knotted."
        }

        // Default
        return "Competitive play continues as \(leadingTeam) maintain their edge."
    }
}
