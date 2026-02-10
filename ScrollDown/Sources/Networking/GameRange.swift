import Foundation

/// Backend-defined snapshot windows for home feed sections.
enum GameRange: String, CaseIterable {
    case earlier    // 2+ days ago
    case yesterday  // 1 day ago
    case current    // today
    case tomorrow   // tomorrow
    case next24     // upcoming 24 hours
}
