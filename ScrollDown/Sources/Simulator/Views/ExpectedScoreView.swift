//
//  ExpectedScoreView.swift
//  ScrollDown
//
//  Animated count-up expected score display.
//

import SwiftUI

struct ExpectedScoreView: View {
    let homeScore: Double
    let awayScore: Double
    let homeTeam: String
    let awayTeam: String
    let totalRuns: Double
    let medianTotal: Double

    @State private var animatedHome: Double = 0
    @State private var animatedAway: Double = 0
    @State private var showTotal = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Expected Score")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 24) {
                scoreColumn(team: awayTeam, score: animatedAway, color: SimulatorTheme.awayColor)
                Text("-")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.secondary)
                scoreColumn(team: homeTeam, score: animatedHome, color: SimulatorTheme.homeColor)
            }

            if showTotal {
                HStack(spacing: 16) {
                    Label(String(format: "Avg Total: %.1f", totalRuns), systemImage: "sum")
                    Label(String(format: "Median: %.1f", medianTotal), systemImage: "chart.bar.xaxis")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedHome = homeScore
                animatedAway = awayScore
            }
            withAnimation(.easeIn.delay(0.6)) {
                showTotal = true
            }
        }
    }

    private func scoreColumn(team: String, score: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(team)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", score))
                .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText(value: score))
        }
    }
}
