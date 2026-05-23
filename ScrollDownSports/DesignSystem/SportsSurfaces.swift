import SwiftUI

struct ScoreRow: View {
    let team: String
    let abbreviation: String?
    let score: Int?
    var scoreText: String? = nil

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(abbreviation ?? team)
                    .font(SportsTheme.Typography.teamName)
                    .foregroundStyle(SportsTheme.Team.accent(for: abbreviation, fallback: SportsTheme.Tone.scoreboard.accent))
                Text(team)
                    .font(.caption)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
            Spacer()
            Text(scoreText ?? score.map(String.init) ?? "-")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SportsTheme.Colors.ink)
                .monospacedDigit()
        }
    }
}

struct CatchUpSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(SportsTheme.Typography.sectionTitle)
                .foregroundStyle(SportsTheme.Colors.ink)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CollapsibleCatchUpSection<Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content
                .padding(.top, 10)
        } label: {
            Label(title, systemImage: systemImage)
                .font(SportsTheme.Typography.sectionTitle)
                .foregroundStyle(SportsTheme.Colors.ink)
        }
        .sportsSurface(.statSummary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel(title)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint("Shows or hides \(title.lowercased()).")
    }
}

struct StatCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SportsTheme.Colors.ink)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                }
                Spacer()
            }
            content
        }
        .sportsSurface(.statSummary)
    }
}

struct StatPills: View {
    let items: [(String, String)]

    var body: some View {
        if items.isEmpty {
            UnavailableText("Stats unavailable.")
        } else {
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.0) { label, value in
                    SportsCompactTableRow(label: label, value: value)
                }
            }
        }
    }
}

struct UnavailableText: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sportsSurface(.eventCard)
    }
}
