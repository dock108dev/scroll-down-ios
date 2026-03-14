//
//  ScoreCardView.swift
//  ScrollDown
//
//  Top 5 most likely final scores with staggered entry animations.
//

import SwiftUI

struct ScoreCardView: View {
    let scores: [MostCommonScore]
    let awayTeam: String
    let homeTeam: String

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Most Likely Scores")
                .font(.subheadline.weight(.semibold))

            ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
                HStack {
                    if let parsed = score.parsed {
                        Text("\(awayTeam) \(parsed.away)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SimulatorTheme.awayColor)
                        Text("-")
                            .foregroundStyle(.secondary)
                        Text("\(parsed.home) \(homeTeam)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(SimulatorTheme.homeColor)
                    } else {
                        Text(score.score)
                            .font(.subheadline.weight(.medium))
                    }
                    Spacer()
                    Text(String(format: "%.1f%%", score.probability * 100))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08),
                    value: appeared
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { appeared = true }
    }
}
