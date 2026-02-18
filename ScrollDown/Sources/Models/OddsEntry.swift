import Foundation

/// Betting odds entry
struct OddsEntry: Codable, Identifiable {
    let book: String
    let marketType: MarketType
    let side: String?
    let line: Double?
    let price: Double?
    let isClosingLine: Bool
    let observedAt: String?
    var marketCategory: String? = nil
    var playerName: String? = nil
    var description: String? = nil

    var id: String {
        let player = playerName ?? "none"
        return "\(book)-\(marketType.rawValue)-\(side ?? "none")-\(player)"
    }

    init(book: String, marketType: MarketType, side: String? = nil, line: Double? = nil, price: Double? = nil, isClosingLine: Bool = false, observedAt: String? = nil, marketCategory: String? = nil, playerName: String? = nil, description: String? = nil) {
        self.book = book
        self.marketType = marketType
        self.side = side
        self.line = line
        self.price = price
        self.isClosingLine = isClosingLine
        self.observedAt = observedAt
        self.marketCategory = marketCategory
        self.playerName = playerName
        self.description = description
    }

    enum CodingKeys: String, CodingKey {
        case book
        case marketType
        case side
        case line
        case price
        case isClosingLine
        case observedAt
        case marketCategory
        case playerName
        case description
    }
}
