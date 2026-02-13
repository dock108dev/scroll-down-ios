import Foundation
import OSLog

private let teamStatLogger = Logger(subsystem: "com.scrolldown.app", category: "teamStats")

/// Team boxscore statistics
struct TeamStat: Codable, Identifiable {
    let team: String
    let isHome: Bool
    let stats: [String: AnyCodable]
    let source: String?
    let updatedAt: String?

    var id: String { team }

    // Dynamic coding key for flexible decoding
    private struct FlexKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    // Standard coding keys for encoding
    enum CodingKeys: String, CodingKey {
        case team, isHome, stats, source, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FlexKey.self)

        team = try container.decode(String.self, forKey: FlexKey(stringValue: "team")!)

        // isHome: try camelCase first, then snake_case, then default false
        if let key = FlexKey(stringValue: "isHome"), container.contains(key) {
            isHome = try container.decode(Bool.self, forKey: key)
        } else if let key = FlexKey(stringValue: "is_home"), container.contains(key) {
            isHome = try container.decode(Bool.self, forKey: key)
        } else {
            isHome = false
        }

        // stats: try nested dict first, then collect remaining keys as flat stats
        let statsKey = FlexKey(stringValue: "stats")!
        if container.contains(statsKey),
           let nested = try? container.decode([String: AnyCodable].self, forKey: statsKey) {
            stats = nested
        } else {
            let knownKeys: Set<String> = ["team", "isHome", "is_home", "stats", "source", "updatedAt", "updated_at"]
            var collected: [String: AnyCodable] = [:]
            for key in container.allKeys where !knownKeys.contains(key.stringValue) {
                if let val = try? container.decode(AnyCodable.self, forKey: key) {
                    collected[key.stringValue] = val
                }
            }
            stats = collected
        }

        source = try? container.decode(String.self, forKey: FlexKey(stringValue: "source")!)

        updatedAt = (try? container.decode(String.self, forKey: FlexKey(stringValue: "updatedAt")!))
            ?? (try? container.decode(String.self, forKey: FlexKey(stringValue: "updated_at")!))

        let teamName = self.team
        let homeFlag = self.isHome
        let keyList = Array(self.stats.keys).sorted().joined(separator: ", ")
        teamStatLogger.info("📊 TeamStat decoded: \(teamName, privacy: .public) isHome=\(homeFlag) keys=[\(keyList, privacy: .public)]")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team, forKey: .team)
        try container.encode(isHome, forKey: .isHome)
        try container.encode(stats, forKey: .stats)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    init(team: String, isHome: Bool, stats: [String: AnyCodable], source: String? = nil, updatedAt: String? = nil) {
        self.team = team
        self.isHome = isHome
        self.stats = stats
        self.source = source
        self.updatedAt = updatedAt
    }
}
