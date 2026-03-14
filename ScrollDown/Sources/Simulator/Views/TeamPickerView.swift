//
//  TeamPickerView.swift
//  ScrollDown
//
//  Side-by-side away/home team selection for the simulator.
//

import SwiftUI

struct TeamPickerView: View {
    @ObservedObject var viewModel: MLBSimulatorViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingTeams {
                ProgressView("Loading teams…")
                    .padding()
            } else {
                HStack(spacing: 16) {
                    // Away team
                    teamColumn(
                        label: "AWAY",
                        color: SimulatorTheme.awayColor,
                        selected: viewModel.awayTeam,
                        onSelect: { viewModel.selectAwayTeam($0) }
                    )

                    Text("@")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)

                    // Home team
                    teamColumn(
                        label: "HOME",
                        color: SimulatorTheme.homeColor,
                        selected: viewModel.homeTeam,
                        onSelect: { viewModel.selectHomeTeam($0) }
                    )
                }
                .padding(.horizontal)
            }
        }
    }

    private func teamColumn(
        label: String,
        color: Color,
        selected: SimulatorTeam?,
        onSelect: @escaping (SimulatorTeam?) -> Void
    ) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            Menu {
                Button("None") { onSelect(nil) }
                ForEach(viewModel.teams) { team in
                    Button(team.name) { onSelect(team) }
                }
            } label: {
                HStack {
                    Text(selected?.shortName ?? "Select")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            }
            .foregroundStyle(.primary)

            if let team = selected {
                Text("\(team.gamesWithStats) games")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
