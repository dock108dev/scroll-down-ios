//
//  SimulatorTheme.swift
//  ScrollDown
//
//  Colors, gradients, and chart palette for the MLB simulator.
//

import SwiftUI

enum SimulatorTheme {
    // MARK: - Primary Colors

    static let homeColor = Color(red: 0.22, green: 0.55, blue: 0.95)
    static let awayColor = Color(red: 0.90, green: 0.35, blue: 0.40)

    // MARK: - Chart Palette (PA Breakdown)

    static let hrColor = Color(red: 0.95, green: 0.30, blue: 0.30)
    static let tripleColor = Color(red: 0.95, green: 0.60, blue: 0.20)
    static let doubleColor = Color(red: 0.95, green: 0.85, blue: 0.25)
    static let singleColor = Color(red: 0.30, green: 0.80, blue: 0.45)
    static let walkColor = Color(red: 0.35, green: 0.55, blue: 0.95)
    static let strikeoutColor = Color(red: 0.55, green: 0.57, blue: 0.62)
    static let otherOutColor = Color(red: 0.40, green: 0.42, blue: 0.47)

    // MARK: - Gradients

    static let homeGradient = LinearGradient(
        colors: [homeColor, homeColor.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let awayGradient = LinearGradient(
        colors: [awayColor, awayColor.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let winnerGlow = Color.white.opacity(0.6)

    // MARK: - Surfaces

    static let cardBackground = Color(.systemBackground)
    static let cardBorder = Color(.separator).opacity(0.3)

    // MARK: - Spider Chart Axes

    static let radarStroke = Color(.systemGray3)
    static let radarFill = Color(red: 0.35, green: 0.55, blue: 0.95).opacity(0.25)

    // MARK: - Score Card

    static func scoreCardGradient(index: Int) -> LinearGradient {
        let hue = 0.55 + Double(index) * 0.08
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.6, brightness: 0.9),
                Color(hue: hue, saturation: 0.4, brightness: 0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
