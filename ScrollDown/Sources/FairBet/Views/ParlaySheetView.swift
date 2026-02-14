//
//  ParlaySheetView.swift
//  ScrollDown
//
//  Parlay builder detail sheet — shows combined fair odds and leg list
//

import SwiftUI

struct ParlaySheetView: View {
    @ObservedObject var viewModel: OddsComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Combined result card
                    combinedResultCard

                    // Leg list
                    VStack(spacing: 0) {
                        ForEach(viewModel.parlayBets) { bet in
                            legRow(bet)
                            if bet.id != viewModel.parlayBets.last?.id {
                                Divider()
                                    .padding(.horizontal, 14)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(FairBetTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(FairBetTheme.cardBorder, lineWidth: 1)
                    )

                    // Disclaimer
                    Text(FairBetCopy.disclaimer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Clear Parlay button
                    Button {
                        viewModel.clearParlay()
                        dismiss()
                    } label: {
                        Text("Clear Parlay")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(FairBetTheme.negative)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(FairBetTheme.negative.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .navigationTitle("Parlay Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.medium))
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Combined Result Card

    private var combinedResultCard: some View {
        VStack(spacing: 12) {
            Text("\(viewModel.parlayCount)-Leg Parlay")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text(FairBetCopy.formatOdds(viewModel.parlayFairAmericanOdds))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Fair Probability")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(FairBetCopy.formatProbability(viewModel.parlayFairProbability))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 24)

                VStack(spacing: 2) {
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(confidenceLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(confidenceColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FairBetTheme.info.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FairBetTheme.info.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Leg Row

    private func legRow(_ bet: APIBet) -> some View {
        HStack(spacing: 10) {
            LeagueBadgeSmall(league: bet.league)

            VStack(alignment: .leading, spacing: 2) {
                Text(bet.selectionDisplay)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(bet.awayTeam) @ \(bet.homeTeam)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Per-leg fair odds & probability
            VStack(alignment: .trailing, spacing: 2) {
                if let evResult = viewModel.evResult(for: bet) {
                    Text(FairBetCopy.formatOdds(evResult.fairAmericanOdds))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(FairBetCopy.formatProbability(evResult.fairProbability))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Remove button
            Button {
                viewModel.toggleParlay(bet)
                if viewModel.parlayCount == 0 {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private var confidenceLabel: String {
        switch viewModel.parlayConfidence {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .none: return "N/A"
        }
    }

    private var confidenceColor: Color {
        switch viewModel.parlayConfidence {
        case .high: return FairBetTheme.positive
        case .medium: return FairBetTheme.positiveMuted
        case .low: return FairBetTheme.negative
        case .none: return .secondary
        }
    }
}
