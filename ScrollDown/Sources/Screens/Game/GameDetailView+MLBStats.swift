//
//  GameDetailView+MLBStats.swift
//  ScrollDown
//
//  MLB advanced stats section: Statcast metrics table.
//  Gated on leagueCode == "MLB" and presence of advanced stats data.
//

import SwiftUI

extension GameDetailView {
    @ViewBuilder
    func mlbAdvancedStatsSection(detail: GameDetailResponse) -> some View {
        if detail.game.leagueCode == "MLB",
           let advancedStats = detail.mlbAdvancedStats, !advancedStats.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Advanced Stats")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(advancedStats, id: \.team) { stats in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(stats.team + (stats.isHome ? " (Home)" : " (Away)"))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            statCell("Pitches", value: "\(stats.totalPitches)")
                            statCell("BIP", value: "\(stats.ballsInPlay)")
                            statCell("Exit Velo", value: formatOptional(stats.avgExitVelo, format: "%.1f"))
                            statCell("Hard Hit%", value: formatOptional(stats.hardHitPct, format: "%.1f%%"))
                            statCell("Barrel%", value: formatOptional(stats.barrelPct, format: "%.1f%%"))
                            statCell("Z-Swing%", value: formatOptional(stats.zSwingPct, format: "%.1f%%"))
                            statCell("O-Swing%", value: formatOptional(stats.oSwingPct, format: "%.1f%%"))
                            statCell("Z-Contact%", value: formatOptional(stats.zContactPct, format: "%.1f%%"))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func statCell(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatOptional(_ value: Double?, format: String) -> String {
        guard let v = value else { return "—" }
        return String(format: format, v)
    }
}
