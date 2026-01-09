import Foundation

/// Backend-defined snapshot windows for home feed sections.
enum GameRange: String, CaseIterable {
    case last2
    case current
    case next24
}
