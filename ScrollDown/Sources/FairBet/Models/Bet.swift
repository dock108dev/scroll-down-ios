//
//  Bet.swift
//  ScrollDown
//
//  Core data models for odds display
//

import Foundation

/// Represents American odds (e.g., +150, -110)
/// Valid odds are: <= -100 OR >= +100. Values in the invalid zone are auto-corrected.
struct AmericanOdds: Equatable, Hashable, Codable {
    let value: Int

    /// Convert American odds to implied probability
    var impliedProbability: Double {
        if value < 0 { return Double(-value) / (Double(-value) + 100.0) }
        return 100.0 / (Double(value) + 100.0)
    }

    /// Display string with + or - prefix
    var displayString: String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    /// Initialize with auto-correction for invalid values.
    /// Invalid values (-99 to +99 except 0->100) are snapped to the nearest valid boundary.
    init(_ value: Int) {
        self.value = Self.correctedValue(value)
    }

    /// Correct invalid American odds to valid values
    private static func correctedValue(_ value: Int) -> Int {
        // If already valid, return as-is
        if value == 100 || value <= -100 || value >= 100 {
            return value
        }

        // Invalid zone: -99 to +99
        // Snap to nearest boundary
        if value >= 0 {
            return 100  // 0 to 99 -> +100
        } else {
            return -100 // -99 to -1 -> -100
        }
    }
}

/// Odds display format
enum OddsFormat: String, CaseIterable, Identifiable {
    case american = "American"
    case decimal = "Decimal"

    var id: String { rawValue }
}
