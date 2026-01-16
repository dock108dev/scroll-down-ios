import SwiftUI

// MARK: - Collapsible Section Card

/// A card that expands/collapses to show content with a title header.
/// Used for major sections in the game detail view.
struct CollapsibleSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let collapsedTitle: String?
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        collapsedTitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.collapsedTitle = collapsedTitle
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // Tightened from 14
            Button(action: toggle) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        if let collapsedTitle, !isExpanded {
                            Text(collapsedTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(DesignSystem.TextColor.primary)
                        } else {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(DesignSystem.TextColor.primary)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(DesignSystem.TextColor.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .sectionCard()
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Collapsible Quarter Card

/// A smaller collapsible card used for quarter sections within the timeline.
struct CollapsibleQuarterCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    init(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.elementPadding)
        .padding(.vertical, 8) // Tightened
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .shadow(
            color: DesignSystem.Shadow.color,
            radius: DesignSystem.Shadow.subtleRadius,
            x: 0,
            y: DesignSystem.Shadow.subtleY
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Layout Constants

private enum CardLayout {
    static let sectionSpacing: CGFloat = 20
    static let listSpacing: CGFloat = 8
    static let horizontalPadding: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16
    static let borderWidth: CGFloat = 1
    static let shadowRadius: CGFloat = 10
    static let shadowYOffset: CGFloat = 4
    static let headerSpacing: CGFloat = 12
    static let subtitleSpacing: CGFloat = 4
}



