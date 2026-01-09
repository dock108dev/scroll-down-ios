import Foundation

/// Environment for switching between mock and live data sources.
enum AppEnvironment: String, CaseIterable {
    case mock
    case live
    
    var displayName: String {
        switch self {
        case .mock: return "Mock Data"
        case .live: return "Live API"
        }
    }
}

enum FeatureFlags {
    static let enableGamePreviewScores: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}

// MARK: - Dev Clock

/// Centralized date provider for consistent time handling
/// In mock mode: always returns Nov 12, 2024 at noon
/// In API mode: returns real system time
enum AppDate {
    /// The fixed dev date: November 12, 2024 at 12:00 PM
    private static let devDate: Date = {
        var components = DateComponents()
        components.year = 2024
        components.month = 11
        components.day = 12
        components.hour = 12
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Returns the current date based on data mode
    static func now() -> Date {
        AppConfig.shared.environment == .mock ? devDate : Date()
    }
    
    /// Start of today based on AppDate.now()
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: now())
    }
    
    /// End of today (23:59:59) based on AppDate.now()
    static var endOfToday: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
    }
    
    /// Start of the history window (2 days ago)
    static var historyWindowStart: Date {
        Calendar.current.date(byAdding: .day, value: -2, to: startOfToday)!
    }
    
    /// Start of tomorrow
    static var startOfTomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!
    }
}

/// App-wide configuration singleton
final class AppConfig: ObservableObject {
    static let shared = AppConfig()
    
    /// Current data mode - defaults to mock for development
    @Published var environment: AppEnvironment = .mock
    
    /// Returns the appropriate GameService based on current data mode
    var gameService: any GameService {
        switch environment {
        case .mock:
            return MockGameService()
        case .live:
            return RealGameService(baseURL: apiBaseURL)
        }
    }

    /// Single source of truth for the API base URL.
    var apiBaseURL: URL {
        APIConfiguration.baseURL(for: environment)
    }
    
    private init() {}
}

