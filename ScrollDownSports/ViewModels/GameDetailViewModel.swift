import Foundation

@MainActor
final class GameDetailViewModel: ObservableObject {
    @Published var detail: GameDetailResponse?
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    let gameId: Int
    private let apiClient: SDAApiClient
    private var refreshTask: Task<Void, Never>?

    init(gameId: Int, apiClient: SDAApiClient = .shared) {
        self.gameId = gameId
        self.apiClient = apiClient
    }

    func refresh(silent: Bool = false) async {
        if !silent {
            loading = true
        }
        errorMessage = nil
        do {
            detail = try await apiClient.fetchGame(id: gameId)
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5 * 60))
                await self?.refresh(silent: true)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}

