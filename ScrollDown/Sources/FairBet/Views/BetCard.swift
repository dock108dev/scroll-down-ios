//
//  BetCard.swift
//  ScrollDown
//
//  Always-open bet cards with organized layout
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
    private var isCompact: Bool { horizontalSizeClass == .compact }

    // MARK: - Computed Properties

    /// Fair probability from evResult (pre-computed with proper pairing)
    private var fairProbability: Double {
        evResult?.fairProbability ?? 0.5
    }

    /// Fair American odds from evResult
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

    private var anchorBook: BookPrice? {
        if !preferredSportsbook.isEmpty,
           let preferred = bet.books.first(where: { $0.name == preferredSportsbook }) {
            return preferred
        }
        return bestBook
    }

    private var anchorIsBestAvailable: Bool {
        guard let anchor = anchorBook, let best = bestBook else { return true }
        return anchor.name == best.name && anchor.price == best.price
    }

    private var otherBooks: [BookPrice] {
        sortedBooks.filter { book in
            if let anchor = anchorBook, book.name == anchor.name { return false }
            if !anchorIsBestAvailable, let best = bestBook, book.name == best.name { return false }
            return true
        }
    }

    private var opponentName: String {
        bet.selection == bet.homeTeam ? bet.awayTeam : bet.homeTeam
    }

    /// Context line: matchup for props/alts, "vs opponent" for mainlines
    private var contextLine: String {
        if bet.market.isPlayerProp || bet.market.isTeamProp ||
           bet.market == .alternateSpreads || bet.market == .alternateTotals {
            return "\(bet.awayTeam) @ \(bet.homeTeam)"
        }
        return "vs \(opponentName)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 6 : 8) {
            // Row 1: Selection name + League badge & Market
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

            // Row 2: Context line + Date/Time
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

            Divider()

            // Books Grid (with Fair Odds as first chip)
            booksGrid
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

    // MARK: - Books Grid

    private var booksGrid: some View {
        Group {
            if isCompact {
                compactBooksGrid
            } else {
                regularBooksGrid
            }
        }
    }

    /// iPhone: vertical decision stack
    @State private var isExpanded = false

    private var compactBooksGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Row B: Fair odds + Parlay button
            primaryActionRow

            // Disabled reason
            disabledReasonLabel

            // Row C: Anchor book
            if let anchor = anchorBook {
                anchorBookRow(anchor)
            }

            // Row D: Best available (if anchor isn't the best)
            if let best = bestBook, !anchorIsBestAvailable {
                bestAvailableRow(best)
            }

            // Row E: Other books disclosure
            if !otherBooks.isEmpty {
                otherBooksDisclosure
            }
        }
    }

    /// iPad: single-row horizontal scroll
    private var regularBooksGrid: some View {
        HStack(alignment: .center, spacing: 6) {
            fairOddsChip

            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 16)

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
    }

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

    private var confidenceDotColor: Color? {
        switch confidence {
        case .high: return FairBetTheme.positive
        case .medium: return .yellow
        case .low: return .orange
        case .none: return nil
        }
    }

    private var fairOddsChip: some View {
        HStack(spacing: 4) {
            // Confidence dot
            if let dotColor = confidenceDotColor {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }

            Text(FairBetCopy.fairEstimateShort)
                .font(.caption.weight(.medium))
                .foregroundColor(FairBetTheme.info)
            Text(FairBetCopy.formatOdds(fairAmericanOdds))
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)

            // Reference price
            if let refPrice = evResult?.referencePrice {
                Text("PIN \(FairBetCopy.formatOdds(refPrice))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(FairBetTheme.info.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(FairBetTheme.info.opacity(0.25), lineWidth: 1)
        )
        .fixedSize()
    }

    /// Disabled reason label when confidence is .none
    @ViewBuilder
    private var disabledReasonLabel: some View {
        if confidence == .none, let reason = evResult?.evDisabledReason {
            Text(reason)
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
    }

    private func computeEV(for book: BookPrice) -> Double {
        // Prefer server-side EV when available
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

    // MARK: - iPhone Subviews

    private var primaryActionRow: some View {
        HStack {
            fairOddsChip
            Spacer()
            if let onToggleParlay {
                parlayButton(action: onToggleParlay)
            }
        }
    }

    private func anchorBookRow(_ book: BookPrice) -> some View {
        let ev = computeEV(for: book)
        return HStack(spacing: 6) {
            Text(BookNameHelper.abbreviated(book.name))
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

            Text(FairBetCopy.formatOdds(book.price))
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)

            Text(FairBetCopy.formatEV(ev))
                .font(.caption)
                .foregroundColor(evColor(for: ev).opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(FairBetTheme.surfaceSecondary)
        )
    }

    private func bestAvailableRow(_ book: BookPrice) -> some View {
        let ev = computeEV(for: book)
        return HStack(spacing: 4) {
            Text("Best available:")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(BookNameHelper.abbreviated(book.name)) \(FairBetCopy.formatOdds(book.price))")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            Text(FairBetCopy.formatEV(ev))
                .font(.caption)
                .foregroundColor(evColor(for: ev).opacity(0.8))
        }
    }

    private var otherBooksDisclosure: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Other books \u{25B4}" : "Other books \u{25BE}")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Text("(\(otherBooks.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                FlowLayout(spacing: 6) {
                    ForEach(otherBooks) { book in
                        MiniBookChip(
                            book: book,
                            isBest: book.price == bestBook?.price,
                            ev: computeEV(for: book)
                        )
                    }
                }
            }
        }
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
            // Sharp book indicator
            if book.isSharp == true {
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow.opacity(0.8))
            }

            Text(abbreviatedName)
                .font(.caption.weight(.medium))
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

    private var abbreviatedName: String {
        BookNameHelper.abbreviated(book.name)
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

