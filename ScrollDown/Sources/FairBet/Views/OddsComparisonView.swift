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
    @State private var showingSettings = false

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
                        // Slim summary bar
                        summaryBar
                            .padding(.bottom, 4)

                        // Compact filters (market + EV toggle, no league filters)
                        filtersSection
                            .padding(.bottom, 8)

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
        .sheet(isPresented: $showingSettings) {
            FairBetSettingsSheet(viewModel: viewModel)
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

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 8) {
            if viewModel.positiveEVCount > 0 {
                Text("\(viewModel.positiveEVCount) +EV Bets")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(FairBetTheme.positive)
            } else {
                Text("No +EV bets right now")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
            }

            if let bestEV = viewModel.bestEVAvailable, bestEV > 0 {
                Text("·")
                    .foregroundColor(.secondary)
                Text("Best +\(String(format: "%.1f", bestEV))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("·")
                .foregroundColor(.secondary)
            Text("\(viewModel.booksAvailable.count) Books")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            // Settings button
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(FairBetTheme.surfaceSecondary.opacity(0.6))
        )
    }

    // MARK: - Filters Section (market + EV toggle only, no league)

    private var filtersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // +EV Only toggle
                CompactEVToggle(isOn: $viewModel.showOnlyPositiveEV)

                // Refresh button
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
        }
    }

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

// MARK: - Settings Sheet

struct FairBetSettingsSheet: View {
    @ObservedObject var viewModel: OddsComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Display") {
                    Picker("Odds Format", selection: $viewModel.oddsFormat) {
                        ForEach(OddsFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }

                Section("Data Quality") {
                    Toggle("Hide Limited Data", isOn: $viewModel.hideLimitedData)

                    Text("When enabled, only shows bets with reliable fair odds (proper vig removal from multiple books).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FairBet compares odds across sportsbooks to help you find value.")
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        Text("Fair odds are estimated by removing vig from current market prices.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Text(FairBetCopy.disclaimer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
