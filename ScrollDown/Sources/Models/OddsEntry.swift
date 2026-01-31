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

    var id: String {
        "\(book)-\(marketType.rawValue)-\(side ?? "none")"
    }

    init(book: String, marketType: MarketType, side: String? = nil, line: Double? = nil, price: Double? = nil, isClosingLine: Bool = false, observedAt: String? = nil) {
        self.book = book
        self.marketType = marketType
        self.side = side
        self.line = line
        self.price = price
        self.isClosingLine = isClosingLine
        self.observedAt = observedAt
    }
}
