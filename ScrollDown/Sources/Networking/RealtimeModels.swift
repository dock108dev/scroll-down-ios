//
//  RealtimeModels.swift
//  ScrollDown
//
//  WebSocket event types for realtime updates.
//

import Foundation

// MARK: - Incoming Events

struct RealtimeEvent: Codable {
    let type: String
    let channel: String
    let ts: Double
    let seq: Int
    let gameId: String?

    enum CodingKeys: String, CodingKey {
        case type, channel, ts, seq
        case gameId = "game_id"
    }
}

struct GamePatchEvent: Codable {
    let type: String
    let channel: String
    let ts: Double
    let seq: Int
    let gameId: String
    let patch: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case type, channel, ts, seq
        case gameId = "game_id"
        case patch
    }
}

// MARK: - Channel Helpers

enum RealtimeChannel {
    static func gameList(league: String = "all", date: String) -> String {
        "games:\(league):\(date)"
    }

    static func gameSummary(gameId: Int) -> String {
        "game:\(gameId):summary"
    }

    static func gamePbp(gameId: Int) -> String {
        "game:\(gameId):pbp"
    }

    static func fairbet() -> String {
        "fairbet:odds"
    }
}
