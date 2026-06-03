import Foundation

struct NormalizedPlayCard: Codable, Hashable, Sendable {
    let schemaVersion: Int
    let cardID: String?
    let renderType: NormalizedPlayCardRenderType
    let narrative: NormalizedPlayCardNarrative?
    let visualImportance: NormalizedPlayCardImportance
    let accent: NormalizedPlayCardAccent?
    let clock: NormalizedPlayCardText?
    let leadIn: NormalizedPlayCardText?
    let headline: NormalizedPlayCardText
    let body: NormalizedPlayCardText?
    let contextItems: [NormalizedPlayCardContextItem]
    let resultItems: [NormalizedPlayCardResultItem]
    let score: NormalizedPlayCardScore?
    let team: NormalizedPlayCardTeam?
    let situation: NormalizedPlayCardSituation?
    let rawFeed: NormalizedPlayCardRawFeed?
    let accessibility: NormalizedPlayCardAccessibility

    init(
        schemaVersion: Int,
        cardID: String?,
        renderType: NormalizedPlayCardRenderType = .standardPBP,
        narrative: NormalizedPlayCardNarrative? = nil,
        visualImportance: NormalizedPlayCardImportance,
        accent: NormalizedPlayCardAccent?,
        clock: NormalizedPlayCardText?,
        leadIn: NormalizedPlayCardText? = nil,
        headline: NormalizedPlayCardText,
        body: NormalizedPlayCardText?,
        contextItems: [NormalizedPlayCardContextItem],
        resultItems: [NormalizedPlayCardResultItem],
        score: NormalizedPlayCardScore?,
        team: NormalizedPlayCardTeam?,
        situation: NormalizedPlayCardSituation?,
        rawFeed: NormalizedPlayCardRawFeed?,
        accessibility: NormalizedPlayCardAccessibility
    ) {
        self.schemaVersion = schemaVersion
        self.cardID = cardID
        self.renderType = renderType
        self.narrative = narrative
        self.visualImportance = visualImportance
        self.accent = accent
        self.clock = clock
        self.leadIn = leadIn
        self.headline = headline
        self.body = body
        self.contextItems = contextItems
        self.resultItems = resultItems
        self.score = score
        self.team = team
        self.situation = situation
        self.rawFeed = rawFeed
        self.accessibility = accessibility
    }
}

enum NormalizedPlayCardRenderType: String, Codable, Hashable, Sendable {
    case importantNarrative
    case standardPBP
    case fullPBP
    case playUnavailable
    case unknown

    init(cardFeedValue: String?) {
        guard let value = cardFeedValue?.nilIfBlank else {
            self = .unknown
            return
        }
        switch value.replacingOccurrences(of: "_", with: "").lowercased() {
        case "importantnarrative":
            self = .importantNarrative
        case "standardpbp":
            self = .standardPBP
        case "fullpbp":
            self = .fullPBP
        case "playunavailable":
            self = .playUnavailable
        default:
            self = .unknown
        }
    }
}

struct NormalizedPlayCardNarrative: Codable, Hashable, Sendable {
    let setupLine: String
    let playLine: String
    let updateLine: String
}

enum NormalizedPlayCardImportance: String, Codable, Hashable, Sendable {
    case critical
    case high
    case medium
    case low
}

enum NormalizedPlayCardTone: String, Codable, Hashable, Sendable {
    case neutral
    case secondary
    case scoring
    case critical
    case possession
    case context
    case muted
}

struct NormalizedPlayCardAccent: Codable, Hashable, Sendable {
    let tone: NormalizedPlayCardTone?
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
}

struct NormalizedPlayCardText: Codable, Hashable, Sendable {
    let text: String
    let tone: NormalizedPlayCardTone?
    let maxLines: Int?
}

struct NormalizedPlayCardContextItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let kind: NormalizedPlayCardContextKind
    let text: String
    let tone: NormalizedPlayCardTone?
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
}

enum NormalizedPlayCardContextKind: String, Codable, Hashable, Sendable {
    case clock
    case teamBadge
    case eventLabel
    case status
    case metadata
}

struct NormalizedPlayCardResultItem: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let text: String
    let tone: NormalizedPlayCardTone?
    let priority: Int
}

struct NormalizedPlayCardScore: Codable, Hashable, Sendable {
    let label: String?
    let value: String?
    let isScoringPlay: Bool
}

struct NormalizedPlayCardTeam: Codable, Hashable, Sendable {
    let participantRole: GameParticipantRole?
    let abbreviation: String?
    let displayName: String?
    let label: String?
}

struct NormalizedPlayCardSituation: Codable, Hashable, Sendable {
    let title: String
    let periodText: String?
    let setupText: String?
    let contextLine: String?
    let pressureLine: String?
    let sport: String
    let layout: String
    let ownership: NormalizedPlayCardSituationOwnership?
    let accent: NormalizedPlayCardAccent?
    let dataConfidence: String
}

struct NormalizedPlayCardSituationOwnership: Codable, Hashable, Sendable {
    let role: String
    let participantRole: GameParticipantRole?
    let teamAbbreviation: String?
    let teamLabel: String?
    let confidence: String
}

struct NormalizedPlayCardRawFeed: Codable, Hashable, Sendable {
    let text: String?
    let source: String?
    let updatedAt: String?
    let disclosureTitle: String?
}

struct NormalizedPlayCardAccessibility: Codable, Hashable, Sendable {
    let label: String
    let value: String?
    let hint: String?
    let situationSummary: String?
}
