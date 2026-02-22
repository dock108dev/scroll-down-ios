import SwiftUI

struct SectionCardView<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            VStack(alignment: .leading, spacing: Layout.subtitleSpacing) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            content
        }
        .sectionCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

struct SectionCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.card))
            .shadow(
                color: DesignSystem.Shadow.color,
                radius: DesignSystem.Shadow.radius,
                x: 0,
                y: DesignSystem.Shadow.y
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.card)
                    .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: DesignSystem.borderWidth)
            )
    }
}

extension View {
    func sectionCard() -> some View {
        modifier(SectionCardModifier())
    }

    /// Card body styling for content below a `PinnedSectionHeader`.
    /// Rounds only the bottom corners so header + body form a connected card.
    func sectionCardBody() -> some View {
        modifier(SectionCardBodyModifier())
    }
}

struct SectionCardBodyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.cardPadding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: DesignSystem.Radius.card,
                bottomTrailingRadius: DesignSystem.Radius.card,
                topTrailingRadius: 0
            ))
            .shadow(
                color: DesignSystem.Shadow.color,
                radius: DesignSystem.Shadow.radius,
                x: 0,
                y: DesignSystem.Shadow.y
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: DesignSystem.Radius.card,
                    bottomTrailingRadius: DesignSystem.Radius.card,
                    topTrailingRadius: 0
                )
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: DesignSystem.borderWidth)
            )
    }
}

private enum Layout {
    static let spacing: CGFloat = 10
    static let subtitleSpacing: CGFloat = 2
    static let padding: CGFloat = 14
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 4
    static let shadowYOffset: CGFloat = 1
}

#Preview {
    SectionCardView(title: "Preview", subtitle: "Subtitle") {
        Text("Card content")
            .font(.subheadline)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
