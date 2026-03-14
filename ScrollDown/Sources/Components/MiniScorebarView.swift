//
//  MiniScorebarView.swift
//  ScrollDown
//
//  Sticky score bar that appears at the top of GameDetailView on scroll.
//

import SwiftUI

struct MiniScorebarView: View {
    let awayTeam: String
    let homeTeam: String
    let awayScore: Int?
    let homeScore: Int?
    let status: String
    let isLive: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isLive {
                PulsingDotView(color: .red, size: 6)
            }

            Text(awayTeam)
                .font(.caption.weight(.semibold))
            Text("\(awayScore ?? 0)")
                .font(.subheadline.weight(.bold).monospacedDigit())

            Text("-")
                .foregroundStyle(.secondary)

            Text("\(homeScore ?? 0)")
                .font(.subheadline.weight(.bold).monospacedDigit())
            Text(homeTeam)
                .font(.caption.weight(.semibold))

            Spacer()

            Text(status)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
