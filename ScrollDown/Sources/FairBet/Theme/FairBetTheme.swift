//
//  FairBetTheme.swift
//  ScrollDown
//
//  Namespaced color system for FairBet views.
//  Extracted from FairBet's Color extensions to avoid global namespace pollution.
//

import SwiftUI
import UIKit

enum FairBetTheme {

    // MARK: - Semantic Colors

    /// Success / positive value - bright green (for high EV 5%+)
    static let positive = Color(red: 0.18, green: 0.72, blue: 0.45)

    /// Muted positive - for lower EV (0-5%)
    static let positiveMuted = Color(red: 0.35, green: 0.65, blue: 0.50)

    /// Soft success background for badges/chips
    static let successSoft = Color(red: 0.18, green: 0.72, blue: 0.45).opacity(0.12)

    /// Muted success background
    static let successSoftMuted = Color(red: 0.35, green: 0.65, blue: 0.50).opacity(0.10)

    /// Error / negative / warning - softer coral
    static let negative = Color(red: 0.82, green: 0.42, blue: 0.40)

    /// Neutral / even / fair value
    static let neutral = Color(red: 0.55, green: 0.57, blue: 0.62)

    /// Informational accent - soft blue
    static let info = Color(red: 0.35, green: 0.55, blue: 0.95)

    /// Soft info background
    static let infoSoft = Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.10)

    // MARK: - Surface Colors

    /// Primary card background
    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.16, blue: 0.20, alpha: 1)
            : UIColor.white
    })

    /// Secondary surface - slightly tinted for hierarchy
    static let surfaceTint = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.12, blue: 0.16, alpha: 1)
            : UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1)
    })

    /// Tertiary surface - for nested elements
    static let surfaceSecondary = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1)
            : UIColor(red: 0.94, green: 0.95, blue: 0.98, alpha: 1)
    })

    // MARK: - Border & Divider Colors

    /// Subtle border for cards
    static let cardBorder = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.06)
    })

    /// Slightly more visible border
    static let borderSubtle = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.black.withAlphaComponent(0.10)
    })
}
