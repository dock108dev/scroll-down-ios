import SwiftUI

/// Empty state view with clear, neutral messaging
/// Phase F: Intentional empty states that explain why content is absent
struct EmptySectionView: View {
    let text: String
    let icon: String
    
    init(text: String, icon: String = "tray") {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            Image(systemName: icon)
                .font(.system(size: Layout.iconSize))
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .accessibilityLabel(text)
    }
}

private enum Layout {
    static let contentSpacing: CGFloat = 12
    static let iconSize: CGFloat = 32
    static let verticalPadding: CGFloat = 24
    static let horizontalPadding: CGFloat = 20
}

#Preview {
    VStack(spacing: 20) {
        EmptySectionView(text: "No games in this window yet")
        EmptySectionView(text: "This game doesn't have play-by-play available", icon: "list.bullet.clipboard")
        EmptySectionView(text: "Updates are still coming in", icon: "clock")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
