import SwiftUI

/// Content hierarchy tiers for game detail view
/// Higher tiers = lower density, more visual weight
/// Lower tiers = higher density, reference-only content
///
/// CARD DISCIPLINE:
/// - Primary (Tier 1): NEVER a card - this IS the page
/// - Secondary (Tier 2): Card ONLY if optional/collapsible
/// - Supporting (Tier 3): Card for interactive/explorable content
/// - Reference (Tier 4): Card for deep-dive data
enum ContentTier: Int {
    case primary = 1      // Game Story - the main content (EMBEDDED)
    case secondary = 2    // Momentum/Swings - optional exploration (CARD)
    case supporting = 3   // Player Impact - interactive (CARD)
    case reference = 4    // Raw Data - reference (CARD)

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
        case .primary: return 1.5    // Generous - reading rhythm
        case .secondary: return 1.0  // Moderate
        case .supporting: return 0.8 // Tight - dense data
        case .reference: return 0.6  // Tightest - reference only
        }
    }

    /// Whether content should default to expanded
    var defaultExpanded: Bool {
        switch self {
        case .primary: return true   // Always visible - main content
        case .secondary: return false
        case .supporting: return false
        case .reference: return false
        }
    }

    /// Whether to use card container
    /// CARD DISCIPLINE: Cards mean choice (optional, interactive, collapsible, deep-dive)
    var useCard: Bool {
        switch self {
        case .primary: return false   // NEVER - this IS the page
        case .secondary: return true  // Optional exploration
        case .supporting: return true // Interactive data
        case .reference: return true  // Reference receipts
        }
    }

    /// Card intent for this tier
    var cardIntent: CardIntent {
        switch self {
        case .primary: return .embedded
        case .secondary: return .optionalExploration
        case .supporting: return .interactive
        case .reference: return .reference
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

// MARK: - Flow Card Container (Primary Content with Card)

/// Flow/Story content container - primary content wrapped in a card
/// Unlike Tier1Container, this provides visual containment matching other sections
/// Collapsible like other card sections
struct FlowCardContainer<Content: View>: View {
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
            // Section header (tappable)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .tracking(0.5)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, CardDisciplineLayout.cardInternalPadding)
                .padding(.top, TierLayout.Supporting.verticalSpacing)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                content
                    .padding(.bottom, TierLayout.Supporting.verticalSpacing)
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CardDisciplineLayout.cardCornerRadius))
        // Subtle shadow matching other card sections
        .shadow(
            color: DesignSystem.Shadow.color.opacity(0.4),
            radius: 3,
            x: 0,
            y: 1
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Tier 2 Container (Optional Exploration)

/// Secondary content container - optional exploration
/// CARD DISCIPLINE: This is a card because it's optional/collapsible
/// Uses lighter chrome than supporting tiers to signal "less critical"
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
        // Lighter card chrome than supporting tiers - subtle background, no shadow
        .background(DesignSystem.Colors.cardBackground.opacity(CardDisciplineLayout.cardBackgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: CardDisciplineLayout.cardCornerRadius))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Tier 3 Container (Interactive Data)

/// Supporting content container - interactive data exploration
/// CARD DISCIPLINE: This is a card because it's interactive/expandable
/// Uses subtle shadow to signal interactivity
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
                        if let subtitle, !isExpanded {
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
                .padding(.horizontal, CardDisciplineLayout.cardInternalPadding)
                .padding(.vertical, TierLayout.Supporting.verticalSpacing)
                .contentShape(Rectangle())
            }
            .buttonStyle(InteractiveRowButtonStyle())

            if isExpanded {
                content
                    .padding(.horizontal, CardDisciplineLayout.cardInternalPadding)
                    .padding(.bottom, TierLayout.Supporting.verticalSpacing)
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CardDisciplineLayout.cardCornerRadius))
        // Subtle shadow only - signals interactivity without dominating
        .shadow(
            color: DesignSystem.Shadow.color.opacity(0.4),
            radius: 3,
            x: 0,
            y: 1
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Tier 4 Container (Reference Data)

/// Reference content container - highest density, minimal decoration
/// CARD DISCIPLINE: This is a card because it's reference/deep-dive data
/// Signals: "This is here if you want receipts"
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
                    .padding(.horizontal, TierLayout.Reference.horizontalPadding)
                    .padding(.bottom, TierLayout.Reference.verticalSpacing)
                    .transition(.opacity)
            }
        }
        // Minimal card chrome - just enough to indicate it's a container
        .background(DesignSystem.Colors.rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // No shadow - reference content shouldn't demand attention
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
