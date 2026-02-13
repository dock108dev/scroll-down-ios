import SwiftUI

// MARK: - Home View Mode

/// Toggle between Recaps (game feed) and Odds (FairBet) in HomeView
enum HomeViewMode: String, CaseIterable, Identifiable {
    case recaps = "Games"
    case odds = "Current Odds"
    case settings = "Settings"

    var id: String { rawValue }
}

// MARK: - Section State

/// Tracks state for each collapsible section in HomeView
struct HomeSectionState: Identifiable {
    let id = UUID()
    let range: GameRange
    let title: String
    var games: [GameSummary] = []
    var isLoading = true
    var errorMessage: String?
    var isExpanded: Bool

    init(range: GameRange, title: String, isExpanded: Bool = true) {
        self.range = range
        self.title = title
        self.isExpanded = isExpanded
    }

    /// Only completed/final games (excludes scheduled and in-progress)
    var completedGames: [GameSummary] {
        games.filter { $0.status?.isCompleted == true }
    }

    /// Number of completed games the user has read (expanded the Wrap Up)
    var readCount: Int {
        games.filter { $0.status?.isCompleted == true && UserDefaults.standard.bool(forKey: "game.read.\($0.id)") }.count
    }
}

/// Result from loading a single section
struct HomeSectionResult {
    let range: GameRange
    let games: [GameSummary]
    let lastUpdatedAt: String?
    let errorMessage: String?
}

// MARK: - Layout Constants

/// Layout constants for HomeView with iPad/iPhone adaptations
enum HomeLayout {
    // Base horizontal padding for iPhone - iPad uses adaptive computed property
    static let horizontalPadding: CGFloat = 16

    static func cardSpacing(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 8 : 12
    }

    static func sectionHeaderTopPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 8 : 12
    }

    static func sectionStatePadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 8 : 12
    }

    static func bottomPadding(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? 24 : 32
    }

    static let filterSpacing: CGFloat = 12
    static let filterHorizontalPadding: CGFloat = 16
    static let filterVerticalPadding: CGFloat = 8
    static let stateSpacing: CGFloat = 16
    static let statePadding: CGFloat = 24
    static let errorIconSize: CGFloat = 48
    static let cardSpacing: CGFloat = 12
    static let sectionHeaderTopPadding: CGFloat = 12
    static let sectionDividerPadding: CGFloat = 8
    static let sectionStatePadding: CGFloat = 12
    static let skeletonSpacing: CGFloat = 12
    static let bottomPadding: CGFloat = 32
    static let freshnessBottomPadding: CGFloat = 8
}

// MARK: - Button Styles

/// Button style with subtle press animation for game cards
struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Strings

/// Localized strings for HomeView
enum HomeStrings {
    static let navigationTitle = "Scroll Down Sports"
    static let allLeaguesLabel = "All"
    static let errorIconName = "exclamationmark.triangle"
    static let errorTitle = "Error"
    static let retryLabel = "Retry"
    static let sectionEarlier = "Earlier"
    static let sectionYesterday = "Yesterday"
    static let sectionToday = "Today"
    static let sectionUpcoming = "Coming Up"
    static let sectionTomorrow = "Tomorrow"
    static let sectionLoading = "Loading section..."
    static let earlierEmpty = "No games from earlier."
    static let yesterdayEmpty = "No games from yesterday."
    static let todayEmpty = "No games scheduled for today."
    static let tomorrowEmpty = "No games scheduled for tomorrow."
    static let upcomingEmpty = "No games scheduled in the next 24 hours."
    static let updatedTemplate = "Updated %@"
    static let updateUnavailable = "Update time unavailable"
    static let globalErrorMessage = "We couldn't reach the latest game feeds."
    static let earlierError = "Earlier games unavailable. %@"
    static let yesterdayError = "Yesterday's games unavailable. %@"
    static let todayError = "Today's games unavailable. %@"
    static let tomorrowError = "Tomorrow's games unavailable. %@"
    static let upcomingError = "Coming up games unavailable. %@"
}

// MARK: - Date Formatters

let homeDateFormatterWithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

let homeDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

// MARK: - Notifications

extension Notification.Name {
    static let scrollToYesterday = Notification.Name("scrollToYesterday")
}
