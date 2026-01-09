import Foundation

/// Helper for loading mock JSON data from the app bundle
struct MockLoader {
    
    /// Load and decode a JSON file from the bundle
    /// - Parameter file: The filename without extension (e.g., "game-001")
    /// - Returns: Decoded object of type T
    static func load<T: Decodable>(_ file: String) -> T {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
            fatalError("MockLoader: Failed to locate \(file).json in bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("MockLoader: Failed to load \(file).json")
        }
        
        let decoder = JSONDecoder()
        
        guard let decoded = try? decoder.decode(T.self, from: data) else {
            // Try to get more detailed error info
            do {
                _ = try decoder.decode(T.self, from: data)
            } catch {
                fatalError("MockLoader: Failed to decode \(file).json - \(error)")
            }
            fatalError("MockLoader: Failed to decode \(file).json")
        }
        
        return decoded
    }
    
    /// Load and decode a JSON file with Result type for error handling
    /// - Parameter file: The filename without extension
    /// - Returns: Result with decoded object or error
    static func loadResult<T: Decodable>(_ file: String) -> Result<T, Error> {
        guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
            return .failure(MockLoaderError.fileNotFound(file))
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - MockLoader Errors
enum MockLoaderError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let file):
            return "Mock file not found: \(file).json"
        case .decodingFailed(let file, let error):
            return "Failed to decode \(file).json: \(error.localizedDescription)"
        }
    }
}



