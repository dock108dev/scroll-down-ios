import Foundation

enum ScoreSpoilerPolicy: Hashable, Sendable {
    case revealed
    case hideAbsoluteScores
    case hideAllScorePressure
}

enum ScoreSpoilerFilter {
    static func topRegionText(_ value: String?, for game: Game) -> String? {
        guard let trimmed = value?.nilIfBlank else {
            return nil
        }
        return containsAbsoluteScoreBearingText(trimmed, for: game) ? nil : trimmed
    }

    static func matchupText(for game: Game) -> String {
        topRegionText(game.presentation?.matchupLabel, for: game) ?? fallbackMatchupText(for: game)
    }

    static func containsScoreBearingText(_ text: String, for game: Game) -> Bool {
        containsAbsoluteScoreBearingText(text, for: game)
    }

    static func containsAbsoluteScoreBearingText(_ text: String, for game: Game) -> Bool {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return false }

        for token in scoreTokens(for: game) where normalized.contains(token) {
            return true
        }
        if containsCompactScoreline(normalized)
            || containsTeamNumberPair(normalized, for: game)
            || containsStandaloneScoreContext(normalized) {
            return true
        }

        guard game.status.isFinal else {
            return false
        }
        let winnerTerms = [" won", " win", " wins", " beat", " beats", " defeat", " defeated", " winner", " lost"]
        return winnerTerms.contains { normalized.contains($0) }
    }

    static func containsRelativeScorePressureText(_ text: String) -> Bool {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return false }

        let patterns = [
            #"\bup\s+(?:by\s+)?[0-9]+\b"#,
            #"\bdown\s+(?:by\s+)?[0-9]+\b"#,
            #"\btied\b"#,
            #"\blead\s+change\b"#,
            #"\bgo[- ]ahead\b"#,
            #"\bties?\s+(?:it|the\s+game|game)\b"#,
            #"\bcuts?\s+the\s+deficit\b"#,
            #"\bextends?\s+the\s+lead\b"#,
            #"\bgame[- ]winning\b"#,
            #"\bwalk[- ]off\b"#
        ]
        return patterns.contains { containsPattern($0, in: normalized) }
    }

    static func containsAnyScorePressureText(_ text: String, for game: Game) -> Bool {
        containsAbsoluteScoreBearingText(text, for: game) || containsRelativeScorePressureText(text)
    }

    private static func fallbackMatchupText(for game: Game) -> String {
        "\(game.awayParticipant?.name ?? "Away") at \(game.homeParticipant?.name ?? "Home")"
    }

    private static func scoreTokens(for game: Game) -> [String] {
        var tokens = Set<String>()

        if let away = game.scoreState.away, let home = game.scoreState.home {
            tokens.insert("\(away)-\(home)")
            tokens.insert("\(home)-\(away)")
        }

        if let scoreline = game.scoreboard?.scoreline {
            tokens.insert(normalize(scoreline))
        }

        for participant in game.participants {
            guard let score = scoreText(for: participant.role, game: game) else { continue }
            for label in labels(for: participant) {
                tokens.insert(normalize("\(label) \(score)"))
                tokens.insert(normalize("\(score) \(label)"))
            }
        }

        return tokens
            .filter { !$0.isEmpty }
            .sorted { left, right in
                if left.count != right.count {
                    return left.count > right.count
                }
                return left < right
            }
    }

    private static func scoreText(for role: GameParticipantRole, game: Game) -> String? {
        if let score = game.scoreState.score(for: role) {
            return String(score)
        }
        return game.scoreboard?.competitors.first { $0.side == role }?.scoreText
    }

    private static func labels(for participant: GameParticipant) -> [String] {
        var labels = [participant.name]
        if let abbreviation = participant.abbreviation {
            labels.append(abbreviation)
        }
        if let lastName = participant.name.split(separator: " ").last {
            labels.append(String(lastName))
        }
        return labels
    }

    private static func containsCompactScoreline(_ text: String) -> Bool {
        containsPattern(#"\b[0-9]+\s*-\s*[0-9]+\b"#, in: text)
    }

    private static func containsTeamNumberPair(_ text: String, for game: Game) -> Bool {
        for participant in game.participants {
            for label in labels(for: participant) {
                let escapedLabel = NSRegularExpression.escapedPattern(for: normalize(label))
                if containsPattern(#"\b"# + escapedLabel + #"\s+[0-9]+\b"#, in: text)
                    || containsPattern(#"\b[0-9]+\s+"# + escapedLabel + #"\b"#, in: text) {
                    return true
                }
            }
        }
        return false
    }

    private static func containsStandaloneScoreContext(_ text: String) -> Bool {
        let patterns = [
            #"\b(?:final\s+score|score|scoreboard)\s*:?\s*[0-9]+\b"#,
            #"\b(?:makes?|made)\s+it\s+[0-9]+\b"#,
            #"\b(?:ties?|tied)\s+(?:it|the\s+game|game)\s+at\s+[0-9]+\b"#,
            #"\b(?:leads?|led|trails?|trailed)\s+[0-9]+\s*-\s*[0-9]+\b"#
        ]
        return patterns.contains { containsPattern($0, in: text) }
    }

    private static func containsPattern(_ pattern: String, in text: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " - ", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum EventScoreSpoilerFilter {
    static func filtered(
        presentation: GameEventPresentation,
        game: Game,
        policy: ScoreSpoilerPolicy
    ) -> GameEventPresentation {
        switch policy {
        case .revealed:
            return presentation
        case .hideAbsoluteScores:
            return filter(presentation, game: game, hidesRelativePressure: false)
        case .hideAllScorePressure:
            return filter(presentation, game: game, hidesRelativePressure: true)
        }
    }

    private static func filter(
        _ presentation: GameEventPresentation,
        game: Game,
        hidesRelativePressure: Bool
    ) -> GameEventPresentation {
        let filteredSituation = presentation.situation.map {
            filterSituation($0, game: game, hidesRelativePressure: hidesRelativePressure)
        }
        let scoreTextPredicate: (String) -> Bool = { text in
            if hidesRelativePressure {
                return ScoreSpoilerFilter.containsAnyScorePressureText(text, for: game)
            }
            return ScoreSpoilerFilter.containsAbsoluteScoreBearingText(text, for: game)
        }
        let filteredAccessibilityText: String?
        if hidesRelativePressure {
            filteredAccessibilityText = nil
        } else if let accessibilityText = presentation.situationAccessibilityText?.nilIfBlank {
            filteredAccessibilityText = ScoreSpoilerFilter.containsAbsoluteScoreBearingText(accessibilityText, for: game)
                ? nil
                : accessibilityText
        } else {
            filteredAccessibilityText = filteredSituation?.accessibilitySummary
        }

        return GameEventPresentation(
            clockText: presentation.clockText,
            headline: filteredHeadline(presentation.headline, fallback: presentation, shouldHide: scoreTextPredicate),
            detail: filteredSupplement(presentation.detail, shouldHide: scoreTextPredicate),
            eventLabel: presentation.eventLabel,
            teamAbbreviation: presentation.teamAbbreviation,
            teamLabel: presentation.teamLabel,
            scoringLabel: filteredSupplement(presentation.scoringLabel, shouldHide: scoreTextPredicate),
            scoreLabel: nil,
            rawFeedText: filteredSupplement(presentation.rawFeedText, shouldHide: scoreTextPredicate),
            rawFeedSource: filteredSupplement(presentation.rawFeedSource, shouldHide: scoreTextPredicate),
            accessibilityLabel: filteredSupplement(presentation.accessibilityLabel, shouldHide: scoreTextPredicate),
            situation: filteredSituation,
            situationAccessibilityText: filteredAccessibilityText
        )
    }

    private static func filteredHeadline(
        _ headline: String,
        fallback presentation: GameEventPresentation,
        shouldHide: (String) -> Bool
    ) -> String {
        guard shouldHide(headline) else { return headline }
        return [
            filteredSupplement(presentation.scoringLabel, shouldHide: shouldHide),
            filteredSupplement(presentation.eventLabel, shouldHide: shouldHide),
            presentation.teamLabel?.nilIfBlank.map { "\($0) play" },
            "Play update"
        ].compactMap(\.self).first ?? "Play update"
    }

    private static func filteredSupplement(_ text: String?, shouldHide: (String) -> Bool) -> String? {
        guard let text = text?.nilIfBlank else { return nil }
        return shouldHide(text) ? nil : text
    }

    private static func filterSituation(
        _ situation: GameEventSituationPresentation,
        game: Game,
        hidesRelativePressure: Bool
    ) -> GameEventSituationPresentation {
        let contextLine = filteredSituationText(situation.contextLine, game: game, hidesRelativePressure: hidesRelativePressure)
        let pressureLine = hidesRelativePressure
            ? nil
            : filteredSituationText(situation.pressureLine, game: game, hidesRelativePressure: false)
        let diagram = filterDiagram(situation.diagram, game: game, hidesRelativePressure: hidesRelativePressure)

        return GameEventSituationPresentation(
            title: situation.title,
            periodText: situation.periodText,
            setupText: situation.setupText,
            contextLine: contextLine,
            pressureLine: pressureLine,
            sport: situation.sport,
            layout: situation.layout,
            ownership: situation.ownership,
            diagram: diagram,
            accent: situation.accent,
            dataConfidence: situation.dataConfidence
        )
    }

    private static func filteredSituationText(
        _ text: String?,
        game: Game,
        hidesRelativePressure: Bool
    ) -> String? {
        guard let text = text?.nilIfBlank else { return nil }
        if ScoreSpoilerFilter.containsAbsoluteScoreBearingText(text, for: game) {
            return nil
        }
        if hidesRelativePressure && ScoreSpoilerFilter.containsRelativeScorePressureText(text) {
            return nil
        }
        return text
    }

    private static func filterDiagram(
        _ diagram: GameEventSituationDiagram?,
        game: Game,
        hidesRelativePressure: Bool
    ) -> GameEventSituationDiagram? {
        guard let diagram else { return nil }
        switch diagram {
        case .baseballDiamond, .footballFieldStrip, .hockeyRinkStrip, .soccerPitchStrip:
            return diagram
        case .basketballHalfCourt(let basketball):
            return .basketballHalfCourt(
                BasketballHalfCourtDiagram(
                    possessionText: basketball.possessionText,
                    clockText: basketball.clockText,
                    shotClockText: basketball.shotClockText,
                    scoreText: filteredSituationText(
                        basketball.scoreText,
                        game: game,
                        hidesRelativePressure: hidesRelativePressure
                    ),
                    bonusText: basketball.bonusText,
                    shotText: basketball.shotText,
                    locationText: basketball.locationText,
                    freeThrowText: basketball.freeThrowText,
                    shotLocation: basketball.shotLocation,
                    pressure: hidesRelativePressure ? nil : basketball.pressure
                )
            )
        case .pressureBoardFallback(let board):
            let metrics = board.metrics.filter { metric in
                if ScoreSpoilerFilter.containsAbsoluteScoreBearingText(metric.label, for: game) {
                    return false
                }
                if ScoreSpoilerFilter.containsAbsoluteScoreBearingText(metric.value, for: game) {
                    return false
                }
                if hidesRelativePressure && (
                    metric.emphasis == .pressure
                        || ScoreSpoilerFilter.containsRelativeScorePressureText(metric.label)
                        || ScoreSpoilerFilter.containsRelativeScorePressureText(metric.value)
                ) {
                    return false
                }
                return true
            }
            return .pressureBoardFallback(
                PressureBoardSituationDiagram(
                    associations: board.associations,
                    metrics: metrics
                )
            )
        }
    }
}
