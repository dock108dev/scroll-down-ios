//
//  FairExplainerSheet.swift
//  ScrollDown
//
//  Extracted from BetCard.swift — self-contained explainer sheet for fair odds estimates.
//

import SwiftUI

struct FairExplainerSheet: View {
    let bet: APIBet
    let evResult: OddsComparisonViewModel.EVResult?
    @Environment(\.dismiss) private var dismiss

    private var confidence: FairOddsConfidence {
        evResult?.confidence ?? .none
    }

    private var fairOdds: Int {
        evResult?.fairAmericanOdds ?? 0
    }

    private var fairProb: Double {
        evResult?.fairProbability ?? 0.5
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fairValueHeader
                    Divider()
                    devigMathSection
                    explanationSection
                    confidenceSection
                    dataSourcesSection
                    disclaimerSection
                }
                .padding()
            }
            .background(FairBetTheme.surfaceTint)
            .navigationTitle("Fair Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Header

    private var fairValueHeader: some View {
        VStack(spacing: 8) {
            Text(bet.selectionDisplay)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Estimated Fair Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FairBetCopy.formatOdds(fairOdds))
                        .font(.title.weight(.bold))
                        .foregroundColor(.primary)
                }

                if let refPrice = evResult?.referencePrice {
                    VStack(spacing: 2) {
                        Text("Sharp Reference")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(FairBetCopy.formatOdds(refPrice))
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Text("Implied probability: \(FairBetCopy.formatProbability(fairProb))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FairBetTheme.cardBackground)
        )
    }

    // MARK: - What Is This

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What is this?", systemImage: "questionmark.circle")
                .font(.subheadline.weight(.semibold))

            Text(methodExplanation)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("It's a reference point — not a prediction of what will happen.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var methodExplanation: String {
        guard let method = bet.evMethod?.lowercased() else {
            return "This is an estimate of the fair market price for this bet, calculated by comparing prices across multiple sportsbooks and removing each book's built-in margin (vig)."
        }

        if method.contains("pinnacle") && method.contains("devig") {
            return "Pinnacle is widely regarded as the sharpest sportsbook. This estimate removes Pinnacle's margin (vig) from both sides of the market to derive the true implied probability."
        } else if method.contains("pinnacle") && method.contains("extrapol") {
            return "Pinnacle isn't offering this exact line, so the fair price is extrapolated from nearby Pinnacle lines. This is less precise than a direct Pinnacle devig but still anchored to sharp market data."
        } else if method.contains("paired") || method.contains("vig_removal") || method.contains("vig removal") {
            return "This estimate pairs the over/under (or home/away) prices from each sportsbook, removes the built-in margin (vig), and uses the median across books as the fair probability."
        } else if method.contains("median") || method.contains("consensus") {
            return "This estimate takes the median implied probability across all sportsbooks pricing this market, smoothing out individual book biases to approximate the true odds."
        } else if method.contains("sharp") {
            return "This estimate is derived from a sharp (professional) sportsbook's pricing, which typically has lower margins and more accurate odds than recreational books."
        } else {
            return "This is an estimate of the fair market price for this bet, calculated by comparing prices across multiple sportsbooks and removing each book's built-in margin (vig)."
        }
    }

    // MARK: - Devig Math

    private var devigMathSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How it was calculated", systemImage: "function")
                .font(.subheadline.weight(.semibold))

            // Method used
            if let method = bet.evMethod {
                methodRow(method)
            }

            // Show the actual devig numbers if we have them
            if let trueProb = bet.trueProb {
                devigNumbersCard(trueProb: trueProb)
            } else {
                // Client-side computed probability
                devigNumbersCard(trueProb: fairProb)
            }

            // Per-book implied probabilities
            if bet.books.contains(where: { $0.impliedProb != nil }) {
                impliedProbBreakdown
            }
        }
    }

    private func methodRow(_ method: String) -> some View {
        HStack(spacing: 6) {
            Text("Method:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(methodDisplayName(method))
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }

    private func methodDisplayName(_ method: String) -> String {
        switch method.lowercased() {
        case "paired_devig", "paired_vig_removal", "paired vig removal":
            return "Paired vig removal"
        case "median_consensus", "median consensus":
            return "Median consensus"
        case "sharp_reference", "sharp_book":
            return "Sharp book reference"
        default:
            return method.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func devigNumbersCard(trueProb: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // This side
            HStack {
                Text("This side")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                Spacer()
                Text(FairBetCopy.formatProbability(trueProb))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundColor(.primary)
                Text("(\(FairBetCopy.formatOdds(fairOdds)))")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }

            // Opposite side (if available)
            if let oppRef = bet.oppositeReferencePrice {
                let oppProb = 1.0 - trueProb
                HStack {
                    Text("Other side")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Text(FairBetCopy.formatProbability(oppProb))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundColor(.primary)
                    Text("(\(FairBetCopy.formatOdds(oppRef)))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Vig removed
            let rawTotal = impliedProbTotal
            if rawTotal > 1.0 {
                HStack {
                    Text("Vig removed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Text(String(format: "%.1f%%", (rawTotal - 1.0) * 100))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundColor(FairBetTheme.info)
                }
            }

            // Best book EV
            if let bestEV = evResult?.ev, bestEV != 0 {
                HStack {
                    Text("Best EV")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Spacer()
                    Text(FairBetCopy.formatEV(bestEV))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundColor(bestEV > 0 ? FairBetTheme.positive : FairBetTheme.negative)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FairBetTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(FairBetTheme.cardBorder, lineWidth: 1)
        )
    }

    /// Sum of raw implied probabilities from the best books (before devig)
    private var impliedProbTotal: Double {
        // Use reference prices if available
        if let refPrice = evResult?.referencePrice {
            let thisSideImplied = AmericanOdds(refPrice).impliedProbability
            if let oppPrice = bet.oppositeReferencePrice {
                let oppImplied = AmericanOdds(oppPrice).impliedProbability
                return thisSideImplied + oppImplied
            }
            return thisSideImplied + (1.0 - fairProb) // estimate
        }
        return 1.0 // can't determine vig
    }

    /// Breakdown of each book's implied probability
    private var impliedProbBreakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Book implied probabilities")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(bet.books.sorted(by: { ($0.impliedProb ?? 0) < ($1.impliedProb ?? 0) })) { book in
                if let implied = book.impliedProb {
                    HStack {
                        HStack(spacing: 4) {
                            if book.isSharp == true {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                            }
                            Text(book.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(FairBetCopy.formatOdds(book.price))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.primary)
                        Text(FairBetCopy.formatProbability(implied))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FairBetTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(FairBetTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Confidence

    private var confidenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Estimate Quality", systemImage: "chart.bar")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 8) {
                Circle()
                    .fill(confidenceColor)
                    .frame(width: 10, height: 10)

                Text(confidenceLabel)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text(confidenceDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            // Disabled reason from API
            if let reason = evResult?.evDisabledReason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Data Sources

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Data Sources", systemImage: "building.columns")
                .font(.subheadline.weight(.semibold))

            Text("\(bet.books.count) sportsbooks compared")
                .font(.subheadline)
                .foregroundColor(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(bet.books.sorted(by: { $0.name < $1.name })) { book in
                    HStack(spacing: 3) {
                        if book.isSharp == true {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.yellow)
                        }
                        Text(book.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FairBetTheme.surfaceSecondary)
                    )
                }
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimerSection: some View {
        Text(FairBetCopy.fullDisclaimer)
            .font(.caption2)
            .foregroundColor(Color(.tertiaryLabel))
            .padding(.top, 8)
    }

    // MARK: - Helpers

    private var confidenceColor: Color {
        switch confidence {
        case .high: return FairBetTheme.positive
        case .medium: return .yellow
        case .low: return .orange
        case .none: return .gray
        }
    }

    private var confidenceLabel: String {
        switch confidence {
        case .high: return "High confidence"
        case .medium: return "Moderate confidence"
        case .low: return "Limited data"
        case .none: return "Insufficient data"
        }
    }

    private var confidenceDescription: String {
        switch confidence {
        case .high:
            return "Multiple sportsbooks are pricing both sides of this bet, allowing accurate vig removal."
        case .medium:
            return "A few sportsbooks are pricing both sides. The estimate is reasonable but less precise."
        case .low:
            return "Limited books are pricing this bet. The estimate is a rough approximation."
        case .none:
            return "Not enough data to produce a reliable estimate."
        }
    }
}
