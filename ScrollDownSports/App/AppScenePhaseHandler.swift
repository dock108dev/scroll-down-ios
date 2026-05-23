import SwiftUI

@MainActor
protocol BackgroundRefreshScheduling: AnyObject {
    func scheduleRefresh()
    func cancelPendingRefresh()
}

@MainActor
struct AppScenePhaseHandler {
    let gameStateStore: any GameStateStore
    let scheduler: any BackgroundRefreshScheduling
    let now: () -> Date

    func handle(_ phase: ScenePhase) {
        switch phase {
        case .active:
            scheduler.cancelPendingRefresh()
        case .background:
            gameStateStore.prune(now: now())
            scheduler.scheduleRefresh()
        default:
            break
        }
    }
}
