import Foundation

enum SituationAccessibilitySummary {
    static func make(for situation: GameEventSituationPresentation) -> String? {
        var fragments: [String] = []

        switch situation.diagram {
        case .baseballDiamond(let baseball):
            appendBaseballFragments(for: baseball, situation: situation, to: &fragments)
        case .footballFieldStrip(let football):
            appendFootballFragments(for: football, situation: situation, to: &fragments)
        case .hockeyRinkStrip(let hockey):
            appendHockeyFragments(for: hockey, situation: situation, to: &fragments)
        case .basketballHalfCourt(let basketball):
            appendBasketballFragments(for: basketball, situation: situation, to: &fragments)
        case .soccerPitchStrip(let soccer):
            appendSoccerFragments(for: soccer, situation: situation, to: &fragments)
        case .pressureBoardFallback(let pressureBoard):
            appendPressureBoardFragments(for: pressureBoard, situation: situation, to: &fragments)
        case nil:
            append(accessibilityPhrase(for: situation.ownership), to: &fragments)
            append(situation.setupText, to: &fragments)
            append(situation.pressureLine, to: &fragments)
            append(situation.contextLine, to: &fragments)
        }

        return fragments
            .map(normalizeForSpeech)
            .reduce(into: [String]()) { result, fragment in
                guard !containsDuplicate(fragment, in: result) else { return }
                result.append(fragment)
            }
            .joined(separator: ". ")
            .nilIfBlank
    }

    private static func appendBaseballFragments(
        for baseball: BaseballSituationDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(accessibilityPhrase(for: situation.ownership ?? baseball.batting), to: &fragments)
        append(baseOccupancyText(for: baseball.occupiedBases), to: &fragments)
        append(outsText(for: baseball.outs), to: &fragments)
        append(baseball.count.map { "\($0) count" }, to: &fragments)
        append(situation.pressureLine, to: &fragments)
        append(situation.contextLine, to: &fragments)
    }

    private static func appendFootballFragments(
        for football: FootballFieldStripDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(accessibilityPhrase(for: situation.ownership), to: &fragments)
        append("\(football.downDistanceText) at \(football.yardLineText)", to: &fragments)
        if football.firstDownX != nil {
            append("First-down marker shown", to: &fragments)
        }
        if football.isRedZone {
            append("Red zone", to: &fragments)
        }
        append(situation.pressureLine, to: &fragments)
        append(situation.contextLine, to: &fragments)
    }

    private static func appendHockeyFragments(
        for hockey: HockeyRinkStripDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(accessibilityPhrase(for: situation.ownership), to: &fragments)
        append(situation.setupText, to: &fragments)
        append(hockey.zone.label, to: &fragments)
        append(hockey.puckLocation.map { "Puck at \($0.label)" }, to: &fragments)
        append(situation.pressureLine, to: &fragments)
        append(situation.contextLine, to: &fragments)
    }

    private static func appendBasketballFragments(
        for basketball: BasketballHalfCourtDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(accessibilityPhrase(for: situation.ownership), to: &fragments)
        append(basketball.clockText, to: &fragments)
        append(basketball.shotClockText.map { "Shot clock \($0)" }, to: &fragments)
        append(basketball.scoreText, to: &fragments)
        append(basketball.bonusText, to: &fragments)
        append(basketball.freeThrowText.map { "Free throws \($0)" }, to: &fragments)
        append(basketball.locationText, to: &fragments)
        append(situation.pressureLine, to: &fragments)
    }

    private static func appendSoccerFragments(
        for soccer: SoccerPitchStripDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(accessibilityPhrase(for: situation.ownership), to: &fragments)
        append(situation.periodText, to: &fragments)
        append(soccer.setPieceText, to: &fragments)
        append(soccer.locationText, to: &fragments)
        append(situation.pressureLine, to: &fragments)
        append(situation.contextLine, to: &fragments)
    }

    private static func appendPressureBoardFragments(
        for pressureBoard: PressureBoardSituationDiagram,
        situation: GameEventSituationPresentation,
        to fragments: inout [String]
    ) {
        append(associationPhrase(for: situation.ownership), to: &fragments)
        append(situation.setupText, to: &fragments)
        append(situation.pressureLine, to: &fragments)
        append(situation.contextLine, to: &fragments)
        pressureBoard.metrics.forEach { metric in
            append("\(metric.label): \(metric.value)", to: &fragments)
        }
        pressureBoard.associations.forEach { ownership in
            append(associationPhrase(for: ownership), to: &fragments)
        }
    }

    private static func baseOccupancyText(for occupiedBases: Set<BaseballBase>) -> String {
        let orderedBases = BaseballBase.allCases.filter { occupiedBases.contains($0) }
        switch orderedBases.count {
        case 0:
            return "Bases empty"
        case 3:
            return "Bases loaded"
        case 1:
            return "Runner on \(orderedBases[0].accessibilityName)"
        default:
            return "Runners on \(orderedBases.map(\.accessibilityName).joined(separator: " and "))"
        }
    }

    private static func outsText(for outs: Int?) -> String? {
        guard let outs else { return nil }
        switch outs {
        case 0:
            return "No outs"
        case 1:
            return "1 out"
        default:
            return "\(outs) outs"
        }
    }

    private static func accessibilityPhrase(for ownership: GameEventSituationOwnership?) -> String? {
        guard let ownership else { return nil }
        let team = ownership.accessibilityTeamName
        switch ownership.role {
        case .batting:
            return [team, "batting"].compactMap(\.self).joined(separator: " ")
        case .possession:
            return [team, "possession"].compactMap(\.self).joined(separator: " ")
        case .offense:
            return [team, "on offense"].compactMap(\.self).joined(separator: " ")
        case .defense:
            return [team, "on defense"].compactMap(\.self).joined(separator: " ")
        case .attackingSide:
            return [team, "attacking"].compactMap(\.self).joined(separator: " ")
        case .association:
            return associationPhrase(for: ownership)
        }
    }

    private static func associationPhrase(for ownership: GameEventSituationOwnership?) -> String? {
        guard let team = ownership?.accessibilityTeamName else { return nil }
        return "Associated with \(team)"
    }

    private static func append(_ text: String?, to fragments: inout [String]) {
        guard let text = text?.nilIfBlank else { return }
        fragments.append(text)
    }

    private static func containsDuplicate(_ candidate: String, in existing: [String]) -> Bool {
        let normalizedCandidate = normalizedMeaning(candidate)
        guard !normalizedCandidate.isEmpty else { return true }
        return existing.contains { fragment in
            let normalizedFragment = normalizedMeaning(fragment)
            guard !normalizedFragment.isEmpty else { return false }
            if normalizedCandidate == normalizedFragment {
                return true
            }
            let minimumContainedLength = 12
            return normalizedCandidate.count >= minimumContainedLength && normalizedFragment.contains(normalizedCandidate)
                || normalizedFragment.count >= minimumContainedLength && normalizedCandidate.contains(normalizedFragment)
        }
    }

    private static func normalizeForSpeech(_ text: String) -> String {
        let normalizedSeparators = text
            .replacingOccurrences(of: "→", with: " to ")
            .replacingOccurrences(of: "->", with: " to ")
            .replacingOccurrences(of: "·", with: ", ")
            .replacingOccurrences(of: "%", with: " percent")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return normalizedSeparators
            .replacingOccurrences(of: " to Up", with: " to up")
            .replacingOccurrences(of: " to Down", with: " to down")
            .replacingOccurrences(of: " to Tied", with: " to tied")
    }

    private static func normalizedMeaning(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "1st", with: "first")
            .replacingOccurrences(of: "2nd", with: "second")
            .replacingOccurrences(of: "3rd", with: "third")
            .replacingOccurrences(of: "bases loaded", with: "runners on first second third")
            .replacingOccurrences(of: "%", with: " percent")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private extension GameEventSituationOwnership {
    var accessibilityTeamName: String? {
        teamLabel?.nilIfBlank ?? teamAbbreviation?.nilIfBlank ?? participantRole?.displayName
    }
}

private extension GameParticipantRole {
    var displayName: String {
        switch self {
        case .home:
            return "Home"
        case .away:
            return "Away"
        case .other(let value):
            return value
        }
    }
}
