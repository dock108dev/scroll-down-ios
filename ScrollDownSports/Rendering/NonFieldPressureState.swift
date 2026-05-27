import Foundation

struct GolfPressureState {
    let metadata: [String: JSONValue]
    let hole: Int?
    let round: String?
    let scoreToPar: String?
    let rank: String?
    let strokesBack: String?
    let movement: String?

    init(event: GameEvent) {
        metadata = nonFieldSportMetadata(for: event, sportKey: "golf")
        hole = nonFieldInteger(["hole", "holeNumber", "currentHole"], in: metadata)
        round = nonFieldText(["round", "roundLabel", "round_label"], in: metadata) ?? event.periodLabel?.nilIfBlank
        scoreToPar = nonFieldText(["scoreToPar", "toPar", "scoreText"], in: metadata)
        rank = nonFieldText(["rank", "position", "leaderboardRank", "currentRank"], in: metadata)
        strokesBack = nonFieldText(["strokesBack", "leaderboardGap", "gapToLead", "back"], in: metadata)
        movement = Self.movementText(in: metadata)
    }

    var hasLeaderboardPressureSignal: Bool {
        hole != nil || scoreToPar != nil || rank != nil || strokesBack != nil || hasMovement
    }

    var hasMovement: Bool {
        movement?.nilIfBlank != nil
    }

    var contextLine: String? {
        [
            round,
            hole.map { "Hole \($0)" }
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private static func movementText(in metadata: [String: JSONValue]) -> String? {
        if let text = nonFieldText(["movement", "leaderboardMovement", "rankMovement", "positionChange"], in: metadata) {
            return text
        }
        if let change = nonFieldNumber(["rankChange", "positionDelta"], in: metadata), change != 0 {
            return change < 0 ? "Up \(Int(abs(change)))" : "Down \(Int(change))"
        }
        guard let previous = nonFieldInteger(["previousRank", "previousPosition"], in: metadata),
              let current = nonFieldInteger(["currentRank", "rank", "position"], in: metadata),
              previous != current else {
            return nil
        }
        return current < previous ? "Up \(previous - current)" : "Down \(current - previous)"
    }
}

struct TennisPressureState {
    let metadata: [String: JSONValue]
    let setText: String?
    let gameText: String?
    let pointState: String?
    let server: String?
    let isBreakPoint: Bool
    let isMatchPoint: Bool
    let isSetPoint: Bool
    let isDeuce: Bool
    let isTiebreak: Bool

    init(event: GameEvent) {
        metadata = nonFieldSportMetadata(for: event, sportKey: "tennis")
        setText = Self.setText(event: event, metadata: metadata)
        gameText = nonFieldText(["game", "gameScore", "games", "scoreGame"], in: metadata) ?? event.clockLabel?.nilIfBlank
        pointState = nonFieldText(["point", "pointState", "pointScore", "scoreState"], in: metadata)
        server = nonFieldText(["server", "serving", "serverTeamAbbreviation", "serverTeam"], in: metadata)
        let eventType = nonFieldNormalized(event.eventType)
        let point = nonFieldNormalized(pointState)
        isBreakPoint = nonFieldBool(["breakPoint", "isBreakPoint"], in: metadata) == true
            || eventType == "break_point"
            || point == "break_point"
        isMatchPoint = nonFieldBool(["matchPoint", "isMatchPoint"], in: metadata) == true
            || eventType == "match_point"
            || point == "match_point"
        isSetPoint = nonFieldBool(["setPoint", "isSetPoint"], in: metadata) == true
            || eventType == "set_point"
            || point == "set_point"
        isDeuce = nonFieldBool(["deuce", "isDeuce"], in: metadata) == true
            || eventType == "deuce"
            || point == "deuce"
        isTiebreak = nonFieldBool(["tiebreak", "isTiebreak"], in: metadata) == true
            || eventType == "tiebreak_swing"
            || nonFieldNormalized(gameText).contains("tiebreak")
    }

    var hasScoreState: Bool {
        pointState != nil
            || nonFieldText(["set", "setNumber", "set_number", "setLabel", "set_label"], in: metadata) != nil
            || nonFieldText(["game", "gameScore", "games", "scoreGame"], in: metadata) != nil
    }

    var hasPointPressureSignal: Bool {
        isBreakPoint || isMatchPoint || isSetPoint || isDeuce || isTiebreak || hasScoreState || server != nil
    }

    var contextLine: String? {
        [
            setText,
            gameText
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " · ")
            .nilIfBlank
    }

    private static func setText(event: GameEvent, metadata: [String: JSONValue]) -> String? {
        if let value = nonFieldText(["setLabel", "set_label"], in: metadata) {
            return value
        }
        if let set = nonFieldInteger(["set", "setNumber", "set_number"], in: metadata) {
            return "Set \(set)"
        }
        return event.periodLabel?.nilIfBlank
    }
}

func appendMetric(
    label: String,
    value: String?,
    emphasis: PressureBoardSituationMetricEmphasis,
    to metrics: inout [PressureBoardSituationMetric]
) {
    guard let value = value?.nilIfBlank,
          !metrics.contains(where: { $0.label == label && $0.value == value }) else {
        return
    }
    metrics.append(PressureBoardSituationMetric(label: label, value: value, emphasis: emphasis))
}

func nonFieldSportMetadata(for event: GameEvent, sportKey: String) -> [String: JSONValue] {
    var metadata = event.sportMetadata
    if case .object(let nested)? = nonFieldValue(for: "\(sportKey)Situation", in: metadata) {
        metadata.merge(nested) { _, new in new }
    }
    if case .object(let nested)? = nonFieldValue(for: sportKey, in: metadata) {
        metadata.merge(nested) { _, new in new }
    }
    if let firstClass = nonFieldFirstClassMetadata(for: event, sportKey: sportKey) {
        metadata.merge(firstClass) { current, _ in current }
    }
    return metadata
}

func nonFieldValue(for key: String, in metadata: [String: JSONValue]) -> JSONValue? {
    if let value = metadata[key] { return value }
    let normalizedKey = nonFieldNormalized(key)
    return metadata.first { nonFieldNormalized($0.key) == normalizedKey }?.value
}

func nonFieldText(_ keys: [String], in metadata: [String: JSONValue]) -> String? {
    for key in keys {
        if let value = nonFieldValue(for: key, in: metadata)?.textValue?.nilIfBlank {
            return value
        }
    }
    return nil
}

func nonFieldNumber(_ keys: [String], in metadata: [String: JSONValue]) -> Double? {
    for key in keys {
        guard let value = nonFieldValue(for: key, in: metadata) else { continue }
        switch value {
        case .number(let number):
            return number
        case .string(let text):
            if let number = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return number
            }
        default:
            continue
        }
    }
    return nil
}

func nonFieldInteger(_ keys: [String], in metadata: [String: JSONValue]) -> Int? {
    for key in keys {
        guard let value = nonFieldValue(for: key, in: metadata) else { continue }
        switch value {
        case .number(let number) where number.rounded() == number:
            return Int(number)
        case .string(let text):
            if let integer = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return integer
            }
        default:
            continue
        }
    }
    return nil
}

func nonFieldBool(_ keys: [String], in metadata: [String: JSONValue]) -> Bool? {
    for key in keys {
        guard let value = nonFieldValue(for: key, in: metadata) else { continue }
        switch value {
        case .bool(let bool):
            return bool
        case .string(let text):
            switch nonFieldNormalized(text) {
            case "true", "yes":
                return true
            case "false", "no":
                return false
            default:
                continue
            }
        default:
            continue
        }
    }
    return nil
}

func nonFieldNormalized(_ value: String?) -> String {
    value?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        .trimmingCharacters(in: CharacterSet(charactersIn: "_")) ?? ""
}

private func nonFieldFirstClassMetadata(for event: GameEvent, sportKey: String) -> [String: JSONValue]? {
    guard let snapshot = event.situationBefore,
          snapshot.normalizedSport == sportKey,
          snapshot.hasRenderableConfidence else {
        return nil
    }
    switch sportKey {
    case "golf":
        return snapshot.sportState?.golf
    case "tennis":
        return snapshot.sportState?.tennis
    default:
        return nil
    }
}
