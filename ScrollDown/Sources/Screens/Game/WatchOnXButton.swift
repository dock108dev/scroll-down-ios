import SwiftUI

// MARK: - Watch on X Button

/// Standalone button for video posts that lack a direct media URL
struct WatchOnXButton: View {
    let postUrl: String

    @State private var showingSafari = false

    var body: some View {
        Button { showingSafari = true } label: {
            HStack(spacing: 10) {
                // X platform badge
                ZStack {
                    Circle()
                        .fill(Color(.label))
                        .frame(width: 24, height: 24)
                    Text("\u{1D54F}")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.systemBackground))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Watch on X")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    Text("Opens in browser")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Play icon in circular background
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        }
        .buttonStyle(SubtleInteractiveButtonStyle())
        .sheet(isPresented: $showingSafari) {
            if let url = URL(string: postUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}
