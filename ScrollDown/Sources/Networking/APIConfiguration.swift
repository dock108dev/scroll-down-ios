import Foundation

enum APIConfiguration {
    static func baseURL(for environment: AppEnvironment) -> URL {
        let urlString: String
        switch environment {
        case .mock:
            urlString = "https://mock.scrolldown.sports"
        case .live:
            // Point to Hetzner server for production data
            urlString = "https://sports-data-admin.dock108.ai"
        }

        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid API base URL.")
        }
        return url
    }
}
