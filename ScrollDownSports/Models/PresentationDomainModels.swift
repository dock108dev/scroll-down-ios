import Foundation

struct GamePresentationData: Codable, Hashable, Sendable {
    let headline: String?
    let shortHeadline: String?
    let subheadline: String?
    let matchupLabel: String?
    let primaryLabel: String?
    let secondaryLabel: String?
    let tertiaryLabel: String?
    let accessibilityLabel: String?
    let displayState: String?
    let visualPriority: Int?
    let sortBucket: String?
    let accentRole: String?
    let statusTone: String?
    let eventCounts: DetailModeEventCounts?
    let statusLabel: String?
    let primaryActionLabel: String?
    let secondaryContextLabel: String?
    let scoreboardPlacement: String?

    func eventCount(for mode: DetailStreamMode) -> Int? {
        eventCounts?.count(for: mode)
    }
}

struct DetailModeEventCounts: Codable, Hashable, Sendable {
    let key: Int?
    let flow: Int?
    let full: Int?

    func count(for mode: DetailStreamMode) -> Int? {
        switch mode {
        case .key:
            return key
        case .flow:
            return flow
        case .full:
            return full
        }
    }
}

struct GameEligibilityData: Codable, Hashable, Sendable {
    let catchUp: ModeEligibilityData?
    let playByPlay: ModeEligibilityData?
    let keyMoments: ModeEligibilityData?
    let boxScore: ModeEligibilityData?
    let teamStats: ModeEligibilityData?
    let playerStats: ModeEligibilityData?
    let liveTracker: ModeEligibilityData?
    let recap: ModeEligibilityData?
}

struct ModeEligibilityData: Codable, Hashable, Sendable {
    let isEligible: Bool?
    let reason: String?
    let minimumEventCount: Int?
    let availableEventCount: Int?
}

struct GameScoreboardData: Codable, Hashable, Sendable {
    let layout: String?
    let clockLabel: String?
    let periodLabel: String?
    let statusLabel: String?
    let scoreline: String?
    let competitors: [ScoreboardCompetitorData]
    let segments: [ScoreboardSegmentData]
    let totals: ScoreboardTotalsData?

    var hasDisplayScore: Bool {
        competitors.contains { $0.score != nil || $0.scoreText?.isEmpty == false }
    }
}

struct ScoreboardCompetitorData: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let side: GameParticipantRole
    let teamName: String
    let teamAbbreviation: String?
    let score: Int?
    let scoreText: String?
    let isWinner: Bool?
    let recordText: String?
}

struct ScoreboardSegmentData: Codable, Hashable, Sendable {
    let label: String
    let away: String?
    let home: String?
}

struct ScoreboardTotalsData: Codable, Hashable, Sendable {
    let away: String?
    let home: String?
}

struct EventPresentationData: Codable, Hashable, Sendable {
    let headline: String?
    let shortHeadline: String?
    let body: String?
    let primaryLabel: String?
    let secondaryLabel: String?
    let tertiaryLabel: String?
    let timeLabel: String?
    let accessibilityLabel: String?
    let eventTypeLabel: String?
    let teamLabel: String?
    let playerLabel: String?
    let scoreLabel: String?
}

struct EventImportanceData: Codable, Hashable, Sendable {
    let level: String?
    let rank: Int?
    let bucket: String?
    let reasons: [String]
    let isKeyMoment: Bool?
    let isScoringPlay: Bool?
    let isLeadChange: Bool?
    let isTyingPlay: Bool?
    let winProbabilityDelta: Double?
}
