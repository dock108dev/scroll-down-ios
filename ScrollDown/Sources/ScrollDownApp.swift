import SwiftUI

@main
struct ScrollDownApp: App {
    @StateObject private var appConfig = AppConfig.shared
    @StateObject private var readStateStore = ReadStateStore.shared
    @StateObject private var authViewModel = AuthViewModel.shared
    @AppStorage("appTheme") private var appTheme = "system"

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appConfig)
                .environmentObject(readStateStore)
                .environmentObject(authViewModel)
                .preferredColorScheme(colorScheme)
                .tint(GameTheme.accentColor)
                .task {
                    await TeamColorCache.shared.loadCachedOrFetch(service: appConfig.gameService)
                    await authViewModel.validateSession()
                    RealtimeService.shared.connect()
                }
        }
    }
}


