//
//  WinProbabilityBarView.swift
//  ScrollDown
//
//  Animated gradient-filled probability bars with glow on winner.
//

import SwiftUI

struct WinProbabilityBarView: View {
    let homeProb: Double
    let awayProb: Double
    let homeTeam: String
    let awayTeam: String

    @State private var animatedHome: Double = 0
    @State private var animatedAway: Double = 0

    private var homeWins: Bool { homeProb > awayProb }

    var body: some View {
        VStack(spacing: 12) {
            Text("Win Probability")
                .font(.subheadline.weight(.semibold))

            // Away bar
            probBar(
                label: awayTeam,
                value: animatedAway,
                gradient: SimulatorTheme.awayGradient,
                isWinner: !homeWins,
                color: SimulatorTheme.awayColor
            )

            // Home bar
            probBar(
                label: homeTeam,
                value: animatedHome,
                gradient: SimulatorTheme.homeGradient,
                isWinner: homeWins,
                color: SimulatorTheme.homeColor
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedHome = homeProb
                animatedAway = awayProb
            }
        }
    }

    private func probBar(
        label: String,
        value: Double,
        gradient: LinearGradient,
        isWinner: Bool,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(String(format: "%.1f%%", value * 100))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(gradient)
                        .frame(width: geo.size.width * max(0, min(1, value)))
                        .shadow(color: isWinner ? color.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
                }
            }
            .frame(height: 24)
        }
    }
}
