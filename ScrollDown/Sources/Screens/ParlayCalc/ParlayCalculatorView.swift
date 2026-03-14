//
//  ParlayCalculatorView.swift
//  ScrollDown
//
//  Standalone parlay odds calculator.
//  Users input individual leg odds to get combined parlay odds, probability, and EV.
//

import SwiftUI

struct ParlayLegInput: Identifiable {
    let id = UUID()
    var americanOdds: String = ""
    var label: String = ""

    var oddsValue: Int? { Int(americanOdds) }

    /// Convert American odds to implied probability
    var impliedProbability: Double? {
        guard let odds = oddsValue, odds != 0 else { return nil }
        if odds > 0 {
            return 100.0 / (Double(odds) + 100.0)
        } else {
            return Double(abs(odds)) / (Double(abs(odds)) + 100.0)
        }
    }

    /// Convert American odds to decimal
    var decimalOdds: Double? {
        guard let odds = oddsValue, odds != 0 else { return nil }
        if odds > 0 {
            return Double(odds) / 100.0 + 1.0
        } else {
            return 100.0 / Double(abs(odds)) + 1.0
        }
    }
}

struct ParlayCalculatorView: View {
    @State private var legs: [ParlayLegInput] = [ParlayLegInput(), ParlayLegInput()]
    @State private var bookParlayOdds: String = ""

    // MARK: - Computed

    private var validLegs: [ParlayLegInput] {
        legs.filter { $0.oddsValue != nil }
    }

    private var combinedDecimalOdds: Double? {
        let decimals = validLegs.compactMap(\.decimalOdds)
        guard decimals.count >= 2 else { return nil }
        return decimals.reduce(1.0, *)
    }

    private var combinedProbability: Double? {
        let probs = validLegs.compactMap(\.impliedProbability)
        guard probs.count >= 2 else { return nil }
        return probs.reduce(1.0, *)
    }

    private var combinedAmericanOdds: Int? {
        guard let decimal = combinedDecimalOdds, decimal > 1 else { return nil }
        if decimal >= 2.0 {
            return Int((decimal - 1.0) * 100)
        } else {
            return Int(-100.0 / (decimal - 1.0))
        }
    }

    private var parlayEV: Double? {
        guard let prob = combinedProbability,
              let bookOdds = Int(bookParlayOdds), bookOdds != 0 else { return nil }
        let bookDecimal: Double
        if bookOdds > 0 {
            bookDecimal = Double(bookOdds) / 100.0 + 1.0
        } else {
            bookDecimal = 100.0 / Double(abs(bookOdds)) + 1.0
        }
        return (prob * bookDecimal - 1.0) * 100.0
    }

    private var payout: Double? {
        guard let bookOdds = Int(bookParlayOdds), bookOdds != 0 else { return nil }
        if bookOdds > 0 {
            return Double(bookOdds) / 100.0 + 1.0
        } else {
            return 100.0 / Double(abs(bookOdds)) + 1.0
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    Text("Parlay Calculator")
                        .font(.title2.weight(.bold))
                    Text("Enter each leg's American odds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Legs
                VStack(spacing: 12) {
                    ForEach(Array(legs.enumerated()), id: \.element.id) { index, _ in
                        legRow(index: index)
                    }

                    // Add leg
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            legs.append(ParlayLegInput())
                        }
                        HapticService.selection()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Leg")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GameTheme.accentColor)
                    }
                }
                .padding(.horizontal)

                // Results
                if let prob = combinedProbability, let odds = combinedAmericanOdds {
                    VStack(spacing: 16) {
                        // Fair parlay odds
                        VStack(spacing: 8) {
                            Text("Fair Parlay Odds")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(formatAmericanOdds(odds))
                                .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("Probability")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.2f%%", prob * 100))
                                        .font(.subheadline.weight(.semibold).monospacedDigit())
                                }
                                if let decimal = combinedDecimalOdds {
                                    VStack(spacing: 2) {
                                        Text("Decimal")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "%.2f", decimal))
                                            .font(.subheadline.weight(.semibold).monospacedDigit())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(FairBetTheme.info.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(FairBetTheme.info.opacity(0.25), lineWidth: 1)
                        )

                        // Book odds & EV calc
                        VStack(spacing: 8) {
                            Text("Your Book's Parlay Odds")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                TextField("+450", text: $bookParlayOdds)
                                    .font(.title3.weight(.semibold).monospacedDigit())
                                    .keyboardType(.numbersAndPunctuation)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 120)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                if let ev = parlayEV {
                                    VStack(spacing: 2) {
                                        Text("EV")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(FairBetCopy.formatEV(ev))
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(ev > 0 ? FairBetTheme.positive : FairBetTheme.negative)
                                    }
                                }

                                if let pay = payout {
                                    VStack(spacing: 2) {
                                        Text("$100 pays")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(String(format: "$%.0f", pay * 100))
                                            .font(.subheadline.weight(.semibold).monospacedDigit())
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Disclaimer
                Text("Fair odds assume independent outcomes. Same-game parlays may have correlated legs.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: validLegs.count)
        }
    }

    // MARK: - Leg Row

    private func legRow(index: Int) -> some View {
        HStack(spacing: 10) {
            Text("Leg \(index + 1)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 44)

            TextField("e.g. -110", text: $legs[index].americanOdds)
                .font(.subheadline.weight(.medium).monospacedDigit())
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: 100)

            // Show implied prob
            if let prob = legs[index].impliedProbability {
                Text(String(format: "%.1f%%", prob * 100))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            // Optional label
            TextField("Label", text: $legs[index].label)
                .font(.caption)
                .foregroundStyle(.primary)

            // Remove
            if legs.count > 2 {
                Button {
                    withAnimation {
                        _ = legs.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatAmericanOdds(_ odds: Int) -> String {
        odds > 0 ? "+\(odds)" : "\(odds)"
    }
}
