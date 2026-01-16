import SwiftUI

/// Empty state view with calm, intentional messaging
/// Confident tone - states facts without apologizing
struct EmptySectionView: View {
    let text: String
    let icon: String
    
    init(text: String, icon: String = "ellipsis") {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(.tertiaryLabel))
            
            Text(text)
                .font(.footnote)
                .foregroundColor(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .accessibilityLabel(text)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptySectionView(text: "Nothing here yet")
        EmptySectionView(text: "Play-by-play not available", icon: "list.bullet")
        EmptySectionView(text: "Still loading", icon: "clock")
    }
        .padding()
        .background(Color(.systemGroupedBackground))
}
