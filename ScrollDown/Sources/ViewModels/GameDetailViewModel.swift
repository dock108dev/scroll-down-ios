import Foundation
import OSLog

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
    @Published var isOutcomeRevealed: Bool = false // User-controlled outcome visibility
    
    // Social posts (Phase E)
    @Published private(set) var socialPosts: [SocialPostResponse] = []
    @Published private(set) var socialPostsState: SocialPostsState = .idle
    @Published var isSocialTabEnabled: Bool = false // User preference for social tab

    // Timeline artifact (read-only fetch)
    @Published private(set) var timelineArtifact: TimelineArtifactResponse?
    @Published private(set) var timelineArtifactState: TimelineArtifactState = .idle
    
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
                // Block fallback routing if the backend returns a different ID.
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

    /// Toggle outcome reveal (presentation-only, no data refetch)
    /// Reveal is a client-side preference - summary content doesn't change
    func toggleOutcomeReveal(for gameId: Int) {
        isOutcomeRevealed.toggle()
        UserDefaults.standard.set(isOutcomeRevealed, forKey: outcomeRevealKey(for: gameId))
    }
    
    /// Load persisted reveal preference
    func loadRevealPreference(for gameId: Int) {
        // Default is always false (pre-reveal)
        isOutcomeRevealed = UserDefaults.standard.bool(forKey: outcomeRevealKey(for: gameId))
    }
    
    private func outcomeRevealKey(for gameId: Int) -> String {
        "game.outcomeRevealed.\(gameId)"
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
    
    /// Load social posts for the game (Phase E)
    /// Only loads if user has enabled social tab
    func loadSocialPosts(gameId: Int, service: GameService) async {
        guard isSocialTabEnabled else {
            return // Social tab disabled, don't load
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
            // Backend provides posts in chronological order
            // Client preserves that order
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
    
    /// Get social posts filtered by reveal level
    /// CRITICAL: Respects outcome visibility preference
    var filteredSocialPosts: [SocialPostResponse] {
        socialPosts.filter { $0.isSafeToShow(outcomeRevealed: isOutcomeRevealed) }
    }
    
    /// Enable social tab and load posts
    func enableSocialTab(gameId: Int, service: GameService) async {
        isSocialTabEnabled = true
        // Persist preference
        UserDefaults.standard.set(true, forKey: socialTabEnabledKey(for: gameId))
        // Load posts
        await loadSocialPosts(gameId: gameId, service: service)
    }
    
    /// Load social tab preference
    func loadSocialTabPreference(for gameId: Int) {
        // Default is false (social tab disabled)
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

    /// DEPRECATED: Client-side fallback summary generation
    /// Summaries should come from timeline artifact's summary_json only
    @available(*, deprecated, message: "Summaries are pre-generated server-side, no client fallback")
    var overviewSummary: String {
        guard let game = detail?.game else {
            return "Game details unavailable."
        }
        return String(format: Constants.summaryTemplate, game.awayTeam, game.homeTeam)
    }
    
    /// Game context - why this game matters
    /// Returns nil if context is unavailable (section will be hidden)
    var gameContext: String? {
        guard let game = detail?.game else {
            return nil
        }
        
        // For now, provide basic context based on teams and league
        // In the future, backend could provide richer context (rivalry, rankings, etc.)
        let context = generateBasicContext(for: game)
        
        // Only return context if it's meaningful
        return context.isEmpty ? nil : context
    }
    
    /// Generate basic context from available game data
    /// CRITICAL: Context must be neutral and non-conclusive
    private func generateBasicContext(for game: Game) -> String {
        var contextParts: [String] = []
        
        // League context
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
        
        // Team matchup
        contextParts.append("featuring \(game.awayTeam) at \(game.homeTeam)")
        
        // Status context (non-conclusive)
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
            return Constants.recapFallbackBullets
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

    /// DEPRECATED: Legacy compact timeline moments from the old chapter-based approach
    @available(*, deprecated, message: "Use unifiedTimelineEvents from timeline_json")
    var compactTimelineMoments: [CompactMoment] {
        let moments = detail?.compactMoments ?? []
        if !moments.isEmpty {
            return moments
        }

        return (detail?.plays ?? []).map { CompactMoment(play: $0) }
    }

    /// DEPRECATED: Pre-game posts - social posts are now in unified timeline
    @available(*, deprecated, message: "Social posts are now integrated into timeline_json")
    var preGamePosts: [SocialPostEntry] {
        splitPosts().preGame
    }

    /// DEPRECATED: Post-game posts - social posts are now in unified timeline
    @available(*, deprecated, message: "Social posts are now integrated into timeline_json")
    var postGamePosts: [SocialPostEntry] {
        splitPosts().postGame
    }

    // MARK: - Unified Timeline (Single Source of Truth)
    
    /// Unified timeline events parsed from timeline_json
    /// Rendered in server-provided order — no client-side sorting or merging
    var unifiedTimelineEvents: [UnifiedTimelineEvent] {
        guard let timelineValue = timelineArtifact?.timelineJson?.value else {
            return []
        }
        
        let rawEvents = extractTimelineEvents(from: timelineValue)
        return rawEvents.enumerated().map { index, dict in
            UnifiedTimelineEvent(from: dict, index: index)
        }
    }
    
    /// Whether timeline data is available from timeline_json
    var hasUnifiedTimeline: Bool {
        !unifiedTimelineEvents.isEmpty
    }
    
    // MARK: - Legacy Timeline (deprecated - kept for fallback)
    
    @available(*, deprecated, message: "Use unifiedTimelineEvents instead - renders from timeline_json")
    var timelineQuarters: [QuarterTimeline] {
        // DEPRECATED: This groups/sorts detail.plays client-side
        // Only used as fallback if timeline_json is empty
        let plays = detail?.plays ?? []
        let grouped = Dictionary(grouping: plays, by: { $0.quarter ?? Constants.unknownQuarter })
        return grouped
            .map { QuarterTimeline(quarter: $0.key, plays: $0.value.sorted { $0.playIndex < $1.playIndex }) }
            .sorted { $0.quarter < $1.quarter }
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
    /// Summaries are pre-generated server-side - no async loading, retry, or client-side generation
    var summaryState: SummaryState {
        // Extract summary from timeline artifact's summary_json
        // If missing, return unavailable - no client-side fallback generation
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
        
        // Try "overall" key first (standard format)
        if let overall = dict["overall"] as? String {
            return sanitizeSummary(overall)
        }
        
        // Try "summary" key as fallback
        if let summary = dict["summary"] as? String {
            return sanitizeSummary(summary)
        }
        
        // If it's just a string value directly
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
                homeDisplay: formattedStat(homeValue, fallback: Constants.statFallback),
                awayDisplay: formattedStat(awayValue, fallback: Constants.statFallback)
            )
        }
    }

    var playerStats: [PlayerStat] {
        detail?.playerStats ?? []
    }

    var teamStats: [TeamStat] {
        detail?.teamStats ?? []
    }

    private func highlightPlayIndex(for index: Int, spacing: Int, plays: [PlayEntry]) -> Int {
        let targetIndex = min(index * spacing, plays.count - 1)
        return plays[targetIndex].playIndex
    }

    private func splitPosts() -> (preGame: [SocialPostEntry], postGame: [SocialPostEntry]) {
        let posts = detail?.socialPosts ?? []
        guard let gameDate = detail?.game.parsedGameDate else {
            return (posts, [])
        }

        var preGame: [SocialPostEntry] = []
        var postGame: [SocialPostEntry] = []

        for post in posts {
            if let postedAt = parseDate(post.postedAt), postedAt < gameDate {
                preGame.append(post)
            } else {
                postGame.append(post)
            }
        }

        return (preGame, postGame)
    }

    private func parseDate(_ string: String) -> Date? {
        Constants.dateFormatter.date(from: string)
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

    private func formattedStat(_ value: Double?, fallback: String) -> String {
        guard let value else {
            return fallback
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
    static let summaryTemplate = "Catch up on %@ at %@."
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights below."
    static let recapFallbackBullets = [
        "Matchup details unavailable.",
        "Check back later for timeline updates.",
        "Highlights will appear when available."
    ]
    static let unknownQuarter = 0
    static let halftimeQuarter = 2
    static let halftimeLabel = "Halftime"
    static let periodEndLabel = "Period End"
    static let liveScoreLabel = "Live Score"
    static let liveMarkerId = "live-score"
    static let minimumHighlightSpacing = 1
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    static let percentageFloor = 0.0
    static let percentageCeiling = 1.0
    static let percentageFormat = "%.3f"
    static let integerFormat = "%.0f"
    static let decimalFormat = "%.1f"
    static let statFallback = "--"
    static let scorePattern = #"(\d+)\s*(?:-|–|to)\s*(\d+)"#
    static let scoreRegex = try? NSRegularExpression(pattern: scorePattern, options: [])
    static let teamComparisonKeys: [(key: String, label: String)] = [
        ("fg_pct", "Field %"),
        ("fg3_pct", "3PT %"),
        ("trb", "Rebounds"),
        ("tov", "Turnovers")
    ]
    static let defaultTimelineGameId = 401585601
    static let timelineEventsKey = "events"
    static let timelineTimestampKey = "timestamp"
    static let timelineEventTimestampKey = "event_timestamp"
    static let timelineTimeKey = "time"
    static let timelineClockKey = "clock"
}
