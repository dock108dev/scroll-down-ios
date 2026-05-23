import Foundation

enum ScoreSpoilerFilter {
    static func topRegionText(_ value: String?, for game: Game) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return containsScoreBearingText(trimmed, for: game) ? nil : trimmed
    }

    static func matchupText(for game: Game) -> String {
        topRegionText(game.presentation?.matchupLabel, for: game) ?? fallbackMatchupText(for: game)
    }

    static func containsScoreBearingText(_ text: String, for game: Game) -> Bool {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return false }

        for token in scoreTokens(for: game) where normalized.contains(token) {
            return true
        }
        if containsCompactScoreline(normalized) || containsTeamNumberPair(normalized, for: game) {
            return true
        }

        guard game.status.isFinal else {
            return false
        }
        let winnerTerms = [" won", " win", " wins", " beat", " beats", " defeat", " defeated", " winner", " lost"]
        return winnerTerms.contains { normalized.contains($0) }
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
