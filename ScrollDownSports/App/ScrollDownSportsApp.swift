import SwiftUI

@main
struct ScrollDownSportsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let gameStateStore: any GameStateStore

    init() {
        let gameStateStore = UserDefaultsGameStateStore()
        self.gameStateStore = gameStateStore
        BackgroundDataScheduler.shared.gameStateStore = gameStateStore
    }

    var body: some Scene {
        WindowGroup {
            ContentView(gameStateStore: gameStateStore)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                BackgroundDataScheduler.shared.cancelPendingRefresh()
            case .background:
                gameStateStore.prune(now: Date())
                BackgroundDataScheduler.shared.scheduleRefresh()
            default:
                break
            }
        }
    }
}
