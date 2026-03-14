//
//  SimScoreboardView.swift
//  ScrollDown
//
//  Scoreboard display for the simulation playback.
//

import SwiftUI

struct SimScoreboardView: View {
    let awayTeam: String
    let homeTeam: String
    let awayScore: Int
    let homeScore: Int
    let inning: Int
    let isTopHalf: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Inning indicator
            VStack(spacing: 2) {
                Image(systemName: isTopHalf ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(inning)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
            }
            .frame(width: 36)

            Spacer()

            // Away
            HStack(spacing: 8) {
                Text(awayTeam)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 50, alignment: .trailing)
                Text("\(awayScore)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(SimulatorTheme.awayColor)
                    .frame(width: 30)
                    .contentTransition(.numericText(value: Double(awayScore)))
            }

            Text("-")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            // Home
            HStack(spacing: 8) {
                Text("\(homeScore)")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(SimulatorTheme.homeColor)
                    .frame(width: 30)
                    .contentTransition(.numericText(value: Double(homeScore)))
                Text(homeTeam)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 50, alignment: .leading)
            }

            Spacer()

            // Spacer to balance inning indicator
            Color.clear.frame(width: 36)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}
