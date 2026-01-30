import SwiftUI

// MARK: - Collapsible Section Card

/// A card that expands/collapses to show content with a title header.
/// Used for major sections in the game detail view.
/// iPad: Tighter internal spacing for density.
struct CollapsibleSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let collapsedTitle: String?
    @Binding var isExpanded: Bool
    /// Optional callback triggered when header is tapped (for global expand/collapse scenarios)
    var onHeaderTap: (() -> Void)?
    let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        title: String,
        subtitle: String? = nil,
        collapsedTitle: String? = nil,
        isExpanded: Binding<Bool>,
        onHeaderTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.collapsedTitle = collapsedTitle
        self._isExpanded = isExpanded
        self.onHeaderTap = onHeaderTap
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 8 : 12) { // iPad: tighter internal spacing
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
                .contentShape(Rectangle()) // Full row tap target
            }
            .buttonStyle(InteractiveRowButtonStyle())

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
            onHeaderTap?()
        }
    }
}

// MARK: - Collapsible Quarter Card

/// A smaller collapsible card used for quarter sections within the timeline.
/// iPad: Tighter spacing for density.
struct CollapsibleQuarterCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 8 : 12) { // iPad: tighter spacing
            // Boundary header - full row tappable
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
                .padding(.vertical, 4) // Increase tap target height
                .contentShape(Rectangle()) // Full row tap target
            }
            .buttonStyle(InteractiveRowButtonStyle())
            .accessibilityLabel("\(title), \(isExpanded ? "expanded" : "collapsed")")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand")")

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

// MARK: - Unified Interactive Button Styles
/// Consistent tap feedback across all interactive elements

/// Standard interactive row style - used for collapsible headers, tappable cards
/// Provides: opacity 0.6 + scale 0.98 on press with 0.15s animation
struct InteractiveRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Subtle interactive style - for less prominent interactive elements
/// Provides: opacity 0.7 only (no scale) with 0.1s animation
struct SubtleInteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
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



