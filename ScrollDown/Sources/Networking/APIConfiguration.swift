import Foundation

enum APIConfiguration {
    // MARK: - Localhost Configuration

    /// Default port for local development server
    /// Change this to match your local backend's port
    static let localhostPort: Int = 8000

    /// Localhost base URL for simulator testing
    /// Uses `localhost` which works in iOS Simulator
    /// For physical devices, use your machine's IP address instead
    static var localhostURL: String {
        "http://localhost:\(localhostPort)"
    }

    // MARK: - API Key Configuration

    /// Info.plist key for the Sports Data API key
    private static let apiKeyPlistKey = "SPORTS_DATA_API_KEY"

    /// Retrieves the API key for authenticating with the Sports Data API.
    /// The key is read from Info.plist (SPORTS_DATA_API_KEY).
    /// Returns nil for mock environment (no auth needed).
    static func apiKey(for environment: AppEnvironment) -> String? {
        switch environment {
        case .mock:
            // Mock environment doesn't need authentication
            return nil
        case .localhost, .live:
            // Read from Info.plist (set via xcconfig or build settings)
            if let key = Bundle.main.object(forInfoDictionaryKey: apiKeyPlistKey) as? String,
               !key.isEmpty,
               !key.hasPrefix("$") { // Ignore unsubstituted build variables
                return key
            }

            // Check environment variable (useful for development)
            if let key = ProcessInfo.processInfo.environment["SPORTS_DATA_API_KEY"],
               !key.isEmpty {
                return key
            }

            return nil
        }
    }

    // MARK: - URL Resolution

    static func baseURL(for environment: AppEnvironment) -> URL {
        let urlString: String
        switch environment {
        case .mock:
            urlString = "https://mock.scrolldown.sports"
        case .localhost:
            urlString = localhostURL
        case .live:
            // Point to Hetzner server for production data
            urlString = "https://sports-data-admin.dock108.ai"
        }

        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid API base URL: \(urlString)")
        }
        return url
    }
}
