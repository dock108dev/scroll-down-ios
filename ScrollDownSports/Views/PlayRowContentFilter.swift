import Foundation

struct PlayRowContentFilter {
    struct ResultContext {
        let pressureLine: String?
        let contextLine: String?
    }

    static func visibleDetailText(for presentation: GameEventPresentation) -> String? {
        guard let detail = presentation.detail?.nilIfBlank else {
            return nil
        }
        let situation = presentation.situation
        let resultContext = situation.map(visibleResultContext)
        let existingText = [
            presentation.headline,
            visibleEventLabel(for: presentation),
            visibleScoreLabel(for: presentation),
            visibleTeamLabel(for: presentation),
            presentation.teamAbbreviation,
            presentation.rawFeedText,
            situation?.periodText,
            situation?.setupText,
            resultContext?.pressureLine,
            resultContext?.contextLine,
            situation?.ownership?.teamAbbreviation,
            situation?.ownership?.teamLabel
        ].compactMap { $0?.nilIfBlank }

        guard existingText.contains(where: { duplicatesMeaning(detail, comparedWith: $0) }) == false,
              isPlayerOnlyRepeat(detail, headline: presentation.headline) == false else {
            return nil
        }
        return detail
    }

    static func visibleEventLabel(for presentation: GameEventPresentation) -> String? {
        guard let eventLabel = presentation.eventLabel?.nilIfBlank else {
            return nil
        }
        let situation = presentation.situation
        let existingText = [
            presentation.headline,
            situation?.pressureLine,
            situation?.contextLine,
            presentation.scoringLabel,
            presentation.scoreLabel
        ].compactMap { $0?.nilIfBlank }
        return existingText.contains { duplicatesMeaning(eventLabel, comparedWith: $0) } ? nil : eventLabel
    }

    static func visibleScoreLabel(for presentation: GameEventPresentation) -> String? {
        guard let scoreLabel = presentation.scoreLabel?.nilIfBlank else {
            return nil
        }
        let resultContext = presentation.situation.map(visibleResultContext)
        let existingText = [
            presentation.headline,
            resultContext?.pressureLine,
            resultContext?.contextLine
        ].compactMap { $0?.nilIfBlank }
        return existingText.contains { duplicatesMeaning(scoreLabel, comparedWith: $0) } ? nil : scoreLabel
    }

    static func visibleTeamLabel(for presentation: GameEventPresentation) -> String? {
        guard let teamLabel = presentation.teamLabel?.nilIfBlank,
              presentation.teamAbbreviation?.nilIfBlank == nil else {
            return nil
        }
        guard let situation = presentation.situation else {
            return teamLabel
        }
        let existingText = [
            situation.ownership?.teamAbbreviation,
            situation.ownership?.teamLabel,
            situation.accent.teamAbbreviation,
            situation.accent.teamLabel
        ].compactMap { $0?.nilIfBlank }
        return existingText.contains { duplicatesMeaning(teamLabel, comparedWith: $0) } ? nil : teamLabel
    }

    static func shouldShowContextTeamBadge(
        _ team: String,
        situation: GameEventSituationPresentation?
    ) -> Bool {
        guard let team = team.nilIfBlank,
              let situation else {
            return team.nilIfBlank != nil
        }
        let matchingSituationLabels = [
            situation.ownership?.teamAbbreviation,
            situation.ownership?.teamLabel,
            situation.accent.teamAbbreviation,
            situation.accent.teamLabel
        ].compactMap { $0?.nilIfBlank }
        return matchingSituationLabels.contains { duplicatesMeaning(team, comparedWith: $0) } == false
    }

    static func situationAccessibilityValue(for presentation: GameEventPresentation) -> String {
        guard let supplement = presentation.situationAccessibilityText?.nilIfBlank else {
            return ""
        }
        let existingText = [
            presentation.accessibilityLabel ?? presentation.headline
        ].compactMap { $0?.nilIfBlank }
            .joined(separator: " ")
        return duplicatesMeaning(supplement, comparedWith: existingText) ? "" : supplement
    }

    static func hasResultContext(for situation: GameEventSituationPresentation) -> Bool {
        let resultContext = visibleResultContext(for: situation)
        return resultContext.pressureLine != nil || resultContext.contextLine != nil
    }

    static func visibleResultContext(for situation: GameEventSituationPresentation) -> ResultContext {
        let pressureLine = resultContextText(situation.pressureLine)
        let contextLine = resultContextText(situation.contextLine)
        if let pressureLine, let contextLine {
            if duplicatesMeaning(pressureLine, comparedWith: contextLine) {
                return ResultContext(pressureLine: nil, contextLine: contextLine)
            }
            if duplicatesMeaning(contextLine, comparedWith: pressureLine) {
                return ResultContext(pressureLine: pressureLine, contextLine: nil)
            }
        }
        return ResultContext(pressureLine: pressureLine, contextLine: contextLine)
    }

    static func situationMetricSuppressionText(for presentation: GameEventPresentation) -> [String] {
        let resultContext = presentation.situation.map(visibleResultContext)
        return [
            presentation.headline,
            visibleEventLabel(for: presentation),
            presentation.clockText,
            presentation.teamAbbreviation,
            visibleTeamLabel(for: presentation),
            visibleScoreLabel(for: presentation),
            resultContext?.pressureLine,
            resultContext?.contextLine,
            presentation.situation?.periodText,
            presentation.situation?.setupText,
            presentation.situation?.pressureLine,
            presentation.situation?.contextLine,
            presentation.situation?.ownership?.teamAbbreviation,
            presentation.situation?.ownership?.teamLabel
        ].compactMap { $0?.nilIfBlank }
    }

    static func resultContextText(_ text: String?) -> String? {
        guard let text = text?.nilIfBlank,
              isResultSensitiveSituationText(text) else {
            return nil
        }
        return text
    }

    static func prePlaySituationText(_ text: String?) -> String? {
        guard let text = text?.nilIfBlank,
              !isResultSensitiveSituationText(text) else {
            return nil
        }
        return text
    }

    static func duplicatesMeaning(_ candidate: String, comparedWith existing: String) -> Bool {
        let normalizedCandidate = normalizedMeaning(candidate)
        let normalizedExisting = normalizedMeaning(existing)
        guard !normalizedCandidate.isEmpty, !normalizedExisting.isEmpty else {
            return false
        }
        if normalizedCandidate == normalizedExisting {
            return true
        }
        let candidateTokens = meaningfulTokens(in: candidate)
        let existingTokens = Set(meaningfulTokens(in: existing))
        if !candidateTokens.isEmpty {
            let covered = candidateTokens.filter { existingTokens.contains($0) }.count
            let coverage = Double(covered) / Double(candidateTokens.count)
            if coverage >= 0.82 {
                return true
            }
        }
        let minimumContainedLength = 24
        return normalizedCandidate.count >= minimumContainedLength && normalizedExisting.contains(normalizedCandidate)
            || normalizedExisting.count >= minimumContainedLength && normalizedCandidate.contains(normalizedExisting)
    }

    static func normalizedMeaning(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func isPlayerOnlyRepeat(_ detail: String, headline: String) -> Bool {
        let detailTokens = meaningfulTokens(in: detail)
        guard detailTokens.count >= 2,
              detailTokens.count <= 4 else {
            return false
        }
        let headlineTokens = Set(meaningfulTokens(in: headline))
        return detailTokens.allSatisfy { headlineTokens.contains($0) }
    }

    private static func isResultSensitiveSituationText(_ text: String) -> Bool {
        let normalized = normalizedMeaning(text)
        let metadataKey = normalizedSituationMetadataKey(text)
        if text.contains("->") {
            return true
        }
        if normalized.contains(" to up ")
            || normalized.contains(" to tied")
            || normalized.contains(" to down ")
            || containsEmbeddedDirectionalMovement(normalized) {
            return true
        }
        if normalized.hasPrefix("up ")
            || normalized.hasPrefix("down ") {
            return false
        }
        return metadataKey.contains("lead_change")
            || metadataKey.contains("tying_play")
            || metadataKey.contains("scoring_play")
            || metadataKey.contains("scoring_swing")
            || metadataKey.contains("power_play_finish")
            || metadataKey.contains("finish")
            || metadataKey.contains("go_ahead")
            || metadataKey.contains("cuts_deficit")
            || metadataKey.contains("extends_lead")
    }

    private static func containsEmbeddedDirectionalMovement(_ normalized: String) -> Bool {
        let tokens = normalized.split(separator: " ").map(String.init)
        guard tokens.count >= 3 else { return false }
        for index in 1..<(tokens.count - 1) where (tokens[index] == "up" || tokens[index] == "down") {
            if Int(tokens[index + 1]) != nil {
                return true
            }
        }
        return false
    }

    private static func meaningfulTokens(in text: String) -> [String] {
        normalizedMeaning(text)
            .split(separator: " ")
            .flatMap { canonicalTokens(for: String($0)) }
            .filter { token in
                token.count > 1 && stopWords.contains(token) == false
            }
    }

    private static func canonicalTokens(for token: String) -> [String] {
        if let compactInning = compactInningPeriodTokens(for: token) {
            return compactInning
        }
        switch token {
        case "1st", "first":
            return ["first"]
        case "2nd", "second":
            return ["second"]
        case "3rd", "third":
            return ["third"]
        case "4th", "fourth":
            return ["fourth"]
        case "singles":
            return ["single"]
        case "doubles":
            return ["double"]
        case "triples":
            return ["triple"]
        case "homer", "homers", "hr":
            return ["home", "run"]
        case "rbi", "scores", "scored", "scoring":
            return ["score"]
        case "td":
            return ["touchdown"]
        case "fg":
            return ["field", "goal"]
        default:
            return [token]
        }
    }

    private static func compactInningPeriodTokens(for token: String) -> [String]? {
        guard token.count >= 2,
              let side = token.first,
              side == "t" || side == "b",
              token.dropFirst().allSatisfy(\.isNumber) else {
            return nil
        }
        return [side == "t" ? "top" : "bottom", String(token.dropFirst())]
    }

    private static let stopWords: Set<String> = [
        "a", "an", "and", "as", "at", "by", "for", "from", "in", "into", "of", "on", "play", "the", "to", "with"
    ]
}
