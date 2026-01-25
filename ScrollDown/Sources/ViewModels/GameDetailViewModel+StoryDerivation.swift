import Foundation

// MARK: - Story Derivation Extension

extension GameDetailViewModel {
    /// Derive sections from chapters when API doesn't provide them
    func deriveSectionsFromChapters() -> [SectionEntry] {
        guard let story = gameStory, !story.chapters.isEmpty else { return [] }

        let allPlays = detail?.plays ?? []
        var sections: [SectionEntry] = []
        let sortedChapters = story.chapters.sorted { $0.index < $1.index }

        for (index, chapter) in sortedChapters.enumerated() {
            let beatType = deriveBeatType(from: chapter.reasonCodes, chapterIndex: index, totalChapters: sortedChapters.count)
            let header = deriveHeader(from: chapter, beatType: beatType)

            // Get plays for this chapter from main plays array using indices
            let chapterPlays = getPlaysForChapter(chapter, from: allPlays)
            let startScore = deriveStartScore(from: chapterPlays)
            let endScore = deriveEndScore(from: chapterPlays)

            let section = SectionEntry(
                sectionIndex: index,
                beatType: beatType,
                header: header,
                chaptersIncluded: [chapter.chapterId],
                startScore: startScore,
                endScore: endScore,
                notes: deriveNotes(from: chapter, playCount: chapterPlays.count)
            )
            sections.append(section)
        }

        return sections
    }

    /// Get plays for a chapter using play indices
    func getPlaysForChapter(_ chapter: ChapterEntry, from allPlays: [PlayEntry]) -> [PlayEntry] {
        // First try chapter's embedded plays
        if !chapter.plays.isEmpty {
            return chapter.plays
        }
        // Fall back to using play indices
        return allPlays.filter { $0.playIndex >= chapter.playStartIdx && $0.playIndex <= chapter.playEndIdx }
    }

    /// Map chapter reason codes to beat type
    func deriveBeatType(from reasonCodes: [String], chapterIndex: Int, totalChapters: Int) -> BeatType {
        let codes = Set(reasonCodes.map { $0.uppercased() })

        if codes.contains("OVERTIME_START") || codes.contains("OVERTIME") {
            return .overtime
        }
        if codes.contains("GAME_END") || chapterIndex == totalChapters - 1 {
            return .closingSequence
        }
        if codes.contains("RUN_BOUNDARY") || codes.contains("SCORING_RUN") {
            return .run
        }
        if codes.contains("PERIOD_START") && chapterIndex < 2 {
            return .fastStart
        }
        if codes.contains("TIMEOUT") {
            return .stall
        }

        if chapterIndex < totalChapters / 4 {
            return .earlyControl
        } else if chapterIndex > totalChapters * 3 / 4 {
            return .crunchSetup
        }
        return .backAndForth
    }

    /// Generate header text from chapter data
    func deriveHeader(from chapter: ChapterEntry, beatType: BeatType) -> String {
        let periodText = chapter.period.map { "Q\($0)" } ?? ""
        let timeText = chapter.timeRange?.displayString ?? ""

        switch beatType {
        case .fastStart:
            return "Game gets underway"
        case .overtime:
            return "Overtime period"
        case .closingSequence:
            return "Final stretch"
        case .run:
            return "Scoring run"
        case .crunchSetup:
            return "Crunch time approaching"
        case .stall:
            return "Teams regroup"
        default:
            if !periodText.isEmpty && !timeText.isEmpty {
                return "\(periodText) • \(timeText)"
            }
            return chapter.boundaryDescription.isEmpty ? "Game action" : chapter.boundaryDescription
        }
    }

    /// Get start score from plays
    func deriveStartScore(from plays: [PlayEntry]) -> ScoreSnapshot {
        if let firstPlay = plays.first {
            return ScoreSnapshot(home: firstPlay.homeScore ?? 0, away: firstPlay.awayScore ?? 0)
        }
        return ScoreSnapshot(home: 0, away: 0)
    }

    /// Get end score from plays
    func deriveEndScore(from plays: [PlayEntry]) -> ScoreSnapshot {
        if let lastPlay = plays.last {
            return ScoreSnapshot(home: lastPlay.homeScore ?? 0, away: lastPlay.awayScore ?? 0)
        }
        return ScoreSnapshot(home: 0, away: 0)
    }

    /// Generate notes from chapter data
    func deriveNotes(from chapter: ChapterEntry, playCount: Int) -> [String] {
        var notes: [String] = []
        let count = playCount > 0 ? playCount : chapter.playCount
        if count > 0 {
            notes.append("\(count) plays")
        }
        if !chapter.reasonCodes.isEmpty {
            notes.append(chapter.boundaryDescription)
        }
        return notes
    }

    /// Get plays for a section by looking up its chapters
    func playsForSection(_ section: SectionEntry) -> [PlayEntry] {
        let allPlays = detail?.plays ?? []
        var plays: [PlayEntry] = []
        for chapterId in section.chaptersIncluded {
            if let chapter = chapters.first(where: { $0.chapterId == chapterId }) {
                let chapterPlays = getPlaysForChapter(chapter, from: allPlays)
                plays.append(contentsOf: chapterPlays)
            }
        }
        return plays.sorted { $0.playIndex < $1.playIndex }
    }

    /// Get unified timeline events for a section
    func unifiedEventsForSection(_ section: SectionEntry) -> [UnifiedTimelineEvent] {
        let sectionPlays = playsForSection(section)
        return sectionPlays.enumerated().map { index, play in
            UnifiedTimelineEvent(from: playToDictionary(play), index: index)
        }
    }

    /// Convert PlayEntry to dictionary for UnifiedTimelineEvent parsing
    func playToDictionary(_ play: PlayEntry) -> [String: Any] {
        var dict: [String: Any] = [
            "event_type": "pbp",
            "play_index": play.playIndex
        ]
        if let quarter = play.quarter { dict["period"] = quarter }
        if let clock = play.gameClock { dict["game_clock"] = clock }
        if let desc = play.description { dict["description"] = desc }
        if let team = play.teamAbbreviation { dict["team"] = team }
        if let player = play.playerName { dict["player_name"] = player }
        if let home = play.homeScore { dict["home_score"] = home }
        if let away = play.awayScore { dict["away_score"] = away }
        if let playType = play.playType { dict["play_type"] = playType.rawValue }
        return dict
    }
}
