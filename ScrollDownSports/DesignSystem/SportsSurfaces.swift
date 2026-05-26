import SwiftUI

struct CatchUpSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .padding(.top, 8)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SportsTheme.Typography.teamName)
                        .foregroundStyle(SportsTheme.Colors.ink)
                    Text(subtitle)
                        .font(SportsTheme.Typography.metadata)
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
            .font(SportsTheme.Typography.momentDetail)
            .foregroundStyle(SportsTheme.Colors.secondaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sportsSurface(.eventCard)
    }
}
