//
//  GameDetailViewModel+Odds.swift
//  ScrollDown
//
//  Odds section: computed properties, market grouping, pregame/wrap-up lines.
//

import Foundation

extension GameDetailViewModel {

    // MARK: - Odds Section

    /// All odds entries from the game detail
    var oddsEntries: [OddsEntry] {
        detail?.odds ?? []
    }

    /// Whether we have odds data to show
    var hasOddsData: Bool {
        !oddsEntries.isEmpty
    }

    /// Available categories that have data, in display order
    var availableOddsCategories: [MarketCategory] {
        let present = Set(oddsEntries.map { $0.resolvedCategory })
        return MarketCategory.allCases.filter { present.contains($0) }
    }

    /// Unique sportsbooks sorted alphabetically
    var oddsBooks: [String] {
        Array(Set(oddsEntries.map { $0.book })).sorted()
    }

    /// Filter odds entries by category
    func oddsEntries(for category: MarketCategory) -> [OddsEntry] {
        oddsEntries.filter { $0.resolvedCategory == category }
    }

    /// Identifies a unique market row (marketType + side + line + playerName + description)
    struct OddsMarketKey: Hashable, Identifiable {
        let marketType: MarketType
        let side: String?
        let line: Double?
        let playerName: String?
        let description: String?

        var id: String {
            "\(marketType.rawValue)-\(side ?? "")-\(line ?? 0)-\(playerName ?? "")-\(description ?? "")"
        }

        var displayLabel: String {
            var parts: [String] = []
            if let player = playerName {
                parts.append(player)
            }
            // Market description
            switch marketType {
            case .spread:
                if let side, let line {
                    let sign = line >= 0 ? "+" : ""
                    parts.append("\(side) \(sign)\(line)")
                }
            case .moneyline:
                if let side { parts.append(side) }
            case .total:
                if let side, let line {
                    parts.append("\(side) \(line)")
                }
            case .teamTotal:
                // Show abbreviated team name from description (e.g., "AUB O 77.5")
                if let desc = description {
                    parts.append(TeamAbbreviations.abbreviation(for: desc))
                }
                if let side {
                    let short = side.lowercased() == "over" ? "O" : (side.lowercased() == "under" ? "U" : side)
                    parts.append(short)
                }
                if let line { parts.append(String(line)) }
            default:
                if marketType.isPlayerProp {
                    parts.append(marketType.displayName)
                }
                if let side {
                    let short = side.lowercased() == "over" ? "O" : (side.lowercased() == "under" ? "U" : side)
                    parts.append(short)
                }
                if let line { parts.append(String(line)) }
            }
            return parts.isEmpty ? marketType.rawValue : parts.joined(separator: " ")
        }
    }

    /// Distinct market rows for a given category
    func oddsMarkets(for category: MarketCategory) -> [OddsMarketKey] {
        let entries = oddsEntries(for: category)
        var seen = Set<OddsMarketKey>()
        var result: [OddsMarketKey] = []
        for entry in entries {
            let key = OddsMarketKey(
                marketType: entry.marketType,
                side: entry.side,
                line: entry.line,
                playerName: entry.playerName,
                description: entry.description
            )
            if seen.insert(key).inserted {
                result.append(key)
            }
        }
        return result
    }

    /// Player prop markets grouped by player name, preserving order.
    /// Each entry is (playerName, [(statType, [OddsMarketKey])]).
    func groupedPlayerPropMarkets(filtered: [OddsMarketKey]) -> [(player: String, statGroups: [(statType: String, markets: [OddsMarketKey])])] {
        var playerOrder: [String] = []
        var playerGroups: [String: [(statType: String, markets: [OddsMarketKey])]] = [:]

        for market in filtered {
            let player = market.playerName ?? "Unknown"
            let statType = market.marketType.displayName

            if playerGroups[player] == nil {
                playerOrder.append(player)
                playerGroups[player] = []
            }

            // Find or create the stat group for this player
            if let idx = playerGroups[player]!.firstIndex(where: { $0.statType == statType }) {
                playerGroups[player]![idx].markets.append(market)
            } else {
                playerGroups[player]!.append((statType: statType, markets: [market]))
            }
        }

        return playerOrder.map { player in
            (player: player, statGroups: playerGroups[player]!)
        }
    }

    /// Cross-book price lookup: returns the American odds price for a given market row + book
    func oddsPrice(for market: OddsMarketKey, book: String) -> Double? {
        oddsEntries.first { entry in
            entry.book == book &&
            entry.marketType == market.marketType &&
            entry.side == market.side &&
            entry.line == market.line &&
            entry.playerName == market.playerName &&
            entry.description == market.description
        }?.price
    }

    // MARK: - Pregame Odds Lines

    /// Main betting lines for the pregame section — spread, total, moneyline without outcomes
    struct PregameOddsLine: Identifiable {
        let id: String
        let label: String
        let detail: String
    }

    var pregameOddsLines: [PregameOddsLine] {
        guard let detail else { return [] }
        let metrics = DerivedMetrics(detail.derivedMetrics)
        var lines: [PregameOddsLine] = []
        if let spread = metrics.pregameSpreadLabel {
            lines.append(PregameOddsLine(id: "spread", label: "Spread", detail: spread))
        }
        if let total = metrics.pregameTotalLabel {
            lines.append(PregameOddsLine(id: "total", label: "O/U", detail: total))
        }
        if let mlHome = metrics.pregameMLHomeLabel, let mlAway = metrics.pregameMLAwayLabel {
            lines.append(PregameOddsLine(id: "ml", label: "ML", detail: "\(mlAway) / \(mlHome)"))
        }
        return lines
    }

    // MARK: - Wrap-up Odds Summary

    /// Odds line + outcome for display in the wrap-up section.
    struct WrapUpOddsLine: Identifiable {
        let id: String
        let label: String
        let lineType: String  // "Open" or "Close"
        let line: String
        let outcome: String?
    }

    /// Build wrap-up odds: opening + closing row for spread, O/U, ML (6 rows).
    var wrapUpOddsLines: [WrapUpOddsLine] {
        guard let detail else { return [] }
        let m = DerivedMetrics(detail.derivedMetrics)
        var lines: [WrapUpOddsLine] = []

        // Spread – opening then closing
        if let openSpread = m.openingSpreadLabel {
            lines.append(WrapUpOddsLine(
                id: "spread-open", label: "Spread", lineType: "Open", line: openSpread,
                outcome: m.openingSpreadOutcomeLabel
            ))
        }
        if let closeSpread = m.pregameSpreadLabel {
            lines.append(WrapUpOddsLine(
                id: "spread-close", label: "Spread", lineType: "Close", line: closeSpread,
                outcome: m.spreadOutcomeLabel
            ))
        }

        // O/U – opening then closing
        if let openTotal = m.openingTotalLabel {
            lines.append(WrapUpOddsLine(
                id: "total-open", label: "O/U", lineType: "Open", line: openTotal,
                outcome: m.openingTotalOutcomeLabel
            ))
        }
        if let closeTotal = m.pregameTotalLabel {
            lines.append(WrapUpOddsLine(
                id: "total-close", label: "O/U", lineType: "Close", line: closeTotal,
                outcome: m.totalOutcomeLabel
            ))
        }

        // ML – opening then closing
        if let openMLHome = m.openingMLHomeLabel, let openMLAway = m.openingMLAwayLabel {
            lines.append(WrapUpOddsLine(
                id: "ml-open", label: "ML", lineType: "Open", line: "\(openMLAway) / \(openMLHome)",
                outcome: m.openingMlOutcomeLabel
            ))
        }
        if let mlHome = m.pregameMLHomeLabel, let mlAway = m.pregameMLAwayLabel {
            lines.append(WrapUpOddsLine(
                id: "ml-close", label: "ML", lineType: "Close", line: "\(mlAway) / \(mlHome)",
                outcome: m.mlOutcomeLabel
            ))
        }

        return lines
    }
}
