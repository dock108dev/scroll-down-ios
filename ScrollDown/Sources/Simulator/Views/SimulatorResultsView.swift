//
//  SimulatorResultsView.swift
//  ScrollDown
//
//  Container for all simulation result visualizations.
//

import SwiftUI

struct SimulatorResultsView: View {
    let result: SimulatorResult

    var body: some View {
        VStack(spacing: 20) {
            // Game Playback Visualization (the showpiece!)
            GameSimPlaybackView(result: result)

            // Win Probability
            WinProbabilityBarView(
                homeProb: result.homeWinProbability,
                awayProb: result.awayWinProbability,
                homeTeam: result.homeTeam,
                awayTeam: result.awayTeam
            )

            // Expected Scores
            ExpectedScoreView(
                homeScore: result.averageHomeScore,
                awayScore: result.averageAwayScore,
                homeTeam: result.homeTeam,
                awayTeam: result.awayTeam,
                totalRuns: result.averageTotal,
                medianTotal: result.medianTotal
            )

            // Most Common Scores
            if !result.mostCommonScores.isEmpty {
                ScoreCardView(
                    scores: Array(result.mostCommonScores.prefix(5)),
                    awayTeam: result.awayTeam,
                    homeTeam: result.homeTeam
                )
            }

            // PA Breakdown
            if let homePA = result.homePaProbabilities, !homePA.isEmpty {
                PABreakdownView(
                    probabilities: homePA,
                    teamName: result.homeTeam,
                    color: SimulatorTheme.homeColor
                )
            }
            if let awayPA = result.awayPaProbabilities, !awayPA.isEmpty {
                PABreakdownView(
                    probabilities: awayPA,
                    teamName: result.awayTeam,
                    color: SimulatorTheme.awayColor
                )
            }

            // Pitcher Profiles
            if let meta = result.profileMeta {
                if let homePitcher = meta.homePitcher, let profile = homePitcher.adjustedProfile ?? homePitcher.rawProfile {
                    PitcherProfileView(
                        pitcher: homePitcher,
                        profile: profile,
                        teamName: result.homeTeam,
                        color: SimulatorTheme.homeColor
                    )
                }
                if let awayPitcher = meta.awayPitcher, let profile = awayPitcher.adjustedProfile ?? awayPitcher.rawProfile {
                    PitcherProfileView(
                        pitcher: awayPitcher,
                        profile: profile,
                        teamName: result.awayTeam,
                        color: SimulatorTheme.awayColor
                    )
                }
            }

            // Metadata
            HStack(spacing: 16) {
                Label("\(result.iterations.formatted()) iterations", systemImage: "number")
                if let source = result.probabilitySource {
                    Label(source, systemImage: "chart.bar")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}
