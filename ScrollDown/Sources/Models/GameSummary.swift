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

    /// Cached parsed date — parsed once at decode time to avoid repeated ISO8601 parsing.
    private let _parsedGameDate: Date?

    private static func parseGameDate(_ dateString: String) -> Date? {
        GameSummary.Formatting.isoFormatterFractional.date(from: dateString)
            ?? GameSummary.Formatting.isoFormatter.date(from: dateString)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        leagueCode = try c.decode(String.self, forKey: .leagueCode)
        gameDate = try c.decode(String.self, forKey: .gameDate)
        statusRaw = try c.decodeIfPresent(String.self, forKey: .statusRaw)
        homeTeam = try c.decode(String.self, forKey: .homeTeam)
        awayTeam = try c.decode(String.self, forKey: .awayTeam)
        homeScore = try c.decodeIfPresent(Int.self, forKey: .homeScore)
        awayScore = try c.decodeIfPresent(Int.self, forKey: .awayScore)
        hasBoxscore = try c.decodeIfPresent(Bool.self, forKey: .hasBoxscore)
        hasPlayerStats = try c.decodeIfPresent(Bool.self, forKey: .hasPlayerStats)
        hasOdds = try c.decodeIfPresent(Bool.self, forKey: .hasOdds)
        hasSocial = try c.decodeIfPresent(Bool.self, forKey: .hasSocial)
        hasPbp = try c.decodeIfPresent(Bool.self, forKey: .hasPbp)
        hasFlow = try c.decodeIfPresent(Bool.self, forKey: .hasFlow)
        playCount = try c.decodeIfPresent(Int.self, forKey: .playCount)
        socialPostCount = try c.decodeIfPresent(Int.self, forKey: .socialPostCount)
        hasRequiredData = try c.decodeIfPresent(Bool.self, forKey: .hasRequiredData)
        scrapeVersion = try c.decodeIfPresent(Int.self, forKey: .scrapeVersion)
        lastScrapedAt = try c.decodeIfPresent(String.self, forKey: .lastScrapedAt)
        lastIngestedAt = try c.decodeIfPresent(String.self, forKey: .lastIngestedAt)
        lastPbpAt = try c.decodeIfPresent(String.self, forKey: .lastPbpAt)
        lastSocialAt = try c.decodeIfPresent(String.self, forKey: .lastSocialAt)
        homeTeamColorLight = try c.decodeIfPresent(String.self, forKey: .homeTeamColorLight)
        homeTeamColorDark = try c.decodeIfPresent(String.self, forKey: .homeTeamColorDark)
        awayTeamColorLight = try c.decodeIfPresent(String.self, forKey: .awayTeamColorLight)
        awayTeamColorDark = try c.decodeIfPresent(String.self, forKey: .awayTeamColorDark)
        homeTeamAbbr = try c.decodeIfPresent(String.self, forKey: .homeTeamAbbr)
        awayTeamAbbr = try c.decodeIfPresent(String.self, forKey: .awayTeamAbbr)
        derivedMetrics = try c.decodeIfPresent([String: AnyCodable].self, forKey: .derivedMetrics)
        _parsedGameDate = Self.parseGameDate(gameDate)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(leagueCode, forKey: .leagueCode)
        try c.encode(gameDate, forKey: .gameDate)
        try c.encodeIfPresent(statusRaw, forKey: .statusRaw)
        try c.encode(homeTeam, forKey: .homeTeam)
        try c.encode(awayTeam, forKey: .awayTeam)
        try c.encodeIfPresent(homeScore, forKey: .homeScore)
        try c.encodeIfPresent(awayScore, forKey: .awayScore)
        try c.encodeIfPresent(hasBoxscore, forKey: .hasBoxscore)
        try c.encodeIfPresent(hasPlayerStats, forKey: .hasPlayerStats)
        try c.encodeIfPresent(hasOdds, forKey: .hasOdds)
        try c.encodeIfPresent(hasSocial, forKey: .hasSocial)
        try c.encodeIfPresent(hasPbp, forKey: .hasPbp)
        try c.encodeIfPresent(hasFlow, forKey: .hasFlow)
        try c.encodeIfPresent(playCount, forKey: .playCount)
        try c.encodeIfPresent(socialPostCount, forKey: .socialPostCount)
        try c.encodeIfPresent(hasRequiredData, forKey: .hasRequiredData)
        try c.encodeIfPresent(scrapeVersion, forKey: .scrapeVersion)
        try c.encodeIfPresent(lastScrapedAt, forKey: .lastScrapedAt)
        try c.encodeIfPresent(lastIngestedAt, forKey: .lastIngestedAt)
        try c.encodeIfPresent(lastPbpAt, forKey: .lastPbpAt)
        try c.encodeIfPresent(lastSocialAt, forKey: .lastSocialAt)
        try c.encodeIfPresent(homeTeamColorLight, forKey: .homeTeamColorLight)
        try c.encodeIfPresent(homeTeamColorDark, forKey: .homeTeamColorDark)
        try c.encodeIfPresent(awayTeamColorLight, forKey: .awayTeamColorLight)
        try c.encodeIfPresent(awayTeamColorDark, forKey: .awayTeamColorDark)
        try c.encodeIfPresent(homeTeamAbbr, forKey: .homeTeamAbbr)
        try c.encodeIfPresent(awayTeamAbbr, forKey: .awayTeamAbbr)
        try c.encodeIfPresent(derivedMetrics, forKey: .derivedMetrics)
    }

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
        self._parsedGameDate = Self.parseGameDate(gameDate)
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

    /// Parsed game date (cached at decode time)
    var parsedGameDate: Date? {
        _parsedGameDate
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
        case .scheduled, .pregame:
            guard let date = parsedGameDate else { return Formatting.startsAtPrefix + formattedDate }
            return Formatting.startsAtPrefix + formattedTime(date: date)
        case .inProgress, .live:
            return Formatting.inProgressText
        case .completed, .final, .archived:
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
