import SwiftUI

struct GameHeaderView: View {
    let game: Game
    let scoreRevealed: Bool

    var body: some View {
        VStack(spacing: Layout.spacing) {
            HStack(spacing: Layout.badgeSpacing) {
                Text(game.status.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, Layout.badgeHorizontalPadding)
                    .padding(.vertical, Layout.badgeVerticalPadding)
                    .background(GameTheme.accentColor.opacity(Layout.badgeBackgroundOpacity))
                    .foregroundColor(GameTheme.accentColor)
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

            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Layout.cardPadding)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(GameTheme.cardBorder, lineWidth: Layout.borderWidth)
        )
        .shadow(
            color: GameTheme.cardShadow,
            radius: Layout.shadowRadius,
            x: 0,
            y: Layout.shadowYOffset
        )
        .padding(.horizontal, Layout.horizontalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game header")
        .accessibilityValue("\(game.awayTeam) at \(game.homeTeam), \(statusDescription)")
    }

    private var statusDescription: String {
        switch game.status {
        case .completed:
            return scoreRevealed ? "Final score below" : "Game complete"
        case .scheduled:
            return "Not started"
        case .inProgress:
            return "In progress"
        case .postponed:
            return "Postponed"
        case .canceled:
            return "Canceled"
        }
    }
}

private struct TeamHeaderView: View {
    let teamName: String
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: Layout.teamTextSpacing) {
            ZStack {
                Circle()
                    .fill(GameTheme.accentColor.opacity(Layout.logoOpacity))
                    .frame(width: Layout.logoSize, height: Layout.logoSize)

                Text(initials(for: teamName))
                    .font(.caption.weight(.bold))
                    .foregroundColor(GameTheme.accentColor)
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
    static let shadowRadius: CGFloat = 10
    static let shadowYOffset: CGFloat = 4
}

#Preview {
    GameHeaderView(game: PreviewFixtures.highlightsHeavyGame.game, scoreRevealed: false)
        .padding()
        .background(Color(.systemGroupedBackground))
}
