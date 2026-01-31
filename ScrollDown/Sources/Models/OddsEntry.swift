import Foundation

/// Betting odds entry as defined in the OpenAPI spec (OddsEntry schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
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
        case marketTypeSnake = "market_type"
        case marketTypeCamel = "marketType"
        case side
        case line
        case price
        case isClosingLineSnake = "is_closing_line"
        case isClosingLineCamel = "isClosingLine"
        case observedAtSnake = "observed_at"
        case observedAtCamel = "observedAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        book = try container.decode(String.self, forKey: .book)

        marketType = (try? container.decode(MarketType.self, forKey: .marketTypeSnake))
            ?? (try? container.decode(MarketType.self, forKey: .marketTypeCamel))
            ?? .unknown

        side = try container.decodeIfPresent(String.self, forKey: .side)
        line = try container.decodeIfPresent(Double.self, forKey: .line)
        price = try container.decodeIfPresent(Double.self, forKey: .price)

        isClosingLine = (try? container.decode(Bool.self, forKey: .isClosingLineSnake))
            ?? (try? container.decode(Bool.self, forKey: .isClosingLineCamel))
            ?? false

        observedAt = (try? container.decode(String.self, forKey: .observedAtSnake))
            ?? (try? container.decode(String.self, forKey: .observedAtCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(book, forKey: .book)
        try container.encode(marketType, forKey: .marketTypeSnake)
        try container.encodeIfPresent(side, forKey: .side)
        try container.encodeIfPresent(line, forKey: .line)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encode(isClosingLine, forKey: .isClosingLineSnake)
        try container.encodeIfPresent(observedAt, forKey: .observedAtSnake)
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



