import Foundation

struct SDAMobilePresentationDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let headline: String?
    let shortHeadline: String?
    let body: String?
    let subheadline: String?
    let matchupLabel: String?
    let primaryLabel: String?
    let secondaryLabel: String?
    let tertiaryLabel: String?
    let accessibilityLabel: String?
    let displayState: String?
    let visualPriority: Int?
    let sortBucket: String?
    let theme: SDAPresentationThemeDTO?
    let eventCounts: SDAEventCountsDTO?
    let displayLabels: SDADisplayLabelsDTO?
    let scoreboardPlacement: String?
    let timeLabel: String?
    let eventTypeLabel: String?
    let teamLabel: String?
    let playerLabel: String?
    let scoreLabel: String?
}

struct SDAPresentationThemeDTO: Decodable, Hashable, Sendable {
    let accentRole: String?
    let statusTone: String?
}

struct SDAEventCountsDTO: Decodable, Hashable, Sendable {
    let key: Int?
    let flow: Int?
    let full: Int?
}

struct SDADisplayLabelsDTO: Decodable, Hashable, Sendable {
    let status: String?
    let primaryAction: String?
    let secondaryContext: String?
}

struct SDAGameEligibilityDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let catchUp: SDAModeEligibilityDTO?
    let playByPlay: SDAModeEligibilityDTO?
    let keyMoments: SDAModeEligibilityDTO?
    let boxScore: SDAModeEligibilityDTO?
    let teamStats: SDAModeEligibilityDTO?
    let playerStats: SDAModeEligibilityDTO?
    let liveTracker: SDAModeEligibilityDTO?
    let recap: SDAModeEligibilityDTO?
}

struct SDAModeEligibilityDTO: Decodable, Hashable, Sendable {
    let isEligible: Bool?
    let reason: String?
    let minimumEventCount: Int?
    let availableEventCount: Int?
}

struct SDAScoreboardDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let layout: String?
    let clockLabel: String?
    let periodLabel: String?
    let statusLabel: String?
    let scoreline: String?
    let competitors: [SDAScoreboardCompetitorDTO]?
    let segments: [SDAScoreboardSegmentDTO]?
    let totals: SDAScoreboardTotalsDTO?
}

struct SDAScoreboardCompetitorDTO: Decodable, Hashable, Sendable {
    let side: String?
    let teamName: String?
    let teamAbbreviation: String?
    let score: Int?
    let scoreText: String?
    let isWinner: Bool?
    let recordText: String?
}

struct SDAScoreboardSegmentDTO: Decodable, Hashable, Sendable {
    let label: String?
    let away: String?
    let home: String?
}

struct SDAScoreboardTotalsDTO: Decodable, Hashable, Sendable {
    let away: String?
    let home: String?
}

struct SDAEventImportanceDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let level: String
    let rank: Int?
    let bucket: String?
    let reasons: [String]
    let isKeyMoment: Bool
    let isScoringPlay: Bool
    let isLeadChange: Bool
    let isTyingPlay: Bool
    let isLateGame: Bool
    let isFinalPlay: Bool?
    let isRunEnding: Bool?
    let winProbabilityDelta: Double?
}

struct SDAEventScoreboardDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let scoreBefore: SDAScoreSnapshotDTO?
    let scoreAfter: SDAScoreSnapshotDTO?
    let scoreDelta: SDAScoreDeltaDTO?
}

struct SDAScoreSnapshotDTO: Decodable, Hashable, Sendable {
    let away: Int?
    let home: Int?
    let scoreText: String?
    let isTied: Bool?
    let leaderSide: String?
}

struct SDAScoreDeltaDTO: Decodable, Hashable, Sendable {
    let side: String?
    let participantRole: String?
    let participantID: String?
    let before: Int?
    let after: Int?
    let change: Int?
    let scoreText: String?
}

struct SDAEventModeEligibilityDTO: Decodable, Hashable, Sendable {
    let important: Bool
    let standard: Bool
    let all: Bool
}
