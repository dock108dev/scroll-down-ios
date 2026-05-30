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
    let collapsedSummary: String?
    let expandedSummary: String?
    let expandButtonTitle: String
    let collapseButtonTitle: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: Content

    init(
        title: String,
        systemImage: String,
        collapsedSummary: String? = nil,
        expandedSummary: String? = nil,
        expandButtonTitle: String = "Show",
        collapseButtonTitle: String = "Hide",
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.collapsedSummary = collapsedSummary
        self.expandedSummary = expandedSummary
        self.expandButtonTitle = expandButtonTitle
        self.collapseButtonTitle = collapseButtonTitle
        _isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                SportsFeedback.selection()
                withAnimation(.snappy(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Label(title, systemImage: systemImage)
                        .font(SportsTheme.Typography.sectionTitle)
                        .foregroundStyle(SportsTheme.Colors.ink)
                    Spacer(minLength: 8)
                    Label(actionTitle, systemImage: isExpanded ? "chevron.up" : "chevron.down")
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .labelStyle(.titleAndIcon)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(actionAccessibilityLabel)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if let summaryText {
                Text(summaryText)
                    .font(SportsTheme.Typography.momentDetail)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isExpanded {
                content
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sportsSurface(.statSummary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint("Shows or hides \(title.lowercased()).")
    }

    private var actionTitle: String {
        isExpanded ? collapseButtonTitle : expandButtonTitle
    }

    private var summaryText: String? {
        isExpanded ? expandedSummary : collapsedSummary
    }

    private var actionAccessibilityLabel: String {
        isExpanded ? "Hide \(title.lowercased())" : "Show \(title.lowercased())"
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
