//
//  MLBSimulatorView.swift
//  ScrollDown
//
//  Top-level container for the MLB Monte Carlo simulator.
//

import SwiftUI

struct MLBSimulatorView: View {
    @ObservedObject var viewModel: MLBSimulatorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("MLB Simulator")
                        .font(.title2.weight(.bold))
                    Text("10,000-iteration Monte Carlo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Team Picker
                TeamPickerView(viewModel: viewModel)

                // Lineup Builder (show when both teams selected)
                if viewModel.awayTeam != nil && viewModel.homeTeam != nil {
                    LineupBuilderView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Simulate Button
                if viewModel.canSimulate {
                    Button {
                        Task { await viewModel.runSimulation() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSimulating {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.isSimulating ? "Simulating…" : "Run Simulation")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SimulatorTheme.homeColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(viewModel.isSimulating)
                    .padding(.horizontal)
                    .transition(.opacity)
                }

                // Loading animation
                if viewModel.isSimulating {
                    SimulatorLoadingView()
                        .frame(height: 200)
                        .transition(.opacity)
                }

                // Results
                if let result = viewModel.result {
                    SimulatorResultsView(result: result)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Reset
                if viewModel.result != nil || viewModel.awayTeam != nil {
                    Button("Reset") {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            viewModel.reset()
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.result != nil)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.canSimulate)
        }
        .task { await viewModel.loadTeams() }
    }
}
