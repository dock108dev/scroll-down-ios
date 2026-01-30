import SwiftUI

/// Team page displaying team information and recent games
/// Preserves league context for proper data filtering
struct TeamView: View {
    let teamName: String
    let abbreviation: String
    let leagueCode: String

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Team Header
                VStack(spacing: 8) {
                    Text(abbreviation)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(DesignSystem.TextColor.primary)

                    Text(teamName)
                        .font(.title3.weight(.medium))
                        .foregroundColor(DesignSystem.TextColor.secondary)

                    Text(leagueCode)
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
                        )
                }
                .padding(.top, 32)

                // Placeholder for future content
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 40))
                        .foregroundColor(Color(.tertiaryLabel))

                    Text("Recent Games")
                        .font(.headline)
                        .foregroundColor(DesignSystem.TextColor.secondary)

                    Text("Team schedule coming soon")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(DesignSystem.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
                .shadow(
                    color: DesignSystem.Shadow.color,
                    radius: DesignSystem.Shadow.radius,
                    x: 0,
                    y: DesignSystem.Shadow.y
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(teamName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TeamView(teamName: "Colorado Avalanche", abbreviation: "COL", leagueCode: "NHL")
    }
}

#Preview("NBA Team") {
    NavigationStack {
        TeamView(teamName: "Boston Celtics", abbreviation: "BOS", leagueCode: "NBA")
    }
}
