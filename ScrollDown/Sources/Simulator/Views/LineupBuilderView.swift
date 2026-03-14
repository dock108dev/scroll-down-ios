//
//  LineupBuilderView.swift
//  ScrollDown
//
//  9-slot batting order + starter pitcher selection for both teams.
//

import SwiftUI

struct LineupBuilderView: View {
    @ObservedObject var viewModel: MLBSimulatorViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                    Text("Custom Lineups")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if viewModel.hasLineupCustomization {
                        Text("Modified")
                            .font(.caption2)
                            .foregroundStyle(SimulatorTheme.homeColor)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            if isExpanded {
                VStack(spacing: 16) {
                    if viewModel.isLoadingRoster {
                        ProgressView("Loading rosters…")
                            .padding()
                    } else {
                        // Away lineup
                        if let away = viewModel.awayTeam {
                            lineupSection(
                                team: away,
                                color: SimulatorTheme.awayColor,
                                batters: viewModel.awayBatters,
                                pitchers: viewModel.awayPitchers,
                                lineup: $viewModel.awayLineup,
                                starter: $viewModel.awayStarter
                            )
                        }

                        // Home lineup
                        if let home = viewModel.homeTeam {
                            lineupSection(
                                team: home,
                                color: SimulatorTheme.homeColor,
                                batters: viewModel.homeBatters,
                                pitchers: viewModel.homePitchers,
                                lineup: $viewModel.homeLineup,
                                starter: $viewModel.homeStarter
                            )
                        }
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func lineupSection(
        team: SimulatorTeam,
        color: Color,
        batters: [RosterBatter],
        pitchers: [RosterPitcher],
        lineup: Binding<[RosterBatter?]>,
        starter: Binding<RosterPitcher?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(team.shortName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .padding(.horizontal)

            // Starter pitcher
            HStack {
                Text("SP")
                    .font(.caption.weight(.bold))
                    .frame(width: 28)
                    .foregroundStyle(color)

                Menu {
                    Button("Default") { starter.wrappedValue = nil }
                    ForEach(pitchers) { pitcher in
                        Button("\(pitcher.name) (\(pitcher.games)G, \(String(format: "%.1f", pitcher.avgIp))IP)") {
                            starter.wrappedValue = pitcher
                        }
                    }
                } label: {
                    Text(starter.wrappedValue?.name ?? "Default starter")
                        .font(.caption)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal)

            // Batting order
            ForEach(0..<9, id: \.self) { slot in
                HStack {
                    Text("\(slot + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .frame(width: 28)
                        .foregroundStyle(color)

                    Menu {
                        Button("Default") { lineup[slot].wrappedValue = nil }
                        ForEach(batters) { batter in
                            Button("\(batter.name) (\(batter.gamesPlayed)G)") {
                                lineup[slot].wrappedValue = batter
                            }
                        }
                    } label: {
                        Text(lineup[slot].wrappedValue?.name ?? "Default")
                            .font(.caption)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal)
            }
        }
    }
}
