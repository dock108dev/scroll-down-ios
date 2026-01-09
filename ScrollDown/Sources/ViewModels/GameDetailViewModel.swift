import Foundation

@MainActor
final class GameDetailViewModel: ObservableObject {
    enum SummaryState: Equatable {
        case loading
        case loaded(String)
        case failed(String)
    }
    struct QuarterTimeline: Identifiable, Equatable {
        let quarter: Int
        let plays: [PlayEntry]
        var id: Int { quarter }
    }

    struct TeamComparisonStat: Identifiable {
        let name: String
        let homeValue: Double?
        let awayValue: Double?
        let homeDisplay: String
        let awayDisplay: String

        var id: String { name }
    }

    struct TimelineScoreMarker: Identifiable, Equatable {
        let id: String
        let label: String
        let score: String
    }

    @Published private(set) var detail: GameDetailResponse?
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    @Published private(set) var isUnavailable: Bool = false
    @Published private(set) var summaryState: SummaryState = .loading
    @Published private(set) var relatedPosts: [RelatedPost] = []
    @Published private(set) var relatedPostsState: RelatedPostsState = .idle
    @Published private(set) var revealedRelatedPostIds: Set<Int> = []

    enum RelatedPostsState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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

    func loadSummary(gameId: Int, service: GameService) async {
        summaryState = .loading

        do {
            let response = try await service.fetchSummary(gameId: gameId)
            let sanitized = sanitizeSummary(response.summary)
            summaryState = .loaded(sanitized ?? overviewSummary)
        } catch {
            summaryState = .failed(error.localizedDescription)
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

    func revealRelatedPost(id: Int) {
        revealedRelatedPostIds.insert(id)
    }

    func isRelatedPostRevealed(_ post: RelatedPost) -> Bool {
        !post.containsScore || revealedRelatedPostIds.contains(post.id)
    }

    var game: Game? {
        detail?.game
    }

    var overviewSummary: String {
        guard let game = detail?.game else {
            return Constants.summaryFallback
        }
        return String(format: Constants.summaryTemplate, game.awayTeam, game.homeTeam)
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

    var compactTimelineMoments: [CompactMoment] {
        let moments = detail?.compactMoments ?? []
        if !moments.isEmpty {
            return moments
        }

        return (detail?.plays ?? []).map { CompactMoment(play: $0) }
    }

    var preGamePosts: [SocialPostEntry] {
        splitPosts().preGame
    }

    var postGamePosts: [SocialPostEntry] {
        splitPosts().postGame
    }

    var timelineQuarters: [QuarterTimeline] {
        let plays = detail?.plays ?? []
        let grouped = Dictionary(grouping: plays, by: { $0.quarter ?? Constants.unknownQuarter })
        return grouped
            .map { QuarterTimeline(quarter: $0.key, plays: $0.value.sorted { $0.playIndex < $1.playIndex }) }
            .sorted { $0.quarter < $1.quarter }
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
    static let summaryFallback = "Summary will appear here soon."
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights below."
    static let recapFallbackBullets = [
        "Matchup details are loading.",
        "Timeline updates will appear shortly.",
        "Highlights will populate when available."
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
}
