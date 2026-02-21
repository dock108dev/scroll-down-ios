//
//  BetCardComponents.swift
//  ScrollDown
//
//  Shared components used by BetCard, FairExplainerSheet, and odds tables.
//

import SwiftUI

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
