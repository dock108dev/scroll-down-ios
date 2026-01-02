import SwiftUI

struct EmptySectionView: View {
    let text: String

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Image(systemName: "tray")
                .foregroundColor(.secondary)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Layout.padding)
        .accessibilityLabel(text)
    }
}

private enum Layout {
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 8
}

#Preview {
    EmptySectionView(text: "No data available.")
        .padding()
        .background(Color(.systemGroupedBackground))
}
