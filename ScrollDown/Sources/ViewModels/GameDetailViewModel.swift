import Foundation

@MainActor
final class GameDetailViewModel: ObservableObject {
    struct QuarterTimeline: Identifiable {
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

    @Published private(set) var detail: GameDetailResponse?
    @Published var isLoading: Bool
    @Published var errorMessage: String?

    init(detail: GameDetailResponse? = nil) {
        self.detail = detail
        self.isLoading = detail == nil
    }

    func load(gameId: Int, service: GameService) async {
        guard detail == nil else {
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            detail = try await service.fetchGame(id: gameId)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
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
}

private enum Constants {
    static let summaryTemplate = "A spoiler-free recap of %@ at %@."
    static let summaryFallback = "A spoiler-free recap is on the way."
    static let recapTeamsTemplate = "Matchup: %@ at %@."
    static let recapStatusTemplate = "Status: %@."
    static let recapHighlightsTemplate = "Key moments and highlights are curated below."
    static let recapFallbackBullets = [
        "Matchup details are loading.",
        "Timeline updates will appear shortly.",
        "Highlights will populate when available."
    ]
    static let unknownQuarter = 0
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
    static let teamComparisonKeys: [(key: String, label: String)] = [
        ("fg_pct", "Field %"),
        ("fg3_pct", "3PT %"),
        ("trb", "Rebounds"),
        ("tov", "Turnovers")
    ]
}
