import SwiftUI

struct GameHeaderView: View {
    let game: Game

    var body: some View {
        VStack(spacing: Layout.spacing) {
            HStack(spacing: Layout.badgeSpacing) {
                Text(game.status.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.badgeHorizontalPadding)
                    .padding(.vertical, Layout.badgeVerticalPadding)
                    .background(Color.blue.opacity(Layout.badgeBackgroundOpacity))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())

                if let date = game.parsedGameDate {
                    Text(date, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: Layout.teamSpacing) {
                TeamHeaderView(teamName: game.awayTeam, alignment: .leading)
                VStack(spacing: Layout.vsSpacing) {
                    Text("vs")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                TeamHeaderView(teamName: game.homeTeam, alignment: .trailing)
            }
        }
        .padding(Layout.cardPadding)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.systemGray5), lineWidth: Layout.borderWidth)
        )
        .padding(.horizontal, Layout.horizontalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game header")
        .accessibilityValue("\(game.awayTeam) at \(game.homeTeam)")
    }
}

private struct TeamHeaderView: View {
    let teamName: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: Layout.teamTextSpacing) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(Layout.logoOpacity))
                    .frame(width: Layout.logoSize, height: Layout.logoSize)

                Text(initials(for: teamName))
                    .font(.caption.weight(.bold))
                    .foregroundColor(.blue)
            }

            Text(teamName)
                .font(.headline)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private func initials(for name: String) -> String {
        let words = name.split(separator: " ")
        let initials = words.prefix(2).compactMap { $0.first }
        return initials.map { String($0) }.joined()
    }
}

private enum Layout {
    static let spacing: CGFloat = 16
    static let badgeSpacing: CGFloat = 12
    static let badgeHorizontalPadding: CGFloat = 10
    static let badgeVerticalPadding: CGFloat = 6
    static let badgeBackgroundOpacity: CGFloat = 0.15
    static let teamSpacing: CGFloat = 12
    static let teamTextSpacing: CGFloat = 8
    static let vsSpacing: CGFloat = 6
    static let logoSize: CGFloat = 54
    static let logoOpacity: CGFloat = 0.12
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 22
    static let borderWidth: CGFloat = 1
    static let horizontalPadding: CGFloat = 20
}

#Preview {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game)
        .padding()
        .background(Color(.systemGroupedBackground))
}
