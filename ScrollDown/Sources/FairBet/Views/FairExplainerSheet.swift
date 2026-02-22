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
            return "Pinnacle is widely regarded as the sharpest sportsbook. This estimate uses Shin's method to remove Pinnacle's margin (vig) from both sides of the market. Unlike simple division, Shin's method accounts for favorite-longshot bias, producing more accurate fair probabilities."
        } else if method.contains("pinnacle") && method.contains("extrapol") {
            return "Pinnacle isn't offering this exact line, so the fair price is extrapolated from nearby Pinnacle lines using Shin's method to remove vig. This is less precise than a direct Pinnacle devig but still accounts for favorite-longshot bias and is anchored to sharp market data."
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

            // Step-by-step math walkthrough
            mathWalkthroughSection

            // Per-book implied probabilities (supplementary detail)
            if bet.books.contains(where: { $0.impliedProb != nil }) {
                DisclosureGroup {
                    impliedProbBreakdown
                } label: {
                    Text("All book probabilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
        case "pinnacle_devig":
            return "Pinnacle Devig (Shin's)"
        case "pinnacle_extrapolated":
            return "Pinnacle Extrapolated (Shin's)"
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

    // MARK: - Math Walkthrough

    @ViewBuilder
    private var mathWalkthroughSection: some View {
        if confidence == .none {
            notAvailableSteps
        } else if isMedianConsensus {
            medianSteps
        } else if rawImpliedThis != nil {
            pairedDevigSteps
        } else {
            fallbackSteps
        }
    }

    // MARK: Not available steps

    @ViewBuilder
    private var notAvailableSteps: some View {
        mathStepView(step: 1, title: "Fair Estimate Not Available") {
            VStack(alignment: .leading, spacing: 4) {
                Text(evResult?.evDisabledReason ?? bet.evDisabledReason ?? "Server EV not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()

                Text("The server did not compute a fair probability for this bet. This may be due to insufficient sharp market data or an unsupported market type.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: Paired devig steps (reference prices available)

    @ViewBuilder
    private var pairedDevigSteps: some View {
        // Step 1: Raw odds → implied probability
        mathStepView(step: 1, title: "Convert odds to implied probability") {
            VStack(alignment: .leading, spacing: 4) {
                if let refPrice = referencePriceValue, let thisProb = rawImpliedThis {
                    mathLine("This side", odds: refPrice, prob: thisProb)
                }
                if let oppPrice = bet.oppositeReferencePrice, let otherProb = rawImpliedOther {
                    mathLine("Other side", odds: oppPrice, prob: otherProb)
                }
                if let total = rawImpliedTotal {
                    Divider()
                    HStack {
                        Text("Total:")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", total * 100))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundColor(.primary)
                    }
                }

                if rawImpliedOther == nil {
                    Text("Only this side's reference price is available.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }

        // Step 2: The vig
        if let total = rawImpliedTotal, let vig = vigPercent, vig > 0 {
            mathStepView(step: 2, title: "Identify the vig") {
                VStack(alignment: .leading, spacing: 4) {
                    mathRow("Total implied:", String(format: "%.1f%%", total * 100))
                    mathRow("Should be:", "100.0%")
                    mathRow("Vig (margin):", String(format: "%.1f%%", vig * 100))
                }
            }
        }

        // Step 3: Remove vig → fair probability
        if isPinnacleDevig, let total = rawImpliedTotal, total > 1.0 {
            // Shin's method walkthrough
            let z = 1.0 - (1.0 / total)
            mathStepView(step: 3, title: "Remove the vig (Shin's method)") {
                VStack(alignment: .leading, spacing: 4) {
                    mathRow("Total implied:", String(format: "%.1f%%", total * 100))
                    mathRow("z = 1 − 1/total:", String(format: "%.4f", z))

                    Divider()

                    Text("Shin's formula adjusts each side's probability\nusing z to correct for favorite-longshot bias.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let thisProb = rawImpliedThis {
                        mathRow("Raw q (this side):", String(format: "%.1f%%", thisProb * 100))
                    }

                    Divider()
                    mathRow("Fair probability:", FairBetCopy.formatProbability(fairProb))
                    mathRow("Fair odds:", FairBetCopy.formatOdds(fairOdds))

                    Text(isPinnacleExtrapolated
                         ? "Shin's method shifts more vig correction to longshots. Extrapolated from nearby Pinnacle lines."
                         : "Shin's method shifts more vig correction to longshots.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        } else if let thisProb = rawImpliedThis, let total = rawImpliedTotal, total > 1.0 {
            mathStepView(step: 3, title: "Remove the vig") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f%% ÷ %.1f%% = %.1f%%",
                                thisProb * 100, total * 100, fairProb * 100))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)

                    Divider()
                    mathRow("Fair probability:", FairBetCopy.formatProbability(fairProb))
                    mathRow("Fair odds:", FairBetCopy.formatOdds(fairOdds))
                }
            }
        } else {
            mathStepView(step: 3, title: "Fair probability") {
                VStack(alignment: .leading, spacing: 4) {
                    mathRow("Fair probability:", FairBetCopy.formatProbability(fairProb))
                    mathRow("Fair odds:", FairBetCopy.formatOdds(fairOdds))
                }
            }
        }

        // Step 4: EV
        evStepView(step: 4)
    }

    // MARK: Median consensus steps

    @ViewBuilder
    private var medianSteps: some View {
        let bookCount = bet.books.filter { $0.impliedProb != nil }.count

        mathStepView(step: 1, title: "Median implied probability") {
            VStack(alignment: .leading, spacing: 4) {
                Text("The median implied probability across \(bookCount) book\(bookCount == 1 ? "" : "s") is \(FairBetCopy.formatProbability(fairProb)).")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()
                mathRow("Fair probability:", FairBetCopy.formatProbability(fairProb))
                mathRow("Fair odds:", FairBetCopy.formatOdds(fairOdds))
            }
        }

        evStepView(step: 2)
    }

    // MARK: Fallback steps (minimal data)

    @ViewBuilder
    private var fallbackSteps: some View {
        mathStepView(step: 1, title: "Fair probability") {
            VStack(alignment: .leading, spacing: 4) {
                mathRow("Fair probability:", FairBetCopy.formatProbability(fairProb))
                mathRow("Fair odds:", FairBetCopy.formatOdds(fairOdds))
            }
        }

        evStepView(step: 2)
    }

    // MARK: EV step (shared)

    @ViewBuilder
    private func evStepView(step: Int) -> some View {
        if let bestBook = bestBookForEV, let profit = bestBookProfit, let ev = evResult?.ev {
            mathStepView(step: step, title: "Calculate EV at best price") {
                VStack(alignment: .leading, spacing: 4) {
                    mathRow("Best price:", "\(FairBetCopy.formatOdds(bestBook.price)) (\(bestBook.name))")

                    Text("If this hits (\(FairBetCopy.formatProbability(fairProb)) chance): win \(String(format: "$%.2f", profit))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                    Text("If this misses (\(FairBetCopy.formatProbability(1.0 - fairProb)) chance): lose $1.00")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)

                    Divider()

                    let winPart = fairProb * profit
                    let lossPart = (1.0 - fairProb)
                    let evDollars = winPart - lossPart

                    Text(String(format: "EV = (%.2f × $%.2f) − (%.2f × $1.00)", fairProb, profit, 1.0 - fairProb))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                    Text(String(format: "   = $%.2f − $%.2f", winPart, lossPart))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.primary)
                    Text(String(format: "   = %@$%.2f per dollar (%@)",
                                evDollars >= 0 ? "+" : "", evDollars,
                                FairBetCopy.formatEV(ev)))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundColor(ev > 0 ? FairBetTheme.positive : FairBetTheme.negative)
                }
            }
        } else if let reason = evResult?.evDisabledReason ?? bet.evDisabledReason {
            mathStepView(step: step, title: "Expected Value") {
                Text("EV not available: \(reason)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        } else {
            mathStepView(step: step, title: "Expected Value") {
                Text("EV not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: Step view helper

    private func mathStepView<Content: View>(step: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(step)")
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(FairBetTheme.info))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                content()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FairBetTheme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(FairBetTheme.cardBorder, lineWidth: 1)
        )
    }

    // MARK: Math row helpers

    private func mathLine(_ label: String, odds: Int, prob: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            Spacer()
            Text(FairBetCopy.formatOdds(odds))
                .font(.caption.monospacedDigit())
                .foregroundColor(.primary)
            Text("→")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f%%", prob * 100))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundColor(.primary)
                .frame(width: 50, alignment: .trailing)
        }
    }

    private func mathRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundColor(.primary)
        }
    }

    // MARK: Walkthrough computed helpers

    private var referencePriceValue: Int? {
        evResult?.referencePrice ?? bet.referencePrice
    }

    private var rawImpliedThis: Double? {
        guard let refPrice = referencePriceValue else { return nil }
        return AmericanOdds(refPrice).impliedProbability
    }

    private var rawImpliedOther: Double? {
        guard let oppPrice = bet.oppositeReferencePrice else { return nil }
        return AmericanOdds(oppPrice).impliedProbability
    }

    private var rawImpliedTotal: Double? {
        guard let thisProb = rawImpliedThis else { return nil }
        guard let otherProb = rawImpliedOther else { return nil }
        return thisProb + otherProb
    }

    private var vigPercent: Double? {
        guard let total = rawImpliedTotal else { return nil }
        return total - 1.0
    }

    private var bestBookForEV: BookPrice? {
        bet.bestBook
    }

    private var bestBookProfit: Double? {
        guard let book = bestBookForEV else { return nil }
        return OddsCalculator.americanToProfit(book.price)
    }

    private var isMedianConsensus: Bool {
        guard let method = bet.evMethod?.lowercased() else { return false }
        return method.contains("median") || method.contains("consensus")
    }

    private var isPinnacleDevig: Bool {
        guard let method = bet.evMethod?.lowercased() else { return false }
        return method.contains("pinnacle") && (method.contains("devig") || method.contains("extrapol"))
    }

    private var isPinnacleExtrapolated: Bool {
        bet.evMethod?.lowercased().contains("extrapol") == true
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
        let pinnacleNote = isPinnacleDevig ? " Derived from Pinnacle's sharp lines using Shin's method." : ""
        switch confidence {
        case .high:
            return "Multiple sportsbooks are pricing both sides of this bet, allowing accurate vig removal." + pinnacleNote
        case .medium:
            return "A few sportsbooks are pricing both sides. The estimate is reasonable but less precise." + pinnacleNote
        case .low:
            return "Limited books are pricing this bet. The estimate is a rough approximation."
        case .none:
            return "Not enough data to produce a reliable estimate."
        }
    }
}
