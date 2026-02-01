import Foundation

/// Game summary for list views matching the admin API /games endpoint
/// All fields use camelCase per API specification
struct GameSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let leagueCode: String
    let gameDate: String
    private let statusRaw: String?
    let homeTeam: String

    enum CodingKeys: String, CodingKey {
        case id, leagueCode, gameDate, homeTeam, awayTeam
        case statusRaw = "status"
        case homeScore, awayScore
        case hasBoxscore, hasPlayerStats, hasOdds, hasSocial, hasPbp, hasStory
        case playCount, socialPostCount, hasRequiredData, scrapeVersion
        case lastScrapedAt, lastIngestedAt, lastPbpAt, lastSocialAt
    }
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let hasBoxscore: Bool?
    let hasPlayerStats: Bool?
    let hasOdds: Bool?
    let hasSocial: Bool?
    let hasPbp: Bool?
    let hasStory: Bool?
    let playCount: Int?
    let socialPostCount: Int?
    let hasRequiredData: Bool?
    let scrapeVersion: Int?
    let lastScrapedAt: String?
    let lastIngestedAt: String?
    let lastPbpAt: String?
    let lastSocialAt: String?

    // Convenience init for mock data generation
    init(
        id: Int,
        leagueCode: String,
        gameDate: String,
        status: GameStatus?,
        homeTeam: String,
        awayTeam: String,
        homeScore: Int?,
        awayScore: Int?,
        hasBoxscore: Bool?,
        hasPlayerStats: Bool?,
        hasOdds: Bool?,
        hasSocial: Bool?,
        hasPbp: Bool?,
        hasStory: Bool? = nil,
        playCount: Int?,
        socialPostCount: Int?,
        hasRequiredData: Bool?,
        scrapeVersion: Int?,
        lastScrapedAt: String?
    ) {
        self.id = id
        self.leagueCode = leagueCode
        self.gameDate = gameDate
        self.statusRaw = status?.rawValue
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.hasBoxscore = hasBoxscore
        self.hasPlayerStats = hasPlayerStats
        self.hasOdds = hasOdds
        self.hasSocial = hasSocial
        self.hasPbp = hasPbp
        self.hasStory = hasStory
        self.playCount = playCount
        self.socialPostCount = socialPostCount
        self.hasRequiredData = hasRequiredData
        self.scrapeVersion = scrapeVersion
        self.lastScrapedAt = lastScrapedAt
        self.lastIngestedAt = nil
        self.lastPbpAt = nil
        self.lastSocialAt = nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: GameSummary, rhs: GameSummary) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties
extension GameSummary {
    private enum Formatting {
        static let startsAtPrefix = "Starts at "
        static let inProgressText = "Live"
        static let completedText = "Final — recap available"
        static let postponedText = "Postponed"
        static let canceledText = "Canceled"
        static let statusUnavailableText = "Status unavailable"
    }

    /// Normalized status from API string to GameStatus enum
    var status: GameStatus? {
        guard let raw = statusRaw?.lowercased() else {
            // Infer status from available data
            if hasRequiredData == true || (homeScore != nil && awayScore != nil) {
                return .completed
            }
            if let date = parsedGameDate, date > Date() {
                return .scheduled
            }
            return nil
        }

        switch raw {
        case "final", "completed":
            return .completed
        case "live", "in_progress", "inprogress":
            return .inProgress
        case "scheduled", "upcoming":
            return .scheduled
        case "postponed":
            return .postponed
        case "canceled", "cancelled":
            return .canceled
        default:
            return nil
        }
    }

    /// Convenience accessors for team names
    var homeTeamName: String { homeTeam }
    var awayTeamName: String { awayTeam }
    var homeTeamAbbreviation: String { String(homeTeam.prefix(3)).uppercased() }
    var awayTeamAbbreviation: String { String(awayTeam.prefix(3)).uppercased() }

    /// League code accessor (for compatibility)
    var league: String { leagueCode }

    /// Start time accessor (for compatibility)
    var startTime: String { gameDate }

    /// Formatted score string (e.g., "112 - 108")
    var scoreDisplay: String {
        guard let home = homeScore, let away = awayScore else {
            return "— vs —"
        }
        return "\(home) - \(away)"
    }

    /// Parsed game date
    var parsedGameDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: gameDate) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: gameDate)
    }

    /// Formatted date for display
    var formattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Short formatted date (e.g., "Jan 1 • 7:30 PM")
    var shortFormattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d")
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return "\(dateFormatter.string(from: date)) • \(timeFormatter.string(from: date))"
    }

    var statusLine: String {
        guard let status else {
            GameStatusLogger.logMissingStatus(gameId: id, league: leagueCode)
            return Formatting.statusUnavailableText
        }

        switch status {
        case .scheduled:
            guard let date = parsedGameDate else { return Formatting.startsAtPrefix + formattedDate }
            return Formatting.startsAtPrefix + formattedTime(date: date)
        case .inProgress:
            return Formatting.inProgressText
        case .completed, .final:
            return Formatting.completedText
        case .postponed:
            return Formatting.postponedText
        case .canceled:
            return Formatting.canceledText
        }
    }

    private func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
