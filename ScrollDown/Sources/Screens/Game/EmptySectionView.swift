import SwiftUI

/// Empty state view with calm, intentional design.
/// Empty ≠ broken. Absence of content feels intentional.
/// Rules: No error language, no icons, subdued text style.
struct EmptySectionView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .accessibilityLabel(text)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptySectionView(text: "Nothing here yet.")
        EmptySectionView(text: "Pregame posts will appear here.")
        EmptySectionView(text: "Stats available after the game.")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
