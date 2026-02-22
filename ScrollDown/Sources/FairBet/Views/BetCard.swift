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

            Text(FairBetCopy.formatEV(ev))
                .font(.caption)
                .foregroundColor(evColor(for: ev))
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
            Text(FairBetCopy.formatEV(ev))
                .font(.caption2)
                .foregroundColor(evColor(for: ev))
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
        book.evPercent ?? 0
    }

    private func evColor(for ev: Double) -> Color {
        if ev >= 5 { return FairBetTheme.positive }
        if ev > 0 { return FairBetTheme.positiveMuted }
        if ev < 0 { return FairBetTheme.negative }
        return .secondary
    }

    private enum TimeFormatting {
        static let timeOnly: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f
        }()

        static let dateOnly: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f
        }()
    }

    private var formattedTime: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(bet.gameDate) {
            return "Today · \(TimeFormatting.timeOnly.string(from: bet.gameDate))"
        } else if calendar.isDateInTomorrow(bet.gameDate) {
            return "Tomorrow · \(TimeFormatting.timeOnly.string(from: bet.gameDate))"
        } else {
            let datePart = TimeFormatting.dateOnly.string(from: bet.gameDate)
            let timePart = TimeFormatting.timeOnly.string(from: bet.gameDate)
            return "\(datePart) · \(timePart)"
        }
    }
}
