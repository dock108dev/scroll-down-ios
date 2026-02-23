//
//  FairOddsCalculator.swift
//  ScrollDown
//

import Foundation

/// How much we trust the devigged line as a reflection of true probability.
/// Books know how to set odds, but external factors (liquidity, competition,
/// handle depth) affect how closely a posted line tracks the real number.
enum FairOddsConfidence: String, Codable {
    case high       // SHARP — high-action, efficient market, tight consensus
    case medium     // MARKET — decent market, enough books for price discovery
    case low        // THIN — few books or wide disagreement, less reliable
    case none       // Cannot compute fair odds
}
