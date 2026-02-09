import Foundation

// MARK: - Block Role

/// Semantic role for flow blocks (backend classification, not displayed)
enum BlockRole: String, Codable, CaseIterable {
    case setup = "SETUP"
    case momentumShift = "MOMENTUM_SHIFT"
    case response = "RESPONSE"
    case decisionPoint = "DECISION_POINT"
    case resolution = "RESOLUTION"
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = BlockRole(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Block Player Stat

/// Player stats within a block's mini box score
struct BlockPlayerStat: Codable, Equatable {
    let name: String
    // Basketball stats (cumulative through this block)
    let pts: Int?
    let reb: Int?
    let ast: Int?
    let threePm: Int?
    // Basketball deltas (scored during this block)
    let deltaPts: Int?
    let deltaReb: Int?
    let deltaAst: Int?
    // Hockey stats (cumulative through this block)
    let goals: Int?
    let assists: Int?
    let sog: Int?
    let plusMinus: Int?
    // Hockey deltas
    let deltaGoals: Int?
    let deltaAssists: Int?

    enum CodingKeys: String, CodingKey {
        case name, pts, reb, ast
        case threePm = "3pm"
        case deltaPts = "delta_pts"
        case deltaReb = "delta_reb"
        case deltaAst = "delta_ast"
        case goals, assists, sog, plusMinus
        case deltaGoals = "delta_goals"
        case deltaAssists = "delta_assists"
    }

    /// Formatted stat line for basketball: "15p/4r/6a (+7p/+2r)"
    var basketballStatLine: String {
        var cumulative: [String] = []
        if let p = pts { cumulative.append("\(p)p") }
        if let r = reb { cumulative.append("\(r)r") }
        if let a = ast { cumulative.append("\(a)a") }

        var delta: [String] = []
        if let dp = deltaPts, dp != 0 { delta.append("+\(dp)p") }
        if let dr = deltaReb, dr != 0 { delta.append("+\(dr)r") }
        if let da = deltaAst, da != 0 { delta.append("+\(da)a") }

        let base = cumulative.joined(separator: "/")
        if delta.isEmpty {
            return base
        }
        return "\(base) (\(delta.joined(separator: "/")))"
    }

    /// Formatted stat line for hockey: "2g/1a (+1g)"
    var hockeyStatLine: String {
        var cumulative: [String] = []
        if let g = goals { cumulative.append("\(g)g") }
        if let a = assists { cumulative.append("\(a)a") }

        var delta: [String] = []
        if let dg = deltaGoals, dg != 0 { delta.append("+\(dg)g") }
        if let da = deltaAssists, da != 0 { delta.append("+\(da)a") }

        let base = cumulative.joined(separator: "/")
        if delta.isEmpty {
            return base
        }
        return "\(base) (\(delta.joined(separator: "/")))"
    }

    /// Compact basketball stats: "12p 4r" on first line
    var compactBasketballStats: String {
        var parts: [String] = []
        if let p = pts, p > 0 { parts.append("\(p)p") }
        if let r = reb, r > 0 { parts.append("\(r)r") }
        if let a = ast, a > 0 { parts.append("\(a)a") }
        return parts.isEmpty ? "-" : parts.joined(separator: " ")
    }

    /// Compact hockey stats: "2g 1a"
    var compactHockeyStats: String {
        var parts: [String] = []
        if let g = goals, g > 0 { parts.append("\(g)g") }
        if let a = assists, a > 0 { parts.append("\(a)a") }
        return parts.isEmpty ? "-" : parts.joined(separator: " ")
    }
}

// MARK: - Block Team Mini Box

/// Team mini box score within a block
struct BlockTeamMiniBox: Codable, Equatable {
    let team: String
    let players: [BlockPlayerStat]

    /// Top 2 players for compact display
    var topPlayers: [BlockPlayerStat] {
        Array(players.prefix(2))
    }
}

// MARK: - Block Mini Box

/// Mini box score for a flow block
struct BlockMiniBox: Codable, Equatable {
    let home: BlockTeamMiniBox
    let away: BlockTeamMiniBox
    let blockStars: [String]

    enum CodingKeys: String, CodingKey {
        case home, away, blockStars
    }

    func isBlockStar(_ name: String) -> Bool {
        blockStars.contains(name)
    }
}

// MARK: - Flow Block

/// A narrative block in the game flow
struct FlowBlock: Codable, Identifiable, Equatable {
    let blockIndex: Int
    let role: BlockRole
    let momentIndices: [Int]
    let periodStart: Int
    let periodEnd: Int
    let scoreBefore: [Int]  // [away, home]
    let scoreAfter: [Int]   // [away, home]
    let playIds: [Int]
    let keyPlayIds: [Int]
    let narrative: String
    let miniBox: BlockMiniBox?
    let embeddedSocialPostId: Int?

    var id: Int { blockIndex }

    var startScore: ScoreSnapshot {
        ScoreSnapshot(
            home: scoreBefore.count > 1 ? scoreBefore[1] : 0,
            away: scoreBefore.first ?? 0
        )
    }

    var endScore: ScoreSnapshot {
        ScoreSnapshot(
            home: scoreAfter.count > 1 ? scoreAfter[1] : 0,
            away: scoreAfter.first ?? 0
        )
    }

    /// Period display string (e.g., "Q1" or "Q1-Q2")
    var periodDisplay: String {
        if periodStart == periodEnd {
            return "Q\(periodStart)"
        }
        return "Q\(periodStart)-Q\(periodEnd)"
    }
}

// MARK: - Flow Play

/// Individual play details within the game flow
struct FlowPlay: Codable, Identifiable, Equatable {
    let playId: Int
    let playIndex: Int
    let period: Int
    let clock: String?
    let playType: String?
    let description: String?
    let team: String?
    let playerName: String?
    let homeScore: Int?
    let awayScore: Int?

    var id: Int { playId }
}

// MARK: - Game Flow Response

/// Response from the flow endpoint
struct GameFlowResponse: Decodable {
    let gameId: Int
    let sport: String?
    let plays: [FlowPlay]
    let blocks: [FlowBlock]
    let validationPassed: Bool
    let validationErrors: [String]

    enum CodingKeys: String, CodingKey {
        case gameId, sport, plays, blocks, validationPassed, validationErrors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gameId = try container.decode(Int.self, forKey: .gameId)
        sport = try container.decodeIfPresent(String.self, forKey: .sport)
        plays = try container.decodeIfPresent([FlowPlay].self, forKey: .plays) ?? []
        validationPassed = try container.decodeIfPresent(Bool.self, forKey: .validationPassed) ?? true
        validationErrors = try container.decodeIfPresent([String].self, forKey: .validationErrors) ?? []
        blocks = try container.decodeIfPresent([FlowBlock].self, forKey: .blocks) ?? []
    }

    init(gameId: Int, sport: String? = nil, plays: [FlowPlay] = [], blocks: [FlowBlock] = [],
         validationPassed: Bool = true, validationErrors: [String] = []) {
        self.gameId = gameId
        self.sport = sport
        self.plays = plays
        self.blocks = blocks
        self.validationPassed = validationPassed
        self.validationErrors = validationErrors
    }
}

// MARK: - Score Snapshot

/// Score at a point in time
struct ScoreSnapshot: Codable, Equatable {
    let home: Int
    let away: Int
}
