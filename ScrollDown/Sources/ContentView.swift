import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appConfig: AppConfig
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: GameSummary.self) { game in
                    GameDetailView(gameId: game.id)
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .game(let id):
                        GameDetailView(gameId: id)
                    case .deepLinkPlaceholder(let value):
                        DeepLinkPlaceholderView(value: value)
                    }
                }
        }
    }
}

enum AppRoute: Hashable {
    case game(id: Int)
    case deepLinkPlaceholder(String)
}

private struct DeepLinkPlaceholderView: View {
    let value: String

    var body: some View {
        VStack(spacing: Layout.spacing) {
            Image(systemName: Layout.iconName)
                .font(.system(size: Layout.iconSize))
                .foregroundColor(.secondary)
            Text(Layout.title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Layout.padding)
        .navigationTitle(Layout.navigationTitle)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Layout.accessibilityLabel)
    }
}

private enum Layout {
    static let spacing: CGFloat = 16
    static let iconSize: CGFloat = 48
    static let padding: CGFloat = 24
    static let iconName = "link"
    static let title = "Deep Link Placeholder"
    static let navigationTitle = "Deep Link"
    static let accessibilityLabel = "Deep link placeholder screen"
}

#Preview {
    ContentView()
        .environmentObject(AppConfig.shared)
}

