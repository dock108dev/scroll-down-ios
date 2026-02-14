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

    private var opponentName: String {
        bet.selection == bet.homeTeam ? bet.awayTeam : bet.homeTeam
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            // Row 2: Opponent + Date/Time
            HStack {
                Text("vs \(opponentName)")
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
        .padding(.vertical, 12)
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
        HStack(alignment: .center, spacing: 6) {
            // Fair Odds chip (pinned left)
            fairOddsChip

            // Vertical divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 16)

            // Book chips (scrollable middle)
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

            // Parlay toggle (pinned right)
            if let onToggleParlay {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 16)

                Button {
                    onToggleParlay()
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
        }
    }

    private var fairOddsChip: some View {
        HStack(spacing: 4) {
            Text(FairBetCopy.fairEstimateShort)
                .font(.caption.weight(.medium))
                .foregroundColor(FairBetTheme.info)
            Text(FairBetCopy.formatOdds(fairAmericanOdds))
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
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

    private func computeEV(for book: BookPrice) -> Double {
        return EVCalculator.computeEV(
            americanOdds: book.price,
            marketProbability: fairProbability,
            bookKey: book.name.lowercased()
        )
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
        switch book.name {
        case "DraftKings": return "DK"
        case "FanDuel": return "FD"
        case "BetMGM": return "MGM"
        case "Caesars": return "CZR"
        case "PointsBet": return "PB"
        case "BetRivers": return "BR"
        case "Fanatics": return "FAN"
        case "ESPNBet", "ESPN BET": return "ESPN"
        case "Hard Rock Bet": return "HR"
        case "bet365": return "365"
        default: return String(book.name.prefix(3)).uppercased()
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

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }

            self.size.height = y + rowHeight
        }
    }
}
