//
//  FairOddsCalculator.swift
//  ScrollDown
//

import Foundation

/// Confidence level for fair odds computation
enum FairOddsConfidence: String, Codable {
    case high       // 2+ sharp books pricing both sides
    case medium     // 1 sharp book pricing both sides
    case low        // No sharp books available
    case none       // Cannot compute fair odds
}
