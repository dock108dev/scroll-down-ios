import Foundation

final class GamePreviewService {
    private enum Endpoint {
        static let games = "games"
        static let preview = "preview"
    }

    private let baseURL: URL
    private let session: URLSession

    init(
        baseURL: URL = AppConfig.shared.apiBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchPreview(gameId: String) async throws -> GamePreview {
        let trimmedId = gameId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            throw GamePreviewServiceError.invalidGameId
        }

        let url = baseURL
            .appendingPathComponent(Endpoint.games)
            .appendingPathComponent(trimmedId)
            .appendingPathComponent(Endpoint.preview)

        let request = URLRequest(url: url)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GamePreviewServiceError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try decodePreview(from: data)
            case 404:
                throw GamePreviewServiceError.notFound
            default:
                throw GamePreviewServiceError.unexpectedStatus(httpResponse.statusCode)
            }
        } catch let error as GamePreviewServiceError {
            throw error
        } catch {
            throw GamePreviewServiceError.networkError(error)
        }
    }

    private func decodePreview(from data: Data) throws -> GamePreview {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(GamePreview.self, from: data)
        } catch {
            throw GamePreviewServiceError.decodingError(error)
        }
    }
}

enum GamePreviewServiceError: LocalizedError {
    case invalidGameId
    case notFound
    case invalidResponse
    case unexpectedStatus(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidGameId:
            return "Game ID is required."
        case .notFound:
            return "Game preview not found."
        case .invalidResponse:
            return "Invalid response from server."
        case .unexpectedStatus(let statusCode):
            return "Unexpected status code: \(statusCode)."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}
