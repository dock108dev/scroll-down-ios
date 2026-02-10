//
//  OddsComparisonView.swift
//  ScrollDown
//
//  Embedded odds comparison view for HomeView.
//  NavigationStack wrapper and header removed — driven by HomeView.
//  League filters removed — driven by HomeView's segmented control.
//

import SwiftUI

struct OddsComparisonView: View {
    @ObservedObject var viewModel: OddsComparisonViewModel
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.allBets.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.allBets.isEmpty {
                Spacer()
                FairBetErrorStateView(message: error) {
                    Task { await viewModel.refresh() }
                }
                Spacer()
            } else if viewModel.displayedBets.isEmpty {
                emptyStateView
            } else {
                // Bets feed
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Refresh button (right-aligned)
                        HStack {
                            Spacer()
                            Button {
                                Task { await viewModel.refresh() }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading)
                        }
                        .padding(.bottom, 4)

                        // Bet cards
                        ForEach(viewModel.displayedBets) { bet in
                            BetCardV2(
                                bet: bet,
                                oddsFormat: viewModel.oddsFormat,
                                evResult: viewModel.evResult(for: bet)
                            )
                        }

                        // Bottom padding
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            if viewModel.allBets.isEmpty {
                await viewModel.loadAllData()
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text(viewModel.loadingProgress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Filters Section removed (summary bar + EV toggle removed, refresh moved inline)

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                if viewModel.showOnlyPositiveEV {
                    Text("No +EV bets right now")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Check back later or try a different league")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Show all bets") {
                        viewModel.showOnlyPositiveEV = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(FairBetTheme.info)
                    .padding(.top, 8)
                } else {
                    Text("No bets available")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Pull down to refresh")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Compact Filter Chip

struct CompactFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact EV Toggle

struct CompactEVToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.caption2)
                Text("+EV Only")
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isOn ? .white : FairBetTheme.positive)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isOn ? FairBetTheme.positive : FairBetTheme.positive.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Error State View

struct FairBetErrorStateView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("Couldn't load bets")
                .font(.headline)
                .foregroundColor(.primary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retryAction)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.accentColor))
        }
        .padding()
    }
}
