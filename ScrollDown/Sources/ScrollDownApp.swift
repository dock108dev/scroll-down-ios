import SwiftUI

@main
struct ScrollDownApp: App {
    @StateObject private var appConfig = AppConfig.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appConfig)
                .tint(HomeTheme.accentColor)
        }
    }
}


