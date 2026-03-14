import Foundation

/// Type-safe accessor for the `derivedMetrics` dictionary.
/// Provides display-ready labels for odds lines and outcomes.
struct DerivedMetrics {
    private let dict: [String: Any]

    init(_ dict: [String: AnyCodable]) {
        self.dict = dict.mapValues { $0.value }
    }

    // MARK: - Closing (Pregame) Odds Labels

    var pregameSpreadLabel: String? { string("pregame_spread_label") }
    var pregameTotalLabel: String? { string("pregame_total_label") }
    var pregameMLHomeLabel: String? { string("pregame_ml_home_label") }
    var pregameMLAwayLabel: String? { string("pregame_ml_away_label") }

    // MARK: - Opening Odds Labels

    var openingSpreadLabel: String? { string("opening_spread_label") }
    var openingTotalLabel: String? { string("opening_total_label") }
    var openingMLHomeLabel: String? { string("opening_ml_home_label") }
    var openingMLAwayLabel: String? { string("opening_ml_away_label") }

    // MARK: - Closing Outcome Labels

    var spreadOutcomeLabel: String? { string("spread_outcome_label") }
    var totalOutcomeLabel: String? { string("total_outcome_label") }
    var mlOutcomeLabel: String? { string("ml_outcome_label") }

    // MARK: - Opening Outcome Labels

    var openingSpreadOutcomeLabel: String? { string("opening_spread_outcome_label") }
    var openingTotalOutcomeLabel: String? { string("opening_total_outcome_label") }
    var openingMlOutcomeLabel: String? { string("opening_ml_outcome_label") }

    // MARK: - Helpers

    private func string(_ key: String) -> String? {
        dict[key] as? String
    }
}
