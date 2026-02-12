import Foundation

// MARK: - Bet Group Factory

/// Factory for creating BetGroups from raw data
struct BetGroupFactory {

    /// Create a spread bet group
    static func createSpread(
        gameId: String,
        line: Double,
        homeTeam: String,
        awayTeam: String,
        homePrices: [GroupBookPrice],
        awayPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "spread",
            subjectId: nil,
            line: line
        )

        let homeSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .home),
            betGroupKey: betGroupKey,
            side: .home,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "spread",
                side: .home,
                line: line,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                playerName: nil
            ),
            teamId: homeTeam,
            prices: homePrices
        )

        let awaySelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .away),
            betGroupKey: betGroupKey,
            side: .away,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "spread",
                side: .away,
                line: line,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                playerName: nil
            ),
            teamId: awayTeam,
            prices: awayPrices
        )

        let pairingStatus = determinePairingStatus(selections: [homeSelection, awaySelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "spread",
            subjectId: nil,
            line: line,
            pairingStatus: pairingStatus,
            selections: [homeSelection, awaySelection]
        )
    }

    /// Create a total bet group
    static func createTotal(
        gameId: String,
        line: Double,
        overPrices: [GroupBookPrice],
        underPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "total",
            subjectId: nil,
            line: line
        )

        let overSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .over),
            betGroupKey: betGroupKey,
            side: .over,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "total",
                side: .over,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: nil
            ),
            teamId: nil,
            prices: overPrices
        )

        let underSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .under),
            betGroupKey: betGroupKey,
            side: .under,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: "total",
                side: .under,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: nil
            ),
            teamId: nil,
            prices: underPrices
        )

        let pairingStatus = determinePairingStatus(selections: [overSelection, underSelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "total",
            subjectId: nil,
            line: line,
            pairingStatus: pairingStatus,
            selections: [overSelection, underSelection]
        )
    }

    /// Create a moneyline bet group
    static func createMoneyline(
        gameId: String,
        homeTeam: String,
        awayTeam: String,
        homePrices: [GroupBookPrice],
        awayPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: "h2h",
            subjectId: nil,
            line: nil
        )

        let homeSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .home),
            betGroupKey: betGroupKey,
            side: .home,
            label: homeTeam,
            teamId: homeTeam,
            prices: homePrices
        )

        let awaySelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .away),
            betGroupKey: betGroupKey,
            side: .away,
            label: awayTeam,
            teamId: awayTeam,
            prices: awayPrices
        )

        let pairingStatus = determinePairingStatus(selections: [homeSelection, awaySelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: "h2h",
            subjectId: nil,
            line: nil,
            pairingStatus: pairingStatus,
            selections: [homeSelection, awaySelection]
        )
    }

    /// Create a player prop bet group
    static func createPlayerProp(
        gameId: String,
        marketKey: String,
        playerId: String,
        playerName: String,
        line: Double,
        overPrices: [GroupBookPrice],
        underPrices: [GroupBookPrice]
    ) -> BetGroup {
        let betGroupKey = BetGroupKeyBuilder.buildBetGroupKey(
            gameId: gameId,
            marketKey: marketKey,
            subjectId: playerId,
            line: line
        )

        let overSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .over),
            betGroupKey: betGroupKey,
            side: .over,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: marketKey,
                side: .over,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: playerName
            ),
            teamId: nil,
            prices: overPrices
        )

        let underSelection = Selection(
            selectionKey: BetGroupKeyBuilder.buildSelectionKey(betGroupKey: betGroupKey, side: .under),
            betGroupKey: betGroupKey,
            side: .under,
            label: SelectionLabelBuilder.buildLabel(
                marketKey: marketKey,
                side: .under,
                line: line,
                homeTeam: nil,
                awayTeam: nil,
                playerName: playerName
            ),
            teamId: nil,
            prices: underPrices
        )

        let pairingStatus = determinePairingStatus(selections: [overSelection, underSelection])

        return BetGroup(
            betGroupKey: betGroupKey,
            gameId: gameId,
            marketKey: marketKey,
            subjectId: playerId,
            line: line,
            pairingStatus: pairingStatus,
            selections: [overSelection, underSelection]
        )
    }

    /// Determine pairing status based on selection prices
    private static func determinePairingStatus(selections: [Selection]) -> PairingStatus {
        guard selections.count >= 2 else { return .oneSided }

        let allHavePrices = selections.allSatisfy { $0.hasPrices }
        let anyHasPrices = selections.contains { $0.hasPrices }

        if !anyHasPrices {
            return .unpaired
        }

        if !allHavePrices {
            return .oneSided
        }

        // Check if any book prices both sides
        let firstBookKeys = selections[0].bookKeys
        for selection in selections.dropFirst() {
            if !firstBookKeys.isDisjoint(with: selection.bookKeys) {
                return .paired
            }
        }

        return .unpaired
    }
}
