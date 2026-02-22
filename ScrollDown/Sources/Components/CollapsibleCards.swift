import SwiftUI

// MARK: - Pinned Section Header

/// A header-only view designed for use with `Section(header:)` inside
/// `LazyVStack(pinnedViews: [.sectionHeaders])`. Renders the same header
/// layout as a collapsible card header but without wrapping content.
struct PinnedSectionHeader: View {
    let title: String
    let subtitle: String?
    let collapsedTitle: String?
    @Binding var isExpanded: Bool
    var onHeaderTap: (() -> Void)?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        title: String,
        subtitle: String? = nil,
        collapsedTitle: String? = nil,
        isExpanded: Binding<Bool>,
        onHeaderTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.collapsedTitle = collapsedTitle
        self._isExpanded = isExpanded
        self.onHeaderTap = onHeaderTap
    }

    var body: some View {
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
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractiveRowButtonStyle())
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: DesignSystem.Radius.card,
            bottomLeadingRadius: isExpanded ? 0 : DesignSystem.Radius.card,
            bottomTrailingRadius: isExpanded ? 0 : DesignSystem.Radius.card,
            topTrailingRadius: DesignSystem.Radius.card
        ))
        .shadow(
            color: DesignSystem.Shadow.color,
            radius: DesignSystem.Shadow.radius,
            x: 0,
            y: DesignSystem.Shadow.y
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: DesignSystem.Radius.card,
                bottomLeadingRadius: isExpanded ? 0 : DesignSystem.Radius.card,
                bottomTrailingRadius: isExpanded ? 0 : DesignSystem.Radius.card,
                topTrailingRadius: DesignSystem.Radius.card
            )
            .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: DesignSystem.borderWidth)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.2)) {
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
    let subtitle: String?
    @Binding var isExpanded: Bool
    let content: Content
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 8 : 12) { // iPad: tighter spacing
            // Boundary header - full row tappable
            Button(action: toggle) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                        }
                    }
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
                    .transition(.opacity)
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
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggle() {
        withAnimation(.easeInOut(duration: 0.2)) {
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


