//
//  FairExplainerSheet.swift
//  ScrollDown
//
//  Explainer sheet for fair odds estimates — renders API-provided data only.
//

import SwiftUI

struct FairExplainerSheet: View {
    let bet: APIBet
    @Environment(\.dismiss) private var dismiss

    private var confidence: FairOddsConfidence {
        guard let tier = bet.evConfidenceTier else { return .none }
        switch tier {
        case "full": return .high
        case "decent": return .medium
        case "thin": return .low
        default: return .none
        }
    }

    private var fairOdds: Int {
        bet.fairAmericanOdds ?? 0
    }

    private var fairProb: Double {
        bet.trueProb ?? 0.5
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

                if let refPrice = bet.referencePrice {
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

            Text(bet.evMethodExplanation ?? "Fair estimate not available.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("It's a reference point — not a prediction of what will happen.")
                .font(.subheadline)
                .foregroundColor(.secondary)
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

            // Step-by-step math walkthrough from API
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
            Text(bet.evMethodDisplayName ?? method)
                .font(.caption.weight(.medium))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Math Walkthrough (API-driven)

    @ViewBuilder
    private var mathWalkthroughSection: some View {
        if let steps = bet.explanationSteps, !steps.isEmpty {
            ForEach(Array(steps.enumerated()), id: \.offset) { _, step in
                mathStepView(step: step.stepNumber, title: step.title) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let desc = step.description {
                            Text(desc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let rows = step.detailRows {
                            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                                mathRow(row.label, row.value, highlight: row.isHighlight ?? false)
                            }
                        }
                    }
                }
            }
        } else if let reason = bet.evDisabledReason {
            mathStepView(step: 1, title: "Fair Estimate Not Available") {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    // MARK: - Step view helper

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

    // MARK: - Math row helpers

    private func mathRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(highlight ? .caption.weight(.bold).monospacedDigit() : .caption.weight(.semibold).monospacedDigit())
                .foregroundColor(highlight ? FairBetTheme.positive : .primary)
        }
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
            if confidence == .none, let reason = bet.evDisabledReason {
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
        bet.confidenceDisplayLabel ?? {
            switch confidence {
            case .high: return "Sharp"
            case .medium: return "Market"
            case .low: return "Thin"
            case .none: return "Unavailable"
            }
        }()
    }

    private var confidenceDescription: String {
        switch confidence {
        case .high:
            return "High-action, efficient market. Many books posting with tight consensus and deep liquidity — the devigged number is close to the true probability."
        case .medium:
            return "Decent market with enough books for price discovery and reasonable agreement. Standard confidence."
        case .low:
            return "Low-liquidity market. Few books posting, or wide disagreement between them. The line may reflect one book's model more than true market consensus."
        case .none:
            return "Not enough data to produce a reliable estimate."
        }
    }
}
