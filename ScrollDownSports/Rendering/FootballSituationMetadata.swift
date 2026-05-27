import Foundation

extension FootballRenderer {
    func footballFieldSituation(for event: GameEvent) -> FootballFieldSituation? {
        footballSituationInputs(for: event).fieldSituation
    }

    func footballSituationInputs(for event: GameEvent) -> FootballSituationInputs {
        let firstClass = firstClassFootballMetadata(for: event)
        let explicitMetadata = firstClass
            ?? explicitFootballMetadata(from: event.sportMetadata)
        let genericMetadata = hasExplicitFootballTiming(in: event.sportMetadata) ? event.sportMetadata : [:]
        let fieldSituation = explicitMetadata.flatMap {
            footballFieldSituation(from: $0, event: event, isFirstClass: firstClass != nil)
        } ?? footballFieldSituation(from: genericMetadata, event: event, isFirstClass: false)
        let hasExplicit = explicitMetadata != nil || !genericMetadata.isEmpty
        let hasPartialExplicit = hasExplicit && fieldSituation == nil
        let hasAmbiguous = hasAmbiguousFootballMetadata(event.sportMetadata)
        let evidence = SituationConfidenceEvidence(
            hasExplicitPreEventState: fieldSituation != nil,
            hasExplicitGenericContext: SituationConfidenceGate.hasGenericContext(for: event),
            hasDerivedState: false,
            hasAmbiguousMetadata: hasAmbiguous || hasPartialExplicit,
            hasEventLocalContext: SituationConfidenceGate.hasEventLocalContext(for: event)
        )
        return FootballSituationInputs(
            fieldSituation: fieldSituation,
            confidenceDecision: SituationConfidenceGate.decision(for: evidence)
        )
    }

    private func firstClassFootballMetadata(for event: GameEvent) -> [String: JSONValue]? {
        guard let snapshot = event.situationBefore,
              snapshot.normalizedSport == "football" || snapshot.normalizedSport == "nfl",
              snapshot.hasRenderableConfidence,
              let football = snapshot.sportState?.football,
              !football.isEmpty else {
            return nil
        }
        var metadata = football
        if let possession = snapshot.possession {
            metadata.merge(possession) { current, _ in current }
        }
        if let label = snapshot.clock?.label?.nilIfBlank {
            metadata["clockLabel"] = .string(label)
        }
        return metadata
    }

    private func explicitFootballMetadata(from metadata: [String: JSONValue]) -> [String: JSONValue]? {
        var explicit: [String: JSONValue] = [:]
        for key in ["preSnap", "pre_snap", "preplay", "prePlay", "before", "situationBefore", "situation_before", "stateBefore", "state_before"] {
            if case .object(let nested)? = situationMetadataValue(for: key, in: metadata) {
                explicit.merge(nested) { current, _ in current }
            }
        }
        for key in footballExplicitKeys {
            if explicit[key] == nil, let value = situationMetadataValue(for: key, in: metadata) {
                explicit[key] = value
            }
        }
        return explicit.isEmpty ? nil : explicit
    }

    private func footballFieldSituation(
        from metadata: [String: JSONValue],
        event: GameEvent,
        isFirstClass: Bool
    ) -> FootballFieldSituation? {
        guard let down = footballDown(from: metadata),
              let distance = footballDistance(from: metadata),
              let yardLine = footballYardLine(from: metadata) else {
            return nil
        }
        let possession = footballPossession(from: metadata, event: event)
        guard yardLine.requiresPossession == false || possession != nil else {
            return nil
        }
        return FootballFieldSituation(
            down: down,
            distance: distance,
            yardLine: yardLine,
            possession: possession,
            source: isFirstClass ? .backendSituationBefore : .sportMetadata
        )
    }

    private func footballDown(from metadata: [String: JSONValue]) -> Int? {
        for key in ["footballDown", "downBefore", "preSnapDown", "down"] {
            guard let value = situationMetadataValue(for: key, in: metadata) else { continue }
            if let down = situationInteger(from: value), (1...4).contains(down) {
                return down
            }
            guard let text = value.textValue?.nilIfBlank else { continue }
            switch normalizedSituationMetadataKey(text) {
            case "1st", "first": return 1
            case "2nd", "second": return 2
            case "3rd", "third": return 3
            case "4th", "fourth": return 4
            default: continue
            }
        }
        return nil
    }

    private func footballDistance(from metadata: [String: JSONValue]) -> FootballDistance? {
        for key in ["footballDistance", "distanceBefore", "preSnapDistance", "yardsToGo", "toGo", "distance"] {
            guard let value = situationMetadataValue(for: key, in: metadata) else { continue }
            if let yards = situationInteger(from: value), (1...99).contains(yards) {
                return .yards(yards)
            }
            guard let text = value.textValue?.nilIfBlank else { continue }
            switch normalizedSituationMetadataKey(text) {
            case "goal", "goal_to_go", "goal_to_goal":
                return .goalToGo
            case "inches", "short":
                return .inches
            default:
                if let yards = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)), (1...99).contains(yards) {
                    return .yards(yards)
                }
            }
        }
        return nil
    }

    private func footballYardLine(from metadata: [String: JSONValue]) -> FootballYardLine? {
        let team = situationMetadataText(["footballYardLineTeam", "yardLineTeam", "yard_line_team"], in: metadata)
        let number = situationMetadataInteger(["footballYardLineNumber", "yardLineNumber", "yard_line_number"], in: metadata)
        if let number, let yardLine = FootballYardLine(team: team, yardNumber: number) {
            return yardLine
        }
        for key in ["footballYardLine", "lineOfScrimmage", "line_of_scrimmage", "yardLine", "yard_line"] {
            guard let value = situationMetadataValue(for: key, in: metadata),
                  let yardLine = value.textValue.flatMap(FootballYardLine.init(rawValue:)) else {
                continue
            }
            return yardLine
        }
        return nil
    }

    private func footballPossession(from metadata: [String: JSONValue], event: GameEvent) -> FootballPossession? {
        let abbreviation = situationMetadataText(
            [
                "footballPossessionTeam",
                "footballPossessionTeamAbbreviation",
                "possessionTeam",
                "possessionTeamAbbreviation",
                "offenseTeam",
                "offenseTeamAbbreviation"
            ],
            in: metadata
        )
        let role = situationMetadataText(
            ["footballPossessionRole", "possessionRole", "offenseTeamRole", "offenseRole"],
            in: metadata
        ).flatMap(situationParticipantRole(from:))
        guard abbreviation?.nilIfBlank != nil || role != nil else {
            return nil
        }
        return FootballPossession(
            teamAbbreviation: abbreviation?.nilIfBlank,
            participantRole: role,
            teamLabel: role == event.teamOwnership ? event.presentation?.teamLabel : nil
        )
    }

    private func hasExplicitFootballTiming(in metadata: [String: JSONValue]) -> Bool {
        guard let timing = situationMetadataText(
            ["situationTiming", "stateTiming", "timing", "metadataTiming", "sourceTiming"],
            in: metadata
        ).map(normalizedSituationMetadataKey) else {
            return false
        }
        return ["before", "before_play", "pre_event", "pre_play", "pre_snap", "presnap"].contains(timing)
    }

    private func hasAmbiguousFootballMetadata(_ metadata: [String: JSONValue]) -> Bool {
        !hasExplicitFootballTiming(in: metadata)
            && ["down", "distance", "yardLine", "yard_line", "lineOfScrimmage", "line_of_scrimmage"].contains {
                situationMetadataValue(for: $0, in: metadata) != nil
            }
    }

    private var footballExplicitKeys: [String] {
        [
            "footballDown", "downBefore", "preSnapDown",
            "footballDistance", "distanceBefore", "preSnapDistance", "yardsToGo", "toGo",
            "footballYardLine", "footballYardLineTeam", "footballYardLineNumber",
            "yardLineTeam", "yardLineNumber", "lineOfScrimmage",
            "footballPossessionTeam", "footballPossessionTeamAbbreviation", "footballPossessionRole",
            "possessionTeam", "possessionTeamAbbreviation", "possessionRole",
            "offenseTeam", "offenseTeamAbbreviation", "offenseTeamRole", "offenseRole"
        ]
    }

}

struct FootballSituationInputs: Hashable, Sendable {
    let fieldSituation: FootballFieldSituation?
    let confidenceDecision: SituationBlockDecision
}

struct FootballFieldSituation: Hashable, Sendable {
    let down: Int
    let distance: FootballDistance
    let yardLine: FootballYardLine
    let possession: FootballPossession?
    let source: FootballSituationSource

    var downDistanceText: String {
        "\(Self.ordinal(down)) & \(distance.label)"
    }

    private static func ordinal(_ value: Int) -> String {
        switch value {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        default: return "\(value)"
        }
    }
}

enum FootballDistance: Hashable, Sendable {
    case yards(Int)
    case goalToGo
    case inches

    var label: String {
        switch self {
        case .yards(let yards):
            return "\(yards)"
        case .goalToGo:
            return "goal"
        case .inches:
            return "inches"
        }
    }

    var targetYards: Double? {
        switch self {
        case .yards(let yards):
            return Double(yards)
        case .goalToGo:
            return nil
        case .inches:
            return 1
        }
    }
}

struct FootballYardLine: Hashable, Sendable {
    let teamAbbreviation: String?
    let yardNumber: Int
    let side: FootballYardLineSide

    var label: String {
        switch side {
        case .team:
            return [teamAbbreviation, String(yardNumber)].compactMap { $0?.nilIfBlank }.joined(separator: " ")
        case .own:
            return "Own \(yardNumber)"
        case .opponent:
            return "Opp \(yardNumber)"
        case .midfield:
            return "50"
        }
    }

    var requiresPossession: Bool {
        side == .own || side == .opponent
    }

    init?(team: String?, yardNumber: Int) {
        if yardNumber == 50 {
            self.teamAbbreviation = team?.nilIfBlank
            self.yardNumber = yardNumber
            self.side = .midfield
            return
        }
        guard (1...49).contains(yardNumber),
              let team = team?.nilIfBlank else {
            return nil
        }
        self.teamAbbreviation = team
        self.yardNumber = yardNumber
        self.side = .team
    }

    init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.range(of: #"\bto\b|->|/"#, options: [.regularExpression, .caseInsensitive]) == nil else {
            return nil
        }
        let regex = try? NSRegularExpression(pattern: #"[0-9]{1,2}"#)
        let nsRange = NSRange(trimmed.startIndex..., in: trimmed)
        let numberMatches = regex?.matches(in: trimmed, range: nsRange) ?? []
        guard numberMatches.count == 1,
              let range = Range(numberMatches[0].range, in: trimmed),
              let number = Int(trimmed[range]) else {
            return nil
        }
        let teamToken = trimmed
            .replacingOccurrences(of: #"[0-9\-\s]"#, with: "", options: .regularExpression)
            .nilIfBlank
        let normalizedTeam = teamToken?.uppercased()
        if number == 50 {
            teamAbbreviation = normalizedTeam == "MID" ? nil : normalizedTeam
            yardNumber = number
            side = .midfield
        } else if normalizedTeam == "OWN", (1...49).contains(number) {
            teamAbbreviation = nil
            yardNumber = number
            side = .own
        } else if normalizedTeam == "OPP", (1...49).contains(number) {
            teamAbbreviation = nil
            yardNumber = number
            side = .opponent
        } else if let normalizedTeam, (1...49).contains(number) {
            teamAbbreviation = normalizedTeam
            yardNumber = number
            side = .team
        } else {
            return nil
        }
    }
}

enum FootballYardLineSide: Hashable, Sendable {
    case team
    case own
    case opponent
    case midfield
}

struct FootballPossession: Hashable, Sendable {
    let teamAbbreviation: String?
    let participantRole: GameParticipantRole?
    let teamLabel: String?
}

enum FootballSituationSource: Hashable, Sendable {
    case sportMetadata
    case backendSituationBefore
}

struct FootballFieldStripDiagram: Hashable {
    let downDistanceText: String
    let yardLineText: String
    let possessionText: String?
    let lineOfScrimmageX: Double
    let firstDownX: Double?
    let offenseDirection: FootballFieldDirection
    let eventTypeText: String?
    let isRedZone: Bool
}

enum FootballFieldDirection: Hashable {
    case leftToRight
    case unknown
}
