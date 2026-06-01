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
    let playCard: SDANormalizedPlayCardDTO?
}

struct SDANormalizedPlayCardDTO: Decodable, Hashable, Sendable {
    let schemaVersion: Int?
    let cardId: String?
    let visualImportance: String?
    let accent: SDANormalizedPlayCardAccentDTO?
    let clock: SDANormalizedPlayCardTextDTO?
    let leadIn: SDANormalizedPlayCardTextDTO?
    let headline: SDANormalizedPlayCardTextDTO?
    let body: SDANormalizedPlayCardTextDTO?
    let contextItems: [SDANormalizedPlayCardContextItemDTO]?
    let resultItems: [SDANormalizedPlayCardResultItemDTO]?
    let score: SDANormalizedPlayCardScoreDTO?
    let team: SDANormalizedPlayCardTeamDTO?
    let situation: SDANormalizedPlayCardSituationDTO?
    let rawFeed: SDANormalizedPlayCardRawFeedDTO?
    let accessibility: SDANormalizedPlayCardAccessibilityDTO?

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case cardId
        case cardID
        case visualImportance
        case accent
        case clock
        case leadIn
        case headline
        case body
        case contextItems
        case resultItems
        case score
        case team
        case situation
        case rawFeed
        case accessibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        cardId = try container.decodeIfPresent(String.self, forKey: .cardId)
            ?? container.decodeIfPresent(String.self, forKey: .cardID)
        visualImportance = try container.decodeIfPresent(String.self, forKey: .visualImportance)
        accent = try container.decodeIfPresent(SDANormalizedPlayCardAccentDTO.self, forKey: .accent)
        clock = try container.decodeIfPresent(SDANormalizedPlayCardTextDTO.self, forKey: .clock)
        leadIn = try container.decodeIfPresent(SDANormalizedPlayCardTextDTO.self, forKey: .leadIn)
        headline = try container.decodeIfPresent(SDANormalizedPlayCardTextDTO.self, forKey: .headline)
        body = try container.decodeIfPresent(SDANormalizedPlayCardTextDTO.self, forKey: .body)
        contextItems = try container.decodeIfPresent([SDANormalizedPlayCardContextItemDTO].self, forKey: .contextItems)
        resultItems = try container.decodeIfPresent([SDANormalizedPlayCardResultItemDTO].self, forKey: .resultItems)
        score = try container.decodeIfPresent(SDANormalizedPlayCardScoreDTO.self, forKey: .score)
        team = try container.decodeIfPresent(SDANormalizedPlayCardTeamDTO.self, forKey: .team)
        situation = try container.decodeIfPresent(SDANormalizedPlayCardSituationDTO.self, forKey: .situation)
        rawFeed = try container.decodeIfPresent(SDANormalizedPlayCardRawFeedDTO.self, forKey: .rawFeed)
        accessibility = try container.decodeIfPresent(SDANormalizedPlayCardAccessibilityDTO.self, forKey: .accessibility)
    }
}

struct SDANormalizedPlayCardTextDTO: Decodable, Hashable, Sendable {
    let text: String?
    let tone: String?
    let maxLines: Int?
}

struct SDANormalizedPlayCardAccentDTO: Decodable, Hashable, Sendable {
    let tone: String?
    let participantRole: String?
    let teamAbbreviation: String?
}

struct SDANormalizedPlayCardContextItemDTO: Decodable, Hashable, Sendable {
    let id: String?
    let kind: String?
    let text: String?
    let tone: String?
    let participantRole: String?
    let teamAbbreviation: String?
}

struct SDANormalizedPlayCardResultItemDTO: Decodable, Hashable, Sendable {
    let id: String?
    let text: String?
    let tone: String?
    let priority: Int?
}

struct SDANormalizedPlayCardScoreDTO: Decodable, Hashable, Sendable {
    let label: String?
    let value: String?
    let isScoringPlay: Bool?
    let spoilerPolicy: String?
}

struct SDANormalizedPlayCardTeamDTO: Decodable, Hashable, Sendable {
    let participantRole: String?
    let abbreviation: String?
    let displayName: String?
    let label: String?
}

struct SDANormalizedPlayCardSituationDTO: Decodable, Hashable, Sendable {
    let title: String?
    let periodText: String?
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: String?
    let layout: String?
    let ownership: SDANormalizedPlayCardSituationOwnershipDTO?
    let accent: SDANormalizedPlayCardAccentDTO?
    let dataConfidence: String?
}

struct SDANormalizedPlayCardSituationOwnershipDTO: Decodable, Hashable, Sendable {
    let role: String?
    let participantRole: String?
    let teamAbbreviation: String?
    let teamLabel: String?
    let confidence: String?
}

struct SDANormalizedPlayCardRawFeedDTO: Decodable, Hashable, Sendable {
    let text: String?
    let source: String?
    let updatedAt: String?
    let disclosureTitle: String?
}

struct SDANormalizedPlayCardAccessibilityDTO: Decodable, Hashable, Sendable {
    let label: String?
    let value: String?
    let hint: String?
    let situationSummary: String?
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
