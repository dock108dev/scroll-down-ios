//
//  BetCard.swift
//  ScrollDown
//
//  Action-first bet cards: What → Where → Fair value (informational)
//

import SwiftUI

struct BetCard: View {
    let bet: APIBet
    let oddsFormat: OddsFormat
    let evResult: OddsComparisonViewModel.EVResult?
    var isInParlay: Bool = false
    var onToggleParlay: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("preferredSportsbook") private var preferredSportsbook = ""
    @State private var isExpanded = false
    @State private var showFairExplainer = false

    private var isCompact: Bool { horizontalSizeClass == .compact }

    // MARK: - Computed Properties

    private var fairProbability: Double {
        evResult?.fairProbability ?? 0.5
    }

    private var fairAmericanOdds: Int {
        evResult?.fairAmericanOdds ?? 0
    }

    private var bestBook: BookPrice? {
        bet.bestBook
    }

    private var bestBookEV: Double? {
        evResult?.ev
    }

    private var confidence: FairOddsConfidence {
        evResult?.confidence ?? .none
    }

    private var isHighValueBet: Bool {
        guard let ev = bestBookEV else { return false }
        return ev >= 5.0 && (confidence == .high || confidence == .medium)
    }

    private var parlayBorderColor: Color {
        if isInParlay { return FairBetTheme.info.opacity(0.6) }
        if isHighValueBet { return FairBetTheme.positive.opacity(0.4) }
        return FairBetTheme.cardBorder
    }

    private var sortedBooks: [BookPrice] {
        bet.books.sorted { computeEV(for: $0) > computeEV(for: $1) }
    }

    /// The primary book to feature: user's preferred sportsbook, or best available
    private var primaryBook: BookPrice? {
        if !preferredSportsbook.isEmpty,
           let preferred = bet.books.first(where: { $0.name == preferredSportsbook }) {
            return preferred
        }
        return bestBook
    }

    private var primaryIsBest: Bool {
        guard let primary = primaryBook, let best = bestBook else { return true }
        return primary.name == best.name && primary.price == best.price
    }

    /// All books except the primary (and best if shown separately)
    private var remainingBooks: [BookPrice] {
        sortedBooks.filter { book in
            if let primary = primaryBook, book.name == primary.name { return false }
            if !primaryIsBest, let best = bestBook, book.name == best.name { return false }
            return true
        }
    }

    private var opponentName: String {
        bet.selection == bet.homeTeam ? bet.awayTeam : bet.homeTeam
    }

    private var contextLine: String {
        if bet.market.isPlayerProp || bet.market.isTeamProp ||
           bet.market == .alternateSpreads || bet.market == .alternateTotals {
            return "\(bet.awayTeam) @ \(bet.homeTeam)"
        }
        return "vs \(opponentName)"
    }

    /// Whether FAIR has enough data to show
    private var hasFairEstimate: Bool {
        confidence != .none && fairAmericanOdds != 0
    }

    private var valueColor: Color {
        guard let ev = bestBookEV else { return .secondary }
        if ev >= 5 { return FairBetTheme.positive }
        if ev > 0 { return FairBetTheme.positiveMuted }
        return .secondary
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            // 1. What is the bet?
            betDescriptionSection

            Divider()

            // 2. Where can I place it? + 3. Fair value reference
            if isCompact {
                compactActionSection
            } else {
                regularActionSection
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, isCompact ? 10 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(FairBetTheme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(parlayBorderColor, lineWidth: isInParlay ? 1.5 : (isHighValueBet ? 1.5 : 1))
        )
        .sheet(isPresented: $showFairExplainer) {
            FairExplainerSheet(bet: bet, evResult: evResult)
        }
    }

    // MARK: - Bet Description (Row 1-2)

    private var betDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: Selection + League + Market
            HStack(alignment: .top) {
                Text(bet.selectionDisplay)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 6) {
                    LeagueBadgeSmall(league: bet.league)
                    Text(FairBetCopy.marketLabel(for: bet.market.rawValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Row 2: Context + Time
            HStack {
                Text(contextLine)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - iPhone Layout

    private var compactActionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Primary book (best price) — the main CTA
            if let primary = primaryBook {
                HStack {
                    primaryBookView(primary)
                    Spacer()
                    if let onToggleParlay {
                        parlayButton(action: onToggleParlay)
                    }
                }
            }

            // Best available callout (if user's preferred isn't the best)
            if let best = bestBook, !primaryIsBest {
                bestAvailableCallout(best)
            }

            // Fair estimate — informational, not a chip
            fairReferenceRow

            // Other books — expandable
            if !remainingBooks.isEmpty {
                otherBooksDisclosure
            }
        }
    }

    /// Primary book display — prominent, actionable
    private func primaryBookView(_ book: BookPrice) -> some View {
        let ev = computeEV(for: book)
        return HStack(spacing: 8) {
            BookAbbreviationButton(name: book.name)

            Text(FairBetCopy.formatOdds(book.price))
                .font(.body.weight(.bold))
                .foregroundColor(.primary)

            if primaryIsBest {
                Text("Best")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(valueColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(valueColor.opacity(0.12))
                    )
            }

            if ev > 0 {
                Text(FairBetCopy.formatEV(ev))
                    .font(.caption)
                    .foregroundColor(evColor(for: ev))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FairBetTheme.surfaceSecondary)
        )
    }

    /// "Best available" callout when user's preferred book isn't the best
    private func bestAvailableCallout(_ book: BookPrice) -> some View {
        let ev = computeEV(for: book)
        return HStack(spacing: 4) {
            Text("Best:")
                .font(.caption)
                .foregroundColor(.secondary)
            BookAbbreviationButton(name: book.name, font: .caption.weight(.medium))
            Text(FairBetCopy.formatOdds(book.price))
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
            if ev > 0 {
                Text(FairBetCopy.formatEV(ev))
                    .font(.caption2)
                    .foregroundColor(evColor(for: ev))
            }
        }
    }

    /// Fair estimate — tappable informational element, visually distinct from sportsbooks
    @ViewBuilder
    private var fairReferenceRow: some View {
        if hasFairEstimate {
            Button {
                showFairExplainer = true
            } label: {
                HStack(spacing: 6) {
                    Text("Est. fair")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(FairBetCopy.formatOdds(fairAmericanOdds))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(FairBetTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    /// Expandable list of other sportsbooks
    private var otherBooksDisclosure: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Other books \u{25B4}" : "Other books \u{25BE}")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Text("(\(remainingBooks.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                FlowLayout(spacing: 6) {
                    ForEach(remainingBooks) { book in
                        MiniBookChip(
                            book: book,
                            isBest: false,
                            ev: computeEV(for: book)
                        )
                    }
                }
            }
        }
    }

    // MARK: - iPad Layout

    private var regularActionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Horizontal book scroll + parlay
            HStack(alignment: .center, spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(sortedBooks) { book in
                            MiniBookChip(
                                book: book,
                                isBest: book.price == bestBook?.price,
                                ev: computeEV(for: book)
                            )
                        }
                    }
                }

                if let onToggleParlay {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 16)

                    parlayButton(action: onToggleParlay)
                }
            }

            // Fair estimate — informational, below the books
            if hasFairEstimate {
                Button {
                    showFairExplainer = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Est. fair")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(FairBetCopy.formatOdds(fairAmericanOdds))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(FairBetTheme.borderSubtle, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Shared Components

    private func parlayButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(isInParlay ? "\u{2713} Parlay" : "\u{FF0B} Parlay")
                .font(.caption.weight(.medium))
                .foregroundColor(isInParlay ? FairBetTheme.info : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isInParlay ? FairBetTheme.info.opacity(0.10) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isInParlay ? FairBetTheme.info.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    private func computeEV(for book: BookPrice) -> Double {
        if let serverEV = book.evPercent {
            return serverEV
        }
        return EVCalculator.computeEV(
            americanOdds: book.price,
            marketProbability: fairProbability,
            bookKey: book.name.lowercased()
        )
    }

    private func evColor(for ev: Double) -> Color {
        if ev >= 5 { return FairBetTheme.positive }
        if ev > 0 { return FairBetTheme.positiveMuted }
        if ev < -2 { return FairBetTheme.negative }
        return .secondary
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(bet.gameDate) {
            formatter.dateFormat = "h:mm a"
            return "Today · \(formatter.string(from: bet.gameDate))"
        } else if calendar.isDateInTomorrow(bet.gameDate) {
            formatter.dateFormat = "h:mm a"
            return "Tomorrow · \(formatter.string(from: bet.gameDate))"
        } else {
            formatter.dateFormat = "MMM d"
            let datePart = formatter.string(from: bet.gameDate)
            formatter.dateFormat = "h:mm a"
            let timePart = formatter.string(from: bet.gameDate)
            return "\(datePart) · \(timePart)"
        }
    }
}

// MARK: - Book Abbreviation Button (tap to see full name)

struct BookAbbreviationButton: View {
    let name: String
    var font: Font = .subheadline.weight(.medium)
    @State private var showFullName = false

    var body: some View {
        Button {
            showFullName.toggle()
        } label: {
            Text(showFullName ? name : BookNameHelper.abbreviated(name))
                .font(font)
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 0.15), value: showFullName)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mini Book Chip

struct MiniBookChip: View {
    let book: BookPrice
    let isBest: Bool
    let ev: Double

    private var isPositiveEV: Bool { ev > 0 }

    var body: some View {
        HStack(spacing: 4) {
            BookAbbreviationButton(
                name: book.name,
                font: .caption.weight(.medium)
            )
            .foregroundColor(isPositiveEV ? evColor : .secondary)

            Text(FairBetCopy.formatOdds(book.price))
                .font(.subheadline.weight(.bold))
                .foregroundColor(isPositiveEV ? evColor : .primary)

            Text(FairBetCopy.formatEV(ev))
                .font(.caption)
                .foregroundColor(evColor.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(chipBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isPositiveEV ? evColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var evColor: Color {
        if ev >= 5 {
            return FairBetTheme.positive
        } else if ev > 0 {
            return FairBetTheme.positiveMuted
        } else if ev < -2 {
            return FairBetTheme.negative
        }
        return .secondary
    }

    private var chipBackground: Color {
        if ev >= 5 {
            return Color(FairBetTheme.positive).opacity(0.12)
        } else if ev > 0 {
            return Color(FairBetTheme.positiveMuted).opacity(0.10)
        }
        return FairBetTheme.surfaceSecondary.opacity(0.5)
    }
}

// MARK: - Fair Explainer Sheet

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
                    explanationSection
                    devigMathSection
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
                        Text("PIN \(FairBetCopy.formatOdds(refPrice))")
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

            Text("This is an estimate of the fair market price for this bet, calculated by comparing prices across multiple sportsbooks and removing each book's built-in margin (vig).")
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

            // Show the actual devig numbers if we have them
            if let trueProb = bet.trueProb {
                devigNumbersCard(trueProb: trueProb)
            } else {
                // Fallback: show what we computed client-side
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

// MARK: - League Badge Small

struct LeagueBadgeSmall: View {
    let league: FairBetLeague

    var body: some View {
        Text(league.displayName)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(leagueColor)
            )
    }

    private var leagueColor: Color {
        switch league {
        case .nba: return Color(red: 0.77, green: 0.36, blue: 0.15)
        case .nhl: return Color(red: 0.0, green: 0.27, blue: 0.55)
        case .ncaab: return Color(red: 0.13, green: 0.55, blue: 0.13)
        }
    }
}

// MARK: - Book Name Helper

enum BookNameHelper {
    /// Abbreviations for all INCLUDED_BOOKS in ev_config.py
    static func abbreviated(_ name: String) -> String {
        switch name {
        case "DraftKings": return "DK"
        case "FanDuel": return "FD"
        case "BetMGM": return "MGM"
        case "Caesars": return "CZR"
        case "ESPNBet", "ESPN BET": return "ESPN"
        case "Fanatics": return "FAN"
        case "Hard Rock Bet": return "HR"
        case "Pinnacle": return "PIN"
        case "PointsBet", "PointsBet (US)": return "PB"
        case "bet365": return "365"
        case "Betway": return "BWY"
        case "Circa Sports": return "CIR"
        case "Fliff": return "FLF"
        case "SI Sportsbook": return "SI"
        case "theScore Bet": return "SCR"
        case "Tipico": return "TIP"
        case "Unibet": return "UNI"
        default: return String(name.prefix(3)).uppercased()
        }
    }
}
