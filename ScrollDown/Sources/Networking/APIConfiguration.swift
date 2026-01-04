import Foundation

enum APIConfiguration {
    static let baseURL: URL = {
        guard let url = URL(string: "https://api.scrolldown.sports") else {
            preconditionFailure("Invalid API base URL.")
        }
        return url
    }()
}
