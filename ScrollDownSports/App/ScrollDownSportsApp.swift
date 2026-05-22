import SwiftUI

@main
struct ScrollDownSportsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                BackgroundDataScheduler.shared.cancelPendingRefresh()
            case .background:
                BackgroundDataScheduler.shared.scheduleRefresh()
            default:
                break
            }
        }
    }
}

