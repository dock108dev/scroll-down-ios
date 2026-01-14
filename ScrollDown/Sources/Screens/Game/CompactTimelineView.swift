import SwiftUI

/// DEPRECATED: This view used the old CompactMoment-based approach
/// Compact mode is now implemented as layout density changes in UnifiedTimelineRowView
/// This file is kept for reference but should be deleted when cleanup is complete
@available(*, deprecated, message: "Use UnifiedTimelineRowView with isCompact instead")
struct CompactTimelineView: View {
    let moments: [CompactMoment]
    let status: GameStatus?
    var onSelect: ((CompactMoment) -> Void)?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: Layout.rowSpacing) {
            if let statusText {
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, Layout.horizontalPadding)
                    .padding(.top, Layout.headerTopPadding)
            }

            ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                Button {
                    onSelect?(moment)
                } label: {
                    CompactTimelineRow(moment: moment, index: index + 1)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Layout.horizontalPadding)
            }

            if moments.isEmpty {
                EmptySectionView(text: "Timeline will appear here as the game unfolds.")
                    .padding(.horizontal, Layout.horizontalPadding)
            }
        }
        .padding(.bottom, Layout.bottomPadding)
    }

    private var statusText: String? {
        switch status {
        case .inProgress:
            return "Live"
        case .completed, .final:
            return "Final"
        default:
            return nil
        }
    }
}

private struct CompactTimelineRow: View {
    let moment: CompactMoment
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: Layout.rowContentSpacing) {
            VStack(alignment: .leading, spacing: Layout.textSpacing) {
                Text(moment.displayTitle)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let player = moment.playerName {
                    Text(player)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let team = moment.teamAbbreviation {
                    Text(team)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let timeLabel = moment.timeLabel {
                Text(timeLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(Layout.rowPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: Layout.borderWidth)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timeline event")
        .accessibilityValue(moment.displayTitle)
    }
}

private enum Layout {
    static let rowSpacing: CGFloat = 12
    static let rowContentSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 4
    static let rowPadding: CGFloat = 12
    static let horizontalPadding: CGFloat = 4
    static let bottomPadding: CGFloat = 8
    static let cornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
    static let headerTopPadding: CGFloat = 4
}

#Preview {
    let moments = PreviewFixtures.highlightsHeavyGame.compactMoments
        ?? PreviewFixtures.highlightsHeavyGame.plays.map { CompactMoment(play: $0) }
    CompactTimelineView(moments: moments, status: .completed)
        .padding()
        .background(Color(.systemGroupedBackground))
}
