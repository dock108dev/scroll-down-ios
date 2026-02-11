import Foundation
import OSLog

/// Environment for switching between mock, localhost, and live data sources.
enum AppEnvironment: String, CaseIterable {
    case mock
    case localhost
    case live
    
    var displayName: String {
        switch self {
        case .mock: return "Mock Data"
        case .localhost: return "Localhost"
        case .live: return "Live API"
        }
    }
    
    /// Whether this environment uses network calls
    var usesNetwork: Bool {
        switch self {
        case .mock: return false
        case .localhost, .live: return true
        }
    }
}

enum FeatureFlags {
    /// Set to true to default to localhost on app launch (DEBUG only)
    /// Useful for local development sessions—change this instead of using Admin Settings each time
    /// NOTE: Requires local server running on port \(APIConfiguration.localhostPort)
    static let defaultToLocalhost: Bool = false

    /// Show play/moment counts on game cards (debug info)
    static let showCardPlayCounts: Bool = true
}

// MARK: - Dev Clock

/// Centralized date provider for consistent time handling
/// Beta Admin Feature: Supports time override via TimeService
///
/// Priority order:
/// 1. TimeService override (if set) - for beta testing historical data
/// 2. Mock mode dev date (if in mock mode) - for development
/// 3. Real system time (default)
///
/// WHY THIS EXISTS:
/// - Single source of truth for "now" throughout the app
/// - Enables deterministic testing of historical data
/// - No view/viewmodel should call Date() directly for logic
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
    
    /// Returns the current date based on priority:
    /// 1. TimeService override (beta testing)
    /// 2. Dev date (mock mode)
    /// 3. Real time (live mode)
    static func now() -> Date {
        // Beta admin: TimeService override takes precedence
        if TimeService.shared.isSnapshotModeActive {
            return TimeService.shared.now
        }
        
        // Development: mock mode uses fixed date
        if AppConfig.shared.environment == .mock {
            return devDate
        }
        
        // Production: real system time
        return Date()
    }
    
    /// EST calendar for game date calculations (US sports assumption)
    private static var estCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }

    /// Start of today based on AppDate.now() in EST
    static var startOfToday: Date {
        estCalendar.startOfDay(for: now())
    }

    /// End of today (23:59:59) based on AppDate.now() in EST
    static var endOfToday: Date {
        estCalendar.date(byAdding: .day, value: 1, to: startOfToday)!.addingTimeInterval(-1)
    }

    /// Start of the history window (2 days ago) in EST
    static var historyWindowStart: Date {
        estCalendar.date(byAdding: .day, value: -2, to: startOfToday)!
    }

    /// Start of tomorrow in EST
    static var startOfTomorrow: Date {
        estCalendar.date(byAdding: .day, value: 1, to: startOfToday)!
    }
}

/// App-wide configuration singleton
final class AppConfig: ObservableObject {
    static let shared = AppConfig()
    
    /// Current data mode - always use live API
    /// Production database is active with non-proprietary sports data
    @Published var environment: AppEnvironment = .live {
        didSet {
            // Clear cached services when environment changes
            if oldValue != environment {
                invalidateServices()
            }
        }
    }
    
    /// Stored services to ensure consistency (especially for mock data)
    private var _mockService: MockGameService?
    private var _realService: RealGameService?
    private var _localhostService: RealGameService?
    
    /// Clear cached services (called when environment changes)
    private func invalidateServices() {
        _realService = nil
        _localhostService = nil
        // Keep mock service as it doesn't depend on URL
    }
    
    /// Returns the appropriate GameService based on current data mode
    var gameService: any GameService {
        switch environment {
        case .mock:
            if _mockService == nil {
                _mockService = MockGameService()
            }
            return _mockService!
        case .localhost:
            if _localhostService == nil {
                _localhostService = RealGameService(
                    baseURL: apiBaseURL,
                    apiKey: APIConfiguration.apiKey(for: environment)
                )
            }
            return _localhostService!
        case .live:
            if _realService == nil {
                _realService = RealGameService(
                    baseURL: apiBaseURL,
                    apiKey: APIConfiguration.apiKey(for: environment)
                )
            }
            return _realService!
        }
    }

    /// Single source of truth for the API base URL.
    var apiBaseURL: URL {
        APIConfiguration.baseURL(for: environment)
    }
    
    /// Beta Admin: Whether snapshot mode is active
    var isSnapshotModeActive: Bool {
        TimeService.shared.isSnapshotModeActive
    }
    
    /// Beta Admin: Filter games for snapshot mode
    /// In snapshot mode:
    /// - Only show completed and scheduled games
    /// - Exclude all live/in-progress games
    /// - This ensures deterministic replay without partial data
    func filterGamesForSnapshotMode(_ games: [GameSummary]) -> [GameSummary] {
        guard isSnapshotModeActive else {
            return games // Normal mode: show all games
        }
        
        // Snapshot mode: exclude live games
        let filtered = games.filter { game in
            guard let status = game.status else {
                return false
            }
            
            switch status {
            case .completed, .final, .scheduled, .postponed, .canceled:
                return true // Safe for snapshot mode
            case .inProgress:
                return false // Exclude live games
            }
        }

        // Log filtering if games were excluded
        if filtered.count < games.count {
            let excluded = games.count - filtered.count
            Logger(subsystem: "com.scrolldown.app", category: "config")
                .info("⏰ Snapshot mode: excluded \(excluded) live/unknown games")
        }
        
        return filtered
    }
    
    private init() {}
}

