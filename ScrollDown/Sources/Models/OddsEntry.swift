import Foundation

/// Betting odds entry as defined in the OpenAPI spec (OddsEntry schema)
struct OddsEntry: Codable, Identifiable {
    let book: String
    let marketType: MarketType
    let side: String?
    let line: Double?
    let price: Double?
    let isClosingLine: Bool
    let observedAt: String?
    
    /// Computed ID for Identifiable conformance
    var id: String {
        "\(book)-\(marketType.rawValue)-\(side ?? "none")"
    }
    
    enum CodingKeys: String, CodingKey {
        case book
        case marketType = "market_type"
        case side
        case line
        case price
        case isClosingLine = "is_closing_line"
        case observedAt = "observed_at"
    }
}



