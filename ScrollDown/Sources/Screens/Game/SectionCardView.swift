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
