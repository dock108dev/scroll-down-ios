import Foundation

/// Type-safe accessor for the `derivedMetrics` dictionary.
/// Provides display-ready labels for odds lines and outcomes.
struct DerivedMetrics {
    private let dict: [String: Any]

    init(_ dict: [String: AnyCodable]) {
        self.dict = dict.mapValues { $0.value }
    }

    init(raw: [String: Any]) {
        self.dict = raw
    }

    // MARK: - Pregame Odds Labels

    var pregameSpreadLabel: String? { string("pregame_spread_label") }
    var pregameTotalLabel: String? { string("pregame_total_label") }
    var pregameMLHomeLabel: String? { string("pregame_ml_home_label") }
    var pregameMLAwayLabel: String? { string("pregame_ml_away_label") }

    // MARK: - Outcome Labels

    var spreadOutcomeLabel: String? { string("spread_outcome_label") }
    var totalOutcomeLabel: String? { string("total_outcome_label") }
    var mlOutcomeLabel: String? { string("ml_outcome_label") }

    // MARK: - Outcome Booleans

    var didHomeCover: Bool? { bool("did_home_cover") }
    var totalResult: String? { string("total_result") }
    var moneylineUpset: Bool? { bool("moneyline_upset") }

    // MARK: - Spread Details

    var spreadLine: Double? { double("spread_line") }
    var spreadFavoredTeam: String? { string("spread_favored_team") }
    var spreadCovered: Bool? { bool("spread_covered") }
    var spreadPush: Bool? { bool("spread_push") }

    // MARK: - Total Details

    var totalLine: Double? { double("total_line") }
    var actualTotal: Int? { int("actual_total") }
    var totalWentOver: Bool? { bool("total_went_over") }
    var totalPush: Bool? { bool("total_push") }

    // MARK: - Moneyline Details

    var mlFavoredTeam: String? { string("ml_favored_team") }
    var mlFavoredPrice: Int? { int("ml_favored_price") }
    var mlUnderdogTeam: String? { string("ml_underdog_team") }
    var mlUnderdogPrice: Int? { int("ml_underdog_price") }
    var mlFavoriteWon: Bool? { bool("ml_favorite_won") }

    // MARK: - Book Info

    var bookName: String? { string("book_name") }

    // MARK: - Helpers

    private func string(_ key: String) -> String? {
        dict[key] as? String
    }

    private func bool(_ key: String) -> Bool? {
        dict[key] as? Bool
    }

    private func double(_ key: String) -> Double? {
        if let d = dict[key] as? Double { return d }
        if let n = dict[key] as? NSNumber { return n.doubleValue }
        return nil
    }

    private func int(_ key: String) -> Int? {
        if let i = dict[key] as? Int { return i }
        if let n = dict[key] as? NSNumber { return n.intValue }
        return nil
    }
}
