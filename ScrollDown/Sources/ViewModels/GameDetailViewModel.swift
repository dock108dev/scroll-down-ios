import Foundation
import OSLog

/// ViewModel for GameDetailView - manages game data, timeline, and progressive disclosure state.
///
/// Key responsibilities:
/// - Fetches game details, timeline artifact, and related content
/// - Provides unified timeline events (PBP + tweets) from timeline_json
/// - Computes derived stats for team comparisons
/// - Manages reveal state for progressive disclosure
///
/// Data flow: API -> GameDetailResponse -> derived computed properties -> View
@MainActor
final class GameDetailViewModel: ObservableObject {
    /// Summary state derived from timeline artifact
    /// No async loading - summaries either exist or don't
    enum SummaryState: Equatable {
        case unavailable
        case available(String)
    }

    @Published private(set) var detail: GameDetailResponse?
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published private(set) var isUnavailable: Bool = false
    @Published private(set) var relatedPosts: [RelatedPost] = []
    @Published private(set) var relatedPostsState: RelatedPostsState = .idle
    @Published private(set) var revealedRelatedPostIds: Set<Int> = []

    // Outcome is always hidden per progressive disclosure principles
    // Users reveal scores by scrolling through the timeline
    var isOutcomeRevealed: Bool { false }

    // Social posts
    @Published private(set) var socialPosts: [SocialPostResponse] = []
    @Published private(set) var socialPostsState: SocialPostsState = .idle
    @Published var isSocialTabEnabled: Bool = false

    // Timeline artifact (read-only fetch)
    @Published private(set) var timelineArtifact: TimelineArtifactResponse?
    @Published private(set) var timelineArtifactState: TimelineArtifactState = .idle

    // Story state (Chapters-First Story API)
    @Published private(set) var storyState: StoryState = .idle
    @Published private(set) var gameStory: GameStoryResponse?

    enum StoryState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum SocialPostsState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    enum TimelineArtifactState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    struct TimelineArtifactSummary: Equatable {
        let eventCount: Int
        let firstTimestamp: String?
        let lastTimestamp: String?
    }

    enum RelatedPostsState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let logger = Logger(subsystem: "com.scrolldown.app", category: "timeline")

    init(detail: GameDetailResponse? = nil) {
        self.detail = detail
        self.isLoading = detail == nil
    }

    func load(gameId: Int, league: String?, service: GameService) async {
        guard detail == nil else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        isUnavailable = false

        do {
            let response = try await service.fetchGame(id: gameId)
            guard response.game.id == gameId else {
                GameRoutingLogger.logMismatch(tappedId: gameId, destinationId: response.game.id, league: league)
                detail = nil
                isUnavailable = true
                isLoading = false
                return
            }
            detail = response
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func loadRelatedPosts(gameId: Int, service: GameService) async {
        switch relatedPostsState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        relatedPostsState = .loading

        do {
            let response = try await service.fetchRelatedPosts(gameId: gameId)
            relatedPosts = response.posts
            relatedPostsState = .loaded
        } catch {
            relatedPostsState = .failed(error.localizedDescription)
        }
    }

    /// Load social posts for the game
    /// Only loads if user has enabled social tab
    func loadSocialPosts(gameId: Int, service: GameService) async {
        guard isSocialTabEnabled else {
            return
        }

        switch socialPostsState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        socialPostsState = .loading

        do {
            let response = try await service.fetchSocialPosts(gameId: gameId)
            socialPosts = response.posts
            socialPostsState = .loaded
        } catch {
            socialPostsState = .failed(error.localizedDescription)
        }
    }

    func loadTimeline(gameId: Int, service: GameService) async {
        switch timelineArtifactState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        timelineArtifactState = .loading

        do {
            let resolvedGameId = timelineGameId(for: gameId)
            let response = try await service.fetchTimeline(gameId: resolvedGameId)
            timelineArtifact = response
            timelineArtifactState = .loaded
        } catch {
            logger.error("Timeline fetch failed: \(error.localizedDescription, privacy: .public)")
            timelineArtifactState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Story Computed Properties

    /// Sections from game story response (or derived from chapters if empty)
    var sections: [SectionEntry] {
        let apiSections = gameStory?.sections ?? []
        if !apiSections.isEmpty {
            return apiSections
        }
        // Derive sections from chapters if API doesn't provide them
        return deriveSectionsFromChapters()
    }

    /// Derive sections from chapters when API doesn't provide them
    private func deriveSectionsFromChapters() -> [SectionEntry] {
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
    private func getPlaysForChapter(_ chapter: ChapterEntry, from allPlays: [PlayEntry]) -> [PlayEntry] {
        // First try chapter's embedded plays
        if !chapter.plays.isEmpty {
            return chapter.plays
        }
        // Fall back to using play indices
        return allPlays.filter { $0.playIndex >= chapter.playStartIdx && $0.playIndex <= chapter.playEndIdx }
    }

    /// Map chapter reason codes to beat type
    private func deriveBeatType(from reasonCodes: [String], chapterIndex: Int, totalChapters: Int) -> BeatType {
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
    private func deriveHeader(from chapter: ChapterEntry, beatType: BeatType) -> String {
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
    private func deriveStartScore(from plays: [PlayEntry]) -> ScoreSnapshot {
        if let firstPlay = plays.first {
            return ScoreSnapshot(home: firstPlay.homeScore ?? 0, away: firstPlay.awayScore ?? 0)
        }
        return ScoreSnapshot(home: 0, away: 0)
    }

    /// Get end score from plays
    private func deriveEndScore(from plays: [PlayEntry]) -> ScoreSnapshot {
        if let lastPlay = plays.last {
            return ScoreSnapshot(home: lastPlay.homeScore ?? 0, away: lastPlay.awayScore ?? 0)
        }
        return ScoreSnapshot(home: 0, away: 0)
    }

    /// Generate notes from chapter data
    private func deriveNotes(from chapter: ChapterEntry, playCount: Int) -> [String] {
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

    /// Chapters from game story response (structural divisions)
    var chapters: [ChapterEntry] {
        gameStory?.chapters ?? []
    }

    /// Highlight sections (sections with notable beat types)
    var highlightSections: [SectionEntry] {
        sections.filter { $0.isHighlight }
    }

    /// Compact story narrative (single AI-generated game recap)
    var compactStory: String? {
        gameStory?.compactStory
    }

    /// Story quality level
    var storyQuality: StoryQuality? {
        gameStory?.quality
    }

    /// Sections grouped by period (derived from chapters)
    var sectionsByPeriod: [Int: [SectionEntry]] {
        var result: [Int: [SectionEntry]] = [:]
        for section in sections {
            if let firstChapterId = section.chaptersIncluded.first,
               let chapter = chapters.first(where: { $0.chapterId == firstChapterId }),
               let period = chapter.period {
                result[period, default: []].append(section)
            } else {
                result[1, default: []].append(section)
            }
        }
        return result
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

    /// Whether story data is available
    var hasStoryData: Bool {
        let loaded = storyState == .loaded
        let hasSections = !sections.isEmpty
        return loaded && hasSections
    }

    /// Whether to show the Story View (completed games with story data)
    /// vs the Timeline View (in-progress or games without story)
    var shouldShowStoryView: Bool {
        guard let game = game else { return false }
        let isCompleted = game.status == .completed || game.status == .final
        return isCompleted && hasStoryData
    }

    // MARK: - Social Post Matching

    /// Compute social post matching result
    /// Note: Computed fresh each time since sections/events may change
    private func computeMatchResult() -> SocialPostMatcher.MatchResult {
        let tweetEvents = unifiedTimelineEvents.filter { $0.eventType == .tweet }
        return SocialPostMatcher.match(
            posts: tweetEvents,
            sections: sections,
            chapters: chapters,
            allPlays: detail?.plays ?? []
        )
    }

    /// Get social posts matched to a specific section
    func socialPostsForSection(_ section: SectionEntry) -> [UnifiedTimelineEvent] {
        computeMatchResult().placed[section.sectionIndex] ?? []
    }

    /// Social posts that couldn't be matched to any section
    var deferredSocialPosts: [UnifiedTimelineEvent] {
        computeMatchResult().deferred
    }

    /// Load story from Chapters-First Story API
    func loadStory(gameId: Int, service: GameService) async {
        switch storyState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        storyState = .loading

        do {
            let response = try await service.fetchStory(gameId: gameId)
            gameStory = response
            storyState = .loaded
            logger.info("📖 Loaded story: \(response.sectionCount, privacy: .public) API sections, \(response.chapterCount, privacy: .public) chapters")
        } catch {
            logger.error("📖 Story API failed: \(error.localizedDescription, privacy: .public)")
            storyState = .failed(error.localizedDescription)
        }
    }

    /// Get social posts filtered by reveal level
    var filteredSocialPosts: [SocialPostResponse] {
        socialPosts.filter { $0.isSafeToShow(outcomeRevealed: isOutcomeRevealed) }
    }

    /// Enable social tab and load posts
    func enableSocialTab(gameId: Int, service: GameService) async {
        isSocialTabEnabled = true
        UserDefaults.standard.set(true, forKey: socialTabEnabledKey(for: gameId))
        await loadSocialPosts(gameId: gameId, service: service)
    }

    /// Load social tab preference
    func loadSocialTabPreference(for gameId: Int) {
        isSocialTabEnabled = UserDefaults.standard.bool(forKey: socialTabEnabledKey(for: gameId))
    }

    private func socialTabEnabledKey(for gameId: Int) -> String {
        "game.socialTabEnabled.\(gameId)"
    }

    func revealRelatedPost(id: Int) {
        revealedRelatedPostIds.insert(id)
    }

    func isRelatedPostRevealed(_ post: RelatedPost) -> Bool {
        !post.containsScore || revealedRelatedPostIds.contains(post.id)
    }

    var game: Game? {
        detail?.game
    }

    /// Game context - why this game matters
    var gameContext: String? {
        guard let game = detail?.game else {
            return nil
        }

        let context = generateBasicContext(for: game)
        return context.isEmpty ? nil : context
    }

    /// Generate basic context from available game data
    private func generateBasicContext(for game: Game) -> String {
        var contextParts: [String] = []

        switch game.leagueCode {
        case "NBA":
            contextParts.append("NBA matchup")
        case "NCAAB":
            contextParts.append("College basketball")
        case "NHL":
            contextParts.append("NHL game")
        default:
            contextParts.append("\(game.leagueCode) game")
        }

        contextParts.append("featuring \(game.awayTeam) at \(game.homeTeam)")

        switch game.status {
        case .scheduled:
            if let date = game.parsedGameDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                contextParts.append("scheduled for \(formatter.string(from: date))")
            }
        case .inProgress:
            contextParts.append("currently in progress")
        case .completed, .final:
            contextParts.append("played on \(game.formattedDate)")
        default:
            break
        }

        return contextParts.joined(separator: ", ") + "."
    }

    var recapBullets: [String] {
        guard let game = detail?.game else {
            return []
        }

        let statusText = game.status.rawValue.capitalized
        return [
            String(format: Constants.recapTeamsTemplate, game.awayTeam, game.homeTeam),
            String(format: Constants.recapStatusTemplate, statusText),
            Constants.recapHighlightsTemplate
        ]
    }

    var highlights: [SocialPostEntry] {
        detail?.socialPosts.filter { $0.hasVideo || $0.imageUrl != nil } ?? []
    }

    // MARK: - Unified Timeline

    /// Unified timeline events - merges plays (with scores) and social posts
    var unifiedTimelineEvents: [UnifiedTimelineEvent] {
        var events: [UnifiedTimelineEvent] = []

        let plays = detail?.plays ?? []
        let pbpEvents = plays.enumerated().map { index, play in
            UnifiedTimelineEvent(from: playToDictionary(play), index: index)
        }
        events.append(contentsOf: pbpEvents)

        if let timelineValue = timelineArtifact?.timelineJson?.value {
            let rawEvents = extractTimelineEvents(from: timelineValue)
            let tweetEvents = rawEvents.enumerated().compactMap { index, dict -> UnifiedTimelineEvent? in
                let eventType = dict["event_type"] as? String
                guard eventType == "tweet" else { return nil }
                return UnifiedTimelineEvent(from: dict, index: plays.count + index)
            }
            events.append(contentsOf: tweetEvents)
        }

        return events
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

    /// Whether timeline data is available from timeline_json
    var hasUnifiedTimeline: Bool {
        !unifiedTimelineEvents.isEmpty
    }

    var timelineArtifactSummary: TimelineArtifactSummary? {
        guard let timelineValue = timelineArtifact?.timelineJson?.value else {
            return nil
        }

        let events = extractTimelineEvents(from: timelineValue)
        guard !events.isEmpty else {
            return TimelineArtifactSummary(eventCount: 0, firstTimestamp: nil, lastTimestamp: nil)
        }

        let firstTimestamp = extractTimestamp(from: events.first)
        let lastTimestamp = extractTimestamp(from: events.last)
        return TimelineArtifactSummary(
            eventCount: events.count,
            firstTimestamp: firstTimestamp,
            lastTimestamp: lastTimestamp
        )
    }

    /// Summary state derived from timeline artifact
    var summaryState: SummaryState {
        if let summaryText = extractSummaryFromArtifact() {
            return .available(summaryText)
        }
        return .unavailable
    }

    /// Extract narrative summary from timeline artifact's summary_json
    private func extractSummaryFromArtifact() -> String? {
        guard let summaryJson = timelineArtifact?.summaryJson,
              let dict = summaryJson.value as? [String: Any] else {
            return nil
        }

        if let overall = dict["overall"] as? String {
            return sanitizeSummary(overall)
        }

        if let summary = dict["summary"] as? String {
            return sanitizeSummary(summary)
        }

        if let directSummary = summaryJson.value as? String {
            return sanitizeSummary(directSummary)
        }

        return nil
    }

    var highlightByPlayIndex: [Int: [SocialPostEntry]] {
        let plays = detail?.plays ?? []
        let highlights = highlights
        guard !plays.isEmpty, !highlights.isEmpty else {
            return [:]
        }

        let spacing = max(Constants.minimumHighlightSpacing, plays.count / max(Constants.minimumHighlightSpacing, highlights.count))
        var mapping: [Int: [SocialPostEntry]] = [:]

        for (index, highlight) in highlights.enumerated() {
            let playIndex = highlightPlayIndex(for: index, spacing: spacing, plays: plays)
            mapping[playIndex, default: []].append(highlight)
        }

        return mapping
    }

    var liveScoreMarker: TimelineScoreMarker? {
        guard game?.status == .inProgress else {
            return nil
        }

        guard let score = latestScoreDisplay() else {
            return nil
        }

        return TimelineScoreMarker(
            id: Constants.liveMarkerId,
            label: Constants.liveScoreLabel,
            score: score
        )
    }

    func scoreMarker(for play: PlayEntry) -> TimelineScoreMarker? {
        guard play.playType == .periodEnd else {
            return nil
        }

        guard let score = scoreDisplay(home: play.homeScore, away: play.awayScore) else {
            return nil
        }

        let label = play.quarter == Constants.halftimeQuarter
            ? Constants.halftimeLabel
            : Constants.periodEndLabel

        return TimelineScoreMarker(
            id: "period-end-\(play.playIndex)",
            label: label,
            score: score
        )
    }

    var teamComparisonStats: [TeamComparisonStat] {
        guard let home = detail?.teamStats.first(where: { $0.isHome }),
              let away = detail?.teamStats.first(where: { !$0.isHome }) else {
            return []
        }

        return Constants.teamComparisonKeys.map { key in
            let homeValue = statValue(for: key.key, in: home.stats)
            let awayValue = statValue(for: key.key, in: away.stats)
            return TeamComparisonStat(
                name: key.label,
                homeValue: homeValue,
                awayValue: awayValue,
                homeDisplay: formattedStat(homeValue, placeholder: Constants.statPlaceholder),
                awayDisplay: formattedStat(awayValue, placeholder: Constants.statPlaceholder)
            )
        }
    }

    var playerStats: [PlayerStat] {
        detail?.playerStats ?? []
    }

    var teamStats: [TeamStat] {
        detail?.teamStats ?? []
    }

    // MARK: - Pre/Post Game Tweet Helpers

    /// Pre-game tweets (tweets before the first PBP event)
    var pregameTweets: [UnifiedTimelineEvent] {
        guard let firstPbpIndex = unifiedTimelineEvents.firstIndex(where: { $0.eventType == .pbp }) else {
            return unifiedTimelineEvents.filter { $0.eventType == .tweet && $0.period == nil }
        }
        return Array(unifiedTimelineEvents.prefix(upTo: firstPbpIndex)).filter { $0.eventType == .tweet }
    }

    /// Post-game tweets (tweets after the last PBP event)
    var postGameTweets: [UnifiedTimelineEvent] {
        guard let lastPbpIndex = unifiedTimelineEvents.lastIndex(where: { $0.eventType == .pbp }) else {
            return []
        }
        let afterLastPbp = unifiedTimelineEvents.suffix(from: unifiedTimelineEvents.index(after: lastPbpIndex))
        return Array(afterLastPbp).filter { $0.eventType == .tweet }
    }

    private func highlightPlayIndex(for index: Int, spacing: Int, plays: [PlayEntry]) -> Int {
        let targetIndex = min(index * spacing, plays.count - 1)
        return plays[targetIndex].playIndex
    }

    private func statValue(for key: String, in stats: [String: AnyCodable]) -> Double? {
        guard let value = stats[key]?.value else {
            return nil
        }

        if let number = value as? NSNumber {
            return number.doubleValue
        }

        if let string = value as? String {
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return nil
    }

    private func timelineGameId(for gameId: Int) -> Int {
        gameId > 0 ? gameId : Constants.defaultTimelineGameId
    }

    private func extractTimelineEvents(from value: Any) -> [[String: Any]] {
        if let events = value as? [[String: Any]] {
            return events
        }

        if let array = value as? [Any] {
            return array.compactMap { $0 as? [String: Any] }
        }

        if let dict = value as? [String: Any] {
            if let events = dict[Constants.timelineEventsKey] as? [[String: Any]] {
                return events
            }
            if let eventsArray = dict[Constants.timelineEventsKey] as? [Any] {
                return eventsArray.compactMap { $0 as? [String: Any] }
            }
        }

        return []
    }

    private func extractTimestamp(from event: [String: Any]?) -> String? {
        guard let event else {
            return nil
        }

        let candidates = [
            Constants.timelineTimestampKey,
            Constants.timelineEventTimestampKey,
            Constants.timelineTimeKey,
            Constants.timelineClockKey
        ]

        for key in candidates {
            if let value = event[key] {
                if let stringValue = value as? String {
                    return stringValue
                }
                if let numberValue = value as? NSNumber {
                    return numberValue.stringValue
                }
            }
        }

        return nil
    }

    private func formattedStat(_ value: Double?, placeholder: String) -> String {
        guard let value else {
            return placeholder
        }

        if value >= Constants.percentageFloor && value <= Constants.percentageCeiling {
            return String(format: Constants.percentageFormat, value)
        }

        if value == floor(value) {
            return String(format: Constants.integerFormat, value)
        }

        return String(format: Constants.decimalFormat, value)
    }

    private func sanitizeSummary(_ summary: String) -> String? {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let regex = Constants.scoreRegex {
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return nil
            }
        }

        return trimmed
    }

    private func latestScoreDisplay() -> String? {
        let plays = detail?.plays ?? []
        if let scoredPlay = plays.reversed().first(where: { $0.homeScore != nil && $0.awayScore != nil }) {
            return scoreDisplay(home: scoredPlay.homeScore, away: scoredPlay.awayScore)
        }

        return scoreDisplay(home: game?.homeScore, away: game?.awayScore)
    }

    private func scoreDisplay(home: Int?, away: Int?) -> String? {
        guard let home, let away else {
            return nil
        }

        return "\(away) - \(home)"
    }
}

private enum Constants {
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights below."
    static let halftimeQuarter = 2
    static let halftimeLabel = "Halftime"
    static let periodEndLabel = "Period End"
    static let liveScoreLabel = "Live Score"
    static let liveMarkerId = "live-score"
    static let minimumHighlightSpacing = 1
    static let percentageFloor = 0.0
    static let percentageCeiling = 1.0
    static let percentageFormat = "%.3f"
    static let integerFormat = "%.0f"
    static let decimalFormat = "%.1f"
    static let statPlaceholder = "--"
    static let scorePattern = #"(\d+)\s*(?:-|–|to)\s*(\d+)"#
    static let scoreRegex = try? NSRegularExpression(pattern: scorePattern, options: [])
    static let teamComparisonKeys: [(key: String, label: String)] = [
        ("fg_pct", "Field Goal %"),
        ("fg", "Field Goals Made"),
        ("fga", "Field Goals Attempted"),
        ("fg3_pct", "3-Point %"),
        ("fg3", "3-Pointers Made"),
        ("fg3a", "3-Pointers Attempted"),
        ("ft_pct", "Free Throw %"),
        ("ft", "Free Throws Made"),
        ("fta", "Free Throws Attempted"),
        ("trb", "Total Rebounds"),
        ("orb", "Offensive Rebounds"),
        ("drb", "Defensive Rebounds"),
        ("ast", "Assists"),
        ("stl", "Steals"),
        ("blk", "Blocks"),
        ("tov", "Turnovers"),
        ("pf", "Personal Fouls")
    ]
    static let defaultTimelineGameId = 401585601
    static let timelineEventsKey = "events"
    static let timelineTimestampKey = "timestamp"
    static let timelineEventTimestampKey = "event_timestamp"
    static let timelineTimeKey = "time"
    static let timelineClockKey = "clock"
}
