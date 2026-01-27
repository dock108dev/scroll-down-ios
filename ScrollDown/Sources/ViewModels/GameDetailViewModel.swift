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

    // V2 Story API (moments-based)
    @Published private(set) var storyV2Response: GameStoryResponseV2?
    @Published private(set) var momentDisplayModels: [MomentDisplayModel] = []
    @Published private(set) var storyPlays: [StoryPlay] = []

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

    private let logger = Logger(subsystem: "com.scrolldown.app", category: "timeline")

    init(detail: GameDetailResponse? = nil) {
        self.detail = detail
        self.isLoading = detail == nil
    }

    // MARK: - Loading Methods

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

    /// Load story from Story API (tries V2 first, falls back to V1)
    func loadStory(gameId: Int, service: GameService) async {
        switch storyState {
        case .loaded, .loading:
            return
        case .idle, .failed:
            break
        }

        storyState = .loading

        do {
            // Try V2 first
            if let v2Response = try await service.fetchStoryV2(gameId: gameId) {
                storyV2Response = v2Response
                storyPlays = v2Response.plays
                momentDisplayModels = StoryAdapter.convertToDisplayModels(from: v2Response)
                storyState = .loaded
                logger.info("📖 Loaded V2 story: \(v2Response.story.moments.count, privacy: .public) moments, \(v2Response.plays.count, privacy: .public) plays")
            } else {
                // Fallback to V1
                let response = try await service.fetchStory(gameId: gameId)
                gameStory = response
                storyState = .loaded
                logger.info("📖 Loaded V1 story: \(response.sectionCount, privacy: .public) API sections, \(response.chapterCount, privacy: .public) chapters")
            }
        } catch {
            logger.error("📖 Story API failed: \(error.localizedDescription, privacy: .public)")
            storyState = .failed(error.localizedDescription)
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

    /// Whether story data is available
    var hasStoryData: Bool {
        let loaded = storyState == .loaded
        let hasSections = !sections.isEmpty || !momentDisplayModels.isEmpty
        return loaded && hasSections
    }

    /// Whether V2 story data is available
    var hasV2Story: Bool {
        !momentDisplayModels.isEmpty
    }

    /// Get plays for a specific moment
    func playsForMoment(_ moment: MomentDisplayModel) -> [StoryPlay] {
        let ids = Set(moment.playIds)
        return storyPlays.filter { ids.contains($0.playId) }
    }

    /// Check if a play is highlighted within a moment
    func isPlayHighlighted(_ playId: Int, in moment: MomentDisplayModel) -> Bool {
        moment.highlightedPlayIds.contains(playId)
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

    // MARK: - Game Properties

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
            String(format: ViewModelConstants.recapTeamsTemplate, game.awayTeam, game.homeTeam),
            String(format: ViewModelConstants.recapStatusTemplate, statusText),
            ViewModelConstants.recapHighlightsTemplate
        ]
    }

    var highlights: [SocialPostEntry] {
        detail?.socialPosts.filter { $0.hasVideo || $0.imageUrl != nil } ?? []
    }

    // MARK: - Score Markers

    var liveScoreMarker: TimelineScoreMarker? {
        guard game?.status == .inProgress else {
            return nil
        }

        guard let score = latestScoreDisplay() else {
            return nil
        }

        return TimelineScoreMarker(
            id: ViewModelConstants.liveMarkerId,
            label: ViewModelConstants.liveScoreLabel,
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

        let label = play.quarter == ViewModelConstants.halftimeQuarter
            ? ViewModelConstants.halftimeLabel
            : ViewModelConstants.periodEndLabel

        return TimelineScoreMarker(
            id: "period-end-\(play.playIndex)",
            label: label,
            score: score
        )
    }

    // MARK: - Team Stats

    var teamComparisonStats: [TeamComparisonStat] {
        guard let home = detail?.teamStats.first(where: { $0.isHome }),
              let away = detail?.teamStats.first(where: { !$0.isHome }) else {
            return []
        }

        return ViewModelConstants.teamComparisonKeys.map { key in
            let homeValue = statValue(for: key.key, in: home.stats)
            let awayValue = statValue(for: key.key, in: away.stats)
            return TeamComparisonStat(
                name: key.label,
                homeValue: homeValue,
                awayValue: awayValue,
                homeDisplay: formattedStat(homeValue, placeholder: ViewModelConstants.statPlaceholder),
                awayDisplay: formattedStat(awayValue, placeholder: ViewModelConstants.statPlaceholder)
            )
        }
    }

    var playerStats: [PlayerStat] {
        detail?.playerStats ?? []
    }

    var teamStats: [TeamStat] {
        detail?.teamStats ?? []
    }

    // MARK: - NHL-Specific Stats

    /// Whether this is an NHL game
    var isNHL: Bool {
        game?.leagueCode == "NHL"
    }

    /// NHL skater stats (non-goalies)
    var nhlSkaters: [NHLSkaterStat] {
        detail?.nhlSkaters ?? []
    }

    /// NHL goalie stats
    var nhlGoalies: [NHLGoalieStat] {
        detail?.nhlGoalies ?? []
    }

    /// NHL data health status
    var nhlDataHealth: NHLDataHealth? {
        detail?.dataHealth
    }

    /// Whether NHL data is healthy
    var isNHLDataHealthy: Bool {
        detail?.dataHealth?.isHealthy ?? true
    }

    // MARK: - Private Helpers

    private func timelineGameId(for gameId: Int) -> Int {
        gameId > 0 ? gameId : ViewModelConstants.defaultTimelineGameId
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

    private func formattedStat(_ value: Double?, placeholder: String) -> String {
        guard let value else {
            return placeholder
        }

        if value >= ViewModelConstants.percentageFloor && value <= ViewModelConstants.percentageCeiling {
            return String(format: ViewModelConstants.percentageFormat, value)
        }

        if value == floor(value) {
            return String(format: ViewModelConstants.integerFormat, value)
        }

        return String(format: ViewModelConstants.decimalFormat, value)
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

// MARK: - Constants

private enum ViewModelConstants {
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights below."
    static let halftimeQuarter = 2
    static let halftimeLabel = "Halftime"
    static let periodEndLabel = "Period End"
    static let liveScoreLabel = "Live Score"
    static let liveMarkerId = "live-score"
    static let percentageFloor = 0.0
    static let percentageCeiling = 1.0
    static let percentageFormat = "%.3f"
    static let integerFormat = "%.0f"
    static let decimalFormat = "%.1f"
    static let statPlaceholder = "--"
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
}
