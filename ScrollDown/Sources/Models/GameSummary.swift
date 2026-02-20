import Foundation

/// Game summary for list views matching the admin API /games endpoint
/// All fields use camelCase per API specification
struct GameSummary: Codable, Identifiable, Hashable {
    let id: Int
    let leagueCode: String
    let gameDate: String
    private let statusRaw: String?
    let homeTeam: String

    enum CodingKeys: String, CodingKey {
        case id, leagueCode, gameDate, homeTeam, awayTeam
        case statusRaw = "status"
        case homeScore, awayScore
        case hasBoxscore, hasPlayerStats, hasOdds, hasSocial, hasPbp, hasFlow
        case playCount, socialPostCount, hasRequiredData, scrapeVersion
        case lastScrapedAt, lastIngestedAt, lastPbpAt, lastSocialAt
        case homeTeamColorLight, homeTeamColorDark, awayTeamColorLight, awayTeamColorDark
        case homeTeamAbbr, awayTeamAbbr
        case derivedMetrics
    }
    let awayTeam: String
    let homeScore: Int?
    let awayScore: Int?
    let hasBoxscore: Bool?
    let hasPlayerStats: Bool?
    let hasOdds: Bool?
    let hasSocial: Bool?
    let hasPbp: Bool?
    let hasFlow: Bool?
    let playCount: Int?
    let socialPostCount: Int?
    let hasRequiredData: Bool?
    let scrapeVersion: Int?
    let lastScrapedAt: String?
    let lastIngestedAt: String?
    let lastPbpAt: String?
    let lastSocialAt: String?
    let homeTeamColorLight: String?
    let homeTeamColorDark: String?
    let awayTeamColorLight: String?
    let awayTeamColorDark: String?
    let homeTeamAbbr: String?
    let awayTeamAbbr: String?
    let derivedMetrics: [String: AnyCodable]?

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
        hasFlow: Bool? = nil,
        playCount: Int?,
        socialPostCount: Int?,
        hasRequiredData: Bool?,
        scrapeVersion: Int?,
        lastScrapedAt: String?,
        homeTeamColorLight: String? = nil,
        homeTeamColorDark: String? = nil,
        awayTeamColorLight: String? = nil,
        awayTeamColorDark: String? = nil,
        homeTeamAbbr: String? = nil,
        awayTeamAbbr: String? = nil
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
        self.hasFlow = hasFlow
        self.playCount = playCount
        self.socialPostCount = socialPostCount
        self.hasRequiredData = hasRequiredData
        self.scrapeVersion = scrapeVersion
        self.lastScrapedAt = lastScrapedAt
        self.lastIngestedAt = nil
        self.lastPbpAt = nil
        self.lastSocialAt = nil
        self.homeTeamColorLight = homeTeamColorLight
        self.homeTeamColorDark = homeTeamColorDark
        self.awayTeamColorLight = awayTeamColorLight
        self.awayTeamColorDark = awayTeamColorDark
        self.homeTeamAbbr = homeTeamAbbr
        self.awayTeamAbbr = awayTeamAbbr
        self.derivedMetrics = nil
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

        static let isoFormatterFractional: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f
        }()
        static let isoFormatter: ISO8601DateFormatter = {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime]
            return f
        }()
        static let mediumDateTimeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f
        }()
        static let shortDateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.setLocalizedDateFormatFromTemplate("MMM d")
            return f
        }()
        static let timeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.timeStyle = .short
            return f
        }()
    }

    /// Status from API string, or derived from data when absent.
    var status: GameStatus? {
        if let raw = statusRaw {
            return GameStatus(rawValue: raw)
        }
        if hasRequiredData == true || (homeScore != nil && awayScore != nil) {
            return .completed
        }
        if let date = parsedGameDate, date > Date() {
            return .scheduled
        }
        return nil
    }

    /// Convenience accessors for team names
    var homeTeamName: String { homeTeam }
    var awayTeamName: String { awayTeam }
    var homeTeamAbbreviation: String { homeTeamAbbr ?? TeamAbbreviations.abbreviation(for: homeTeam) }
    var awayTeamAbbreviation: String { awayTeamAbbr ?? TeamAbbreviations.abbreviation(for: awayTeam) }

    /// League code shorthand
    var league: String { leagueCode }

    /// Game date shorthand
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
        Formatting.isoFormatterFractional.date(from: gameDate)
            ?? Formatting.isoFormatter.date(from: gameDate)
    }

    /// Formatted date for display
    var formattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        return Formatting.mediumDateTimeFormatter.string(from: date)
    }

    /// Short formatted date (e.g., "Jan 1 • 7:30 PM")
    var shortFormattedDate: String {
        guard let date = parsedGameDate else { return gameDate }
        return "\(Formatting.shortDateFormatter.string(from: date)) • \(Formatting.timeFormatter.string(from: date))"
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
        case .unknown:
            return formattedDate
        }
    }

    private func formattedTime(date: Date) -> String {
        Formatting.timeFormatter.string(from: date)
    }
}
