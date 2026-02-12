import Foundation

// MARK: - Bet Group Key Builder

/// Utility for constructing canonical bet_group_key and selection_key
struct BetGroupKeyBuilder {

    /// Construct a canonical bet_group_key
    /// Format: {game_id}|{market_key}|{subject_id}|{line}
    static func buildBetGroupKey(
        gameId: String,
        marketKey: String,
        subjectId: String?,
        line: Double?
    ) -> String {
        let subjectPart = subjectId ?? ""
        let linePart = line.map { formatLine($0) } ?? ""
        return "\(gameId)|\(marketKey)|\(subjectPart)|\(linePart)"
    }

    /// Construct a canonical selection_key
    /// Format: {bet_group_key}:{side}
    static func buildSelectionKey(
        betGroupKey: String,
        side: SelectionSide
    ) -> String {
        "\(betGroupKey):\(side.rawValue)"
    }

    /// Build a canonical game_id
    /// Format: {league}:{date}:{away_team}-{home_team}
    static func buildGameId(
        league: String,
        date: Date,
        awayTeam: String,
        homeTeam: String
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let normalizedAway = normalizeTeamCode(awayTeam)
        let normalizedHome = normalizeTeamCode(homeTeam)

        return "\(league.lowercased()):\(dateString):\(normalizedAway)-\(normalizedHome)"
    }

    /// Normalize team code (uppercase, trimmed)
    static func normalizeTeamCode(_ team: String) -> String {
        team.uppercased().trimmingCharacters(in: .whitespaces)
    }

    /// Normalize player ID for subject_id
    static func normalizePlayerId(_ name: String, disambiguationId: String? = nil) -> String {
        var normalized = name.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")

        if let id = disambiguationId {
            normalized += "-\(id)"
        }

        return normalized
    }

    /// Format line value (one decimal place, absolute for spreads)
    static func formatLine(_ line: Double) -> String {
        String(format: "%.1f", line)
    }
}
