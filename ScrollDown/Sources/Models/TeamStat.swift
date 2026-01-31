import Foundation

/// Team boxscore statistics as defined in the OpenAPI spec (TeamStat schema)
/// Handles both snake_case (app endpoint) and camelCase (admin endpoint) JSON formats
struct TeamStat: Codable, Identifiable {
    let team: String
    let isHome: Bool
    let stats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?

    /// Computed ID for Identifiable conformance
    var id: String { team }

    enum CodingKeys: String, CodingKey {
        case team
        case isHomeSnake = "is_home"
        case isHomeCamel = "isHome"
        case stats
        case source
        case updatedAtSnake = "updated_at"
        case updatedAtCamel = "updatedAt"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        team = try container.decode(String.self, forKey: .team)

        isHome = (try? container.decode(Bool.self, forKey: .isHomeSnake))
            ?? (try? container.decode(Bool.self, forKey: .isHomeCamel))
            ?? false

        stats = (try? container.decode([String: AnyCodable].self, forKey: .stats)) ?? [:]
        source = try container.decodeIfPresent(String.self, forKey: .source)

        updatedAt = (try? container.decode(String.self, forKey: .updatedAtSnake))
            ?? (try? container.decode(String.self, forKey: .updatedAtCamel))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team, forKey: .team)
        try container.encode(isHome, forKey: .isHomeSnake)
        try container.encode(stats, forKey: .stats)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAtSnake)
    }

    init(team: String, isHome: Bool, stats: [String: AnyCodable], source: String? = nil, updatedAt: String? = nil) {
        self.team = team
        self.isHome = isHome
        self.stats = stats
        self.source = source
        self.updatedAt = updatedAt
    }
}



