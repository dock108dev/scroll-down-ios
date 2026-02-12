import Foundation

// MARK: - Selection Label Builder

/// Utility for building human-readable selection labels
struct SelectionLabelBuilder {

    static func buildLabel(
        marketKey: String,
        side: SelectionSide,
        line: Double?,
        homeTeam: String?,
        awayTeam: String?,
        playerName: String?
    ) -> String {
        switch marketKey {
        case "spread":
            return buildSpreadLabel(side: side, line: line, homeTeam: homeTeam, awayTeam: awayTeam)
        case "total":
            return buildTotalLabel(side: side, line: line)
        case "h2h":
            return buildMoneylineLabel(side: side, homeTeam: homeTeam, awayTeam: awayTeam)
        default:
            // Player props and other markets
            if let player = playerName, let line = line {
                return buildPlayerPropLabel(side: side, playerName: player, line: line, marketKey: marketKey)
            }
            return side.rawValue.capitalized
        }
    }

    private static func buildSpreadLabel(
        side: SelectionSide,
        line: Double?,
        homeTeam: String?,
        awayTeam: String?
    ) -> String {
        guard let line = line else { return side.rawValue.capitalized }

        switch side {
        case .home:
            let team = homeTeam ?? "Home"
            return "\(team) -\(BetGroupKeyBuilder.formatLine(line))"
        case .away:
            let team = awayTeam ?? "Away"
            return "\(team) +\(BetGroupKeyBuilder.formatLine(line))"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildTotalLabel(side: SelectionSide, line: Double?) -> String {
        guard let line = line else { return side.rawValue.capitalized }

        switch side {
        case .over:
            return "Over \(BetGroupKeyBuilder.formatLine(line))"
        case .under:
            return "Under \(BetGroupKeyBuilder.formatLine(line))"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildMoneylineLabel(
        side: SelectionSide,
        homeTeam: String?,
        awayTeam: String?
    ) -> String {
        switch side {
        case .home:
            return homeTeam ?? "Home"
        case .away:
            return awayTeam ?? "Away"
        case .draw:
            return "Draw"
        default:
            return side.rawValue.capitalized
        }
    }

    private static func buildPlayerPropLabel(
        side: SelectionSide,
        playerName: String,
        line: Double,
        marketKey: String
    ) -> String {
        let propType = marketKey
            .replacingOccurrences(of: "player_", with: "")
            .capitalized

        switch side {
        case .over:
            return "\(playerName) Over \(BetGroupKeyBuilder.formatLine(line)) \(propType)"
        case .under:
            return "\(playerName) Under \(BetGroupKeyBuilder.formatLine(line)) \(propType)"
        default:
            return "\(playerName) \(side.rawValue.capitalized)"
        }
    }
}
