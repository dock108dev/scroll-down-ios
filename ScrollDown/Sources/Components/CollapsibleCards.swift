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
        VStack(alignment: .leading, spacing: CardLayout.sectionSpacing) {
            Button(action: toggle) {
                HStack(spacing: CardLayout.headerSpacing) {
                    VStack(alignment: .leading, spacing: CardLayout.subtitleSpacing) {
                        if let collapsedTitle, !isExpanded {
                            Text(collapsedTitle)
                                .font(.headline)
                        } else {
                            Text(title)
                                .font(.headline)
                            if let subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .sectionCard()
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
        VStack(alignment: .leading, spacing: CardLayout.sectionSpacing) {
            Button(action: toggle) {
                HStack(spacing: CardLayout.headerSpacing) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, CardLayout.horizontalPadding)
        .padding(.vertical, CardLayout.listSpacing)
        .background(GameTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CardLayout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: CardLayout.cardCornerRadius)
                .stroke(GameTheme.cardBorder, lineWidth: CardLayout.borderWidth)
        )
        .shadow(
            color: GameTheme.cardShadow,
            radius: CardLayout.shadowRadius,
            x: 0,
            y: CardLayout.shadowYOffset
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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



