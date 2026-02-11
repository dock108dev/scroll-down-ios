import Foundation

/// Centralized UserDefaults service for app preferences
/// Provides type-safe access to user preferences with clear key management
final class PreferencesService {
    static let shared = PreferencesService()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Keys
    
    private enum Key: String {
        case homeExpandedSections = "homeExpandedSections"
        case hasSeenOnboarding = "hasSeenOnboarding"
        case betaSnapshotEnabled = "betaSnapshotEnabled"
        case betaSnapshotDate = "betaSnapshotDate"
        
        // Per-game preferences (use with game ID)
        case gameReadState = "game_read_"
        case gameBookmarked = "game_bookmarked_"
    }
    
    // MARK: - Home Screen Preferences
    
    var homeExpandedSections: Set<String> {
        get {
            let value = defaults.string(forKey: Key.homeExpandedSections.rawValue) ?? ""
            return Set(value.split(separator: ",").map(String.init))
        }
        set {
            let value = newValue.joined(separator: ",")
            defaults.set(value, forKey: Key.homeExpandedSections.rawValue)
        }
    }
    
    func toggleHomeSection(_ section: String) {
        var sections = homeExpandedSections
        if sections.contains(section) {
            sections.remove(section)
        } else {
            sections.insert(section)
        }
        homeExpandedSections = sections
    }
    
    // MARK: - Onboarding
    
    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasSeenOnboarding.rawValue) }
        set { defaults.set(newValue, forKey: Key.hasSeenOnboarding.rawValue) }
    }
    
    // MARK: - Beta Features
    
    var betaSnapshotEnabled: Bool {
        get { defaults.bool(forKey: Key.betaSnapshotEnabled.rawValue) }
        set { defaults.set(newValue, forKey: Key.betaSnapshotEnabled.rawValue) }
    }
    
    var betaSnapshotDate: Date? {
        get { defaults.object(forKey: Key.betaSnapshotDate.rawValue) as? Date }
        set { defaults.set(newValue, forKey: Key.betaSnapshotDate.rawValue) }
    }
    
    // MARK: - Per-Game Preferences
    
    func isGameRead(_ gameId: Int) -> Bool {
        defaults.bool(forKey: Key.gameReadState.rawValue + "\(gameId)")
    }
    
    func setGameRead(_ gameId: Int, read: Bool) {
        defaults.set(read, forKey: Key.gameReadState.rawValue + "\(gameId)")
    }
    
    func isGameBookmarked(_ gameId: Int) -> Bool {
        defaults.bool(forKey: Key.gameBookmarked.rawValue + "\(gameId)")
    }
    
    func setGameBookmarked(_ gameId: Int, bookmarked: Bool) {
        defaults.set(bookmarked, forKey: Key.gameBookmarked.rawValue + "\(gameId)")
    }
    
    func toggleGameBookmark(_ gameId: Int) {
        let current = isGameBookmarked(gameId)
        setGameBookmarked(gameId, bookmarked: !current)
    }
    
    // MARK: - Bulk Operations
    
    func clearAllGamePreferences() {
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(Key.gameReadState.rawValue) || 
               key.hasPrefix(Key.gameBookmarked.rawValue) {
                defaults.removeObject(forKey: key)
            }
        }
    }
    
    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
    }
}
