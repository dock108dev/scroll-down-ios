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
