import SwiftUI

struct TimelineScoreChipView: View {
    let marker: GameDetailViewModel.TimelineScoreMarker

    var body: some View {
        HStack(spacing: Layout.spacing) {
            Text(marker.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(marker.score)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.vertical, Layout.verticalPadding)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(.systemGray4), lineWidth: Layout.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(marker.label)
        .accessibilityValue(marker.score)
    }
}

private enum Layout {
    static let spacing: CGFloat = 6
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 6
    static let borderWidth: CGFloat = 1
}

#Preview {
    TimelineScoreChipView(
        marker: GameDetailViewModel.TimelineScoreMarker(
            id: "preview",
            label: "Halftime",
            score: "45 - 48"
        )
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
