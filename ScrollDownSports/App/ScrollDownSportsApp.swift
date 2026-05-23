import SwiftUI

@main
struct ScrollDownSportsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    private let gameStateStore: any GameStateStore
    private let scenePhaseHandler: AppScenePhaseHandler

    init() {
        let gameStateStore: any GameStateStore
        #if DEBUG
        if AppEnvironment.isRunningUITests {
            let initialState = AppEnvironment.shouldResetStateForUITests ? LocalGameStateSnapshot.empty(now: Date()) : nil
            gameStateStore = InMemoryGameStateStore(initial: initialState)
        } else {
            gameStateStore = UserDefaultsGameStateStore()
        }
        #else
        gameStateStore = UserDefaultsGameStateStore()
        #endif
        self.gameStateStore = gameStateStore
        BackgroundDataScheduler.shared.gameStateStore = gameStateStore
        self.scenePhaseHandler = AppScenePhaseHandler(
            gameStateStore: gameStateStore,
            scheduler: BackgroundDataScheduler.shared,
            now: Date.init
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(gameStateStore: gameStateStore)
                .uiTestDynamicTypeOverride()
        }
        .onChange(of: scenePhase) { _, phase in
            scenePhaseHandler.handle(phase)
        }
    }
}

private extension View {
    @ViewBuilder
    func uiTestDynamicTypeOverride() -> some View {
        if let size = AppEnvironment.uiTestDynamicTypeSize {
            environment(\.dynamicTypeSize, size)
        } else {
            self
        }
    }
}
