import Foundation
import UIKit
import OSLog

/// Singleton cache for team colors.
/// Fetches `GET /api/admin/sports/teams` on app launch, stores in memory + UserDefaults (7-day TTL).
/// Falls back to `.systemIndigo` for unknown teams or before colors are fetched.
///
/// The color store uses `nonisolated(unsafe)` to allow synchronous reads from any context
/// (needed by SwiftUI view bodies). Writes only happen on MainActor (loadCachedOrFetch).
final class TeamColorCache {
    static let shared = TeamColorCache()

    private let logger = Logger(subsystem: "com.scrolldown.app", category: "teamColors")
    private static let cacheKey = "teamColorCache"
    private static let cacheTimestampKey = "teamColorCacheTimestamp"
    private static let ttlSeconds: TimeInterval = 7 * 24 * 60 * 60 // 7 days

    /// In-memory color store: teamName -> (lightHex, darkHex)
    /// nonisolated(unsafe) allows synchronous reads from SwiftUI view bodies.
    /// Only written during init (from disk) or from loadCachedOrFetch (MainActor, at launch).
    nonisolated(unsafe) private var colorStore: [String: (lightHex: String, darkHex: String)] = [:]

    private init() {
        // Pre-load from disk at init so colors are available immediately
        loadFromDisk()
    }

    // MARK: - Public API

    /// Load cached colors or fetch from server
    @MainActor
    func loadCachedOrFetch(service: GameService) async {
        if !colorStore.isEmpty {
            logger.info("Team colors already loaded (\(self.colorStore.count) teams)")
            return
        }

        // Fetch from server
        await fetchFromServer(service: service)
    }

    /// Get color pair for a team name (synchronous, safe from any context)
    func color(for teamName: String) -> (light: UIColor, dark: UIColor)? {
        // Exact match
        if let hex = colorStore[teamName] {
            return (light: UIColor(hex: hex.lightHex), dark: UIColor(hex: hex.darkHex))
        }

        // Prefix match (e.g., "Iowa Hawkeyes" -> "Iowa")
        let sortedKeys = colorStore.keys.sorted { $0.count > $1.count }
        if let key = sortedKeys.first(where: { teamName.hasPrefix($0) }),
           let hex = colorStore[key] {
            return (light: UIColor(hex: hex.lightHex), dark: UIColor(hex: hex.darkHex))
        }

        return nil
    }

    // MARK: - Private

    @MainActor
    private func fetchFromServer(service: GameService) async {
        do {
            let teams = try await service.fetchTeamColors()
            var store: [String: (lightHex: String, darkHex: String)] = [:]
            for team in teams {
                if let light = team.colorLightHex, let dark = team.colorDarkHex {
                    store[team.name] = (lightHex: light, darkHex: dark)
                }
            }
            self.colorStore = store
            saveToDisk(store)
            logger.info("Team colors fetched from server (\(store.count) teams)")
        } catch {
            logger.error("Failed to fetch team colors: \(error.localizedDescription)")
        }
    }

    @discardableResult
    private func loadFromDisk() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date else {
            return false
        }

        // Check TTL
        if Date().timeIntervalSince(timestamp) > Self.ttlSeconds {
            return false
        }

        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let decoded = try? JSONDecoder().decode([String: CachedColor].self, from: data) else {
            return false
        }

        colorStore = decoded.mapValues { (lightHex: $0.light, darkHex: $0.dark) }
        return !colorStore.isEmpty
    }

    private func saveToDisk(_ store: [String: (lightHex: String, darkHex: String)]) {
        let encodable = store.mapValues { CachedColor(light: $0.lightHex, dark: $0.darkHex) }
        if let data = try? JSONEncoder().encode(encodable) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
            UserDefaults.standard.set(Date(), forKey: Self.cacheTimestampKey)
        }
    }
}

// MARK: - Cached Color Model

private struct CachedColor: Codable {
    let light: String
    let dark: String
}

// MARK: - Team Summary (from GET /teams)

struct TeamSummary: Codable {
    let name: String
    let colorLightHex: String?
    let colorDarkHex: String?

    enum CodingKeys: String, CodingKey {
        case name
        case colorLightHex = "color_light_hex"
        case colorDarkHex = "color_dark_hex"
    }
}

// MARK: - UIColor hex init

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: CGFloat
        switch hex.count {
        case 6:
            r = CGFloat((int >> 16) & 0xFF) / 255
            g = CGFloat((int >> 8) & 0xFF) / 255
            b = CGFloat(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
