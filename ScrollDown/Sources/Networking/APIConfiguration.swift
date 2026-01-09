import Foundation

enum APIConfiguration {
    static func baseURL(for environment: AppEnvironment) -> URL {
        let urlString: String
        switch environment {
        case .mock:
            urlString = "https://mock.scrolldown.sports"
        case .live:
            urlString = "https://api.scrolldown.sports"
        }

        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid API base URL.")
        }
        return url
    }
}
