import SwiftUI

/// Content hierarchy tiers for game detail view
/// Higher tiers = lower density, more visual weight
/// Lower tiers = higher density, reference-only content
enum ContentTier: Int {
    case primary = 1      // Game Story - the main content
    case secondary = 2    // Momentum/Swings - why it unfolded
    case supporting = 3   // Player Impact - who mattered
    case reference = 4    // Raw Data - verification/detail

    /// Typography scale for each tier
    var bodyFont: Font {
        switch self {
        case .primary: return .body
        case .secondary: return .subheadline
        case .supporting: return .footnote
        case .reference: return .caption
        }
    }

    /// Spacing multiplier for each tier
    var spacingMultiplier: CGFloat {
        switch self {
        case .primary: return 1.5    // Generous
        case .secondary: return 1.0  // Moderate
        case .supporting: return 0.8 // Tight
        case .reference: return 0.6  // Tightest
        }
    }

    /// Whether content should default to expanded
    var defaultExpanded: Bool {
        switch self {
        case .primary: return true
        case .secondary: return false
        case .supporting: return false
        case .reference: return false
        }
    }

    /// Whether to use card container
    var useCard: Bool {
        switch self {
        case .primary: return false   // No card - IS the page
        case .secondary: return true  // Lightweight card
        case .supporting: return true // Standard card
        case .reference: return true  // Standard card
        }
    }
}

/// Tier-specific layout configuration
enum TierLayout {
    // MARK: - Tier 1: Primary (Game Story)
    enum Primary {
        static let verticalSpacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 20
        static let lineSpacing: CGFloat = 6
        static let paragraphSpacing: CGFloat = 16
        static let momentSpacing: CGFloat = 20

        static var narrativeFont: Font { .body }
        static var narrativeFontWeight: Font.Weight { .regular }
        static var narrativeLineHeight: CGFloat { 1.5 }
    }

    // MARK: - Tier 2: Secondary (Momentum/Swings)
    enum Secondary {
        static let verticalSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let itemSpacing: CGFloat = 12

        static var headerFont: Font { .subheadline.weight(.semibold) }
        static var bodyFont: Font { .subheadline }
    }

    // MARK: - Tier 3: Supporting (Player/Team Stats)
    enum Supporting {
        static let verticalSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 12
        static let rowSpacing: CGFloat = 0

        static var headerFont: Font { .footnote.weight(.semibold) }
        static var bodyFont: Font { .footnote }
    }

    // MARK: - Tier 4: Reference (Raw Data)
    enum Reference {
        static let verticalSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 10
        static let rowSpacing: CGFloat = 0

        static var headerFont: Font { .caption.weight(.semibold) }
        static var bodyFont: Font { .caption }
    }
}

// MARK: - Tier 1 Container (No Card)

/// Primary content container - no card, feels like the page itself
struct Tier1Container<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TierLayout.Primary.verticalSpacing) {
            content
        }
        .padding(.horizontal, TierLayout.Primary.horizontalPadding)
    }
}

// MARK: - Tier 2 Container (Lightweight Card)

/// Secondary content container - lightweight card, not heavy chrome
struct Tier2Container<Content: View>: View {
    let title: String?
    @Binding var isExpanded: Bool
    let content: Content

    init(title: String? = nil, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TierLayout.Secondary.itemSpacing) {
            if let title {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(TierLayout.Secondary.headerFont)
                            .foregroundColor(DesignSystem.TextColor.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(DesignSystem.TextColor.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, TierLayout.Secondary.horizontalPadding)
        .padding(.vertical, TierLayout.Secondary.verticalSpacing)
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Tier 3 Container (Compact Card)

/// Supporting content container - compact, high density
struct Tier3Container<Content: View>: View {
    let title: String
    let subtitle: String?
    @Binding var isExpanded: Bool
    let content: Content

    init(title: String, subtitle: String? = nil, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TierLayout.Supporting.rowSpacing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(TierLayout.Supporting.headerFont)
                            .foregroundColor(DesignSystem.TextColor.primary)
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, TierLayout.Supporting.horizontalPadding)
                .padding(.vertical, TierLayout.Supporting.verticalSpacing)
                .contentShape(Rectangle())
            }
            .buttonStyle(InteractiveRowButtonStyle())

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .shadow(
            color: DesignSystem.Shadow.color.opacity(0.5),
            radius: DesignSystem.Shadow.subtleRadius,
            x: 0,
            y: DesignSystem.Shadow.subtleY
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Tier 4 Container (Reference/Dense Card)

/// Reference content container - highest density, minimal decoration
struct Tier4Container<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: Content

    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(TierLayout.Reference.headerFont)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, TierLayout.Reference.horizontalPadding)
                .padding(.vertical, TierLayout.Reference.verticalSpacing)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
