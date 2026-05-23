import Foundation

enum GameParticipantVisibility {
    static func hasConcreteParticipants(_ game: Game) -> Bool {
        isConcreteParticipant(game.awayParticipant) && isConcreteParticipant(game.homeParticipant)
    }

    static func isConcreteParticipant(_ participant: GameParticipant?) -> Bool {
        guard let participant else { return false }

        let labels = [
            normalizedParticipantText(participant.name),
            normalizedParticipantText(participant.abbreviation)
        ].compactMap { $0 }

        guard !labels.isEmpty else { return false }
        return !labels.contains(where: isPlaceholderParticipantText)
    }

    static func isPlaceholderParticipantText(_ value: String?) -> Bool {
        guard let normalized = normalizedParticipantText(value) else { return false }
        if exactPlaceholderLabels.contains(normalized) {
            return true
        }
        return placeholderPatterns.contains { pattern in
            normalized.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static let exactPlaceholderLabels: Set<String> = [
        "tbd",
        "t b d",
        "tba",
        "t b a",
        "to be determined",
        "to be announced",
        "unknown",
        "unknown team",
        "unknown opponent",
        "not available",
        "n a",
        "na",
        "none",
        "null",
        "opponent tbd",
        "team tbd",
        "tbd team",
        "tbd opponent",
        "home team tbd",
        "away team tbd",
        "bye"
    ]

    private static let placeholderPatterns = [
        #"^winner( of)? .+"#,
        #"^loser( of)? .+"#,
        #"^play ?in winner$"#,
        #"^wild card winner$"#,
        #"^#?\d+ seed$"#,
        #"^no ?\d+ seed$"#,
        #"^(east|west|north|south|central|atlantic|pacific|metropolitan) \d+ seed$"#,
        #"^(higher|lower) seed$"#,
        #"^team [0-9]+$"#,
        #"^team [a-z]$"#,
        #"^(home|away) team$"#,
        #"^club [a-z]$"#
    ]

    private static func normalizedParticipantText(_ value: String?) -> String? {
        guard let value else { return nil }
        let separatorCharacters = CharacterSet(charactersIn: "._/\\-")
        let separated = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: separatorCharacters)
            .joined(separator: " ")
        let collapsed = separated
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return collapsed.isEmpty ? nil : collapsed
    }
}
