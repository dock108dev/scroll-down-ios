import SwiftUI

struct TimelineRowView: View {
    let play: PlayEntry

    var body: some View {
        HStack(alignment: .top, spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.timeSpacing) {
                Text(play.gameClock ?? "--")
                    .font(.caption.weight(.semibold))
                Text("Q\(play.quarter ?? 0)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: Layout.timeWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: Layout.descriptionSpacing) {
                Text(play.description ?? "Play update")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                if let player = play.playerName {
                    Text(player)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let team = play.teamAbbreviation {
                    Text(team)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(Layout.padding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: Layout.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timeline event")
        .accessibilityValue(play.description ?? "Update")
    }
}

private enum Layout {
    static let spacing: CGFloat = 12
    static let timeSpacing: CGFloat = 4
    static let timeWidth: CGFloat = 48
    static let descriptionSpacing: CGFloat = 4
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
}

#Preview {
    TimelineRowView(play: PreviewFixtures.highlightsHeavyGame.plays.first ?? PreviewFixtures.highlightsHeavyGame.plays[0])
        .padding()
        .background(Color(.systemGroupedBackground))
}
