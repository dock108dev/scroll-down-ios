import SwiftUI

// MARK: - Visual Rhythm System
/// Creates intentional pauses and density variation to reduce scrolling fatigue

enum VisualRhythm {
    // MARK: - Spacing Scales (Distinct per tier)

    /// Generous spacing for primary content
    static let primarySpacing: CGFloat = 28

    /// Moderate spacing for secondary content
    static let secondarySpacing: CGFloat = 20

    /// Tight spacing for supporting content
    static let supportingSpacing: CGFloat = 14

    /// Minimal spacing for reference content
    static let referenceSpacing: CGFloat = 10

    /// Breathing room before major section breaks
    static let sectionBreathingRoom: CGFloat = 32

    /// Divider margin (vertical)
    static let dividerMargin: CGFloat = 24
}

// MARK: - Section Divider

/// Thin, low-contrast divider for visual pauses between sections
/// Acts as a rest point, not a separator
struct SectionDivider: View {
    var opacity: Double = 0.25

    var body: some View {
        Rectangle()
            .fill(DesignSystem.borderColor.opacity(opacity))
            .frame(height: 1)
            .padding(.vertical, VisualRhythm.dividerMargin)
    }
}

// MARK: - Section Header

/// Earned section header - feels like a chapter break, not a label
/// Uses subtle typographic emphasis, never competes with content
struct SectionHeader: View {
    let title: String
    let tier: ContentTier

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(headerFont)
                .foregroundColor(headerColor)
                .tracking(tier == .reference ? 0.5 : 0)

            // Subtle underline for primary/secondary tiers
            if tier == .primary || tier == .secondary {
                Rectangle()
                    .fill(DesignSystem.borderColor.opacity(0.3))
                    .frame(height: 1)
                    .frame(maxWidth: 60)
            }
        }
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }

    private var headerFont: Font {
        switch tier {
        case .primary:
            return .subheadline.weight(.semibold)
        case .secondary:
            return .footnote.weight(.semibold)
        case .supporting:
            return .caption.weight(.semibold)
        case .reference:
            return .caption2.weight(.bold)
        }
    }

    private var headerColor: Color {
        switch tier {
        case .primary:
            return DesignSystem.TextColor.primary
        case .secondary:
            return DesignSystem.TextColor.secondary
        case .supporting, .reference:
            return DesignSystem.TextColor.tertiary
        }
    }

    private var topPadding: CGFloat {
        switch tier {
        case .primary: return VisualRhythm.sectionBreathingRoom
        case .secondary: return VisualRhythm.secondarySpacing
        case .supporting: return VisualRhythm.supportingSpacing
        case .reference: return VisualRhythm.referenceSpacing
        }
    }

    private var bottomPadding: CGFloat {
        switch tier {
        case .primary: return 12
        case .secondary: return 8
        case .supporting: return 6
        case .reference: return 4
        }
    }
}

// MARK: - Rhythm Section

/// A section with tier-appropriate density and spacing
struct RhythmSection<Content: View>: View {
    let tier: ContentTier
    let content: Content

    init(tier: ContentTier, @ViewBuilder content: () -> Content) {
        self.tier = tier
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            content
        }
        .padding(.horizontal, horizontalPadding)
    }

    private var sectionSpacing: CGFloat {
        switch tier {
        case .primary: return VisualRhythm.primarySpacing
        case .secondary: return VisualRhythm.secondarySpacing
        case .supporting: return VisualRhythm.supportingSpacing
        case .reference: return VisualRhythm.referenceSpacing
        }
    }

    private var horizontalPadding: CGFloat {
        switch tier {
        case .primary: return 20
        case .secondary: return 16
        case .supporting: return 12
        case .reference: return 10
        }
    }
}

// MARK: - Compressed Section Preview

/// Compact preview of a section that expands on tap
/// Reduces perceived screen length while preserving discoverability
struct CompressedSectionPreview<Content: View, ExpandedContent: View>: View {
    let title: String
    let subtitle: String?
    let previewContent: Content
    @Binding var isExpanded: Bool
    let expandedContent: ExpandedContent

    init(
        title: String,
        subtitle: String? = nil,
        isExpanded: Binding<Bool>,
        @ViewBuilder preview: () -> Content,
        @ViewBuilder expanded: () -> ExpandedContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.previewContent = preview()
        self.expandedContent = expanded()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with expand control
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.footnote.weight(.semibold))
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Preview or expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                previewContent
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}

// MARK: - Alternating Background

/// Subtle background variation for scroll landmarks
/// Not color blocks - just subtle warmth/coolness shifts
struct AlternatingBackground: ViewModifier {
    let index: Int

    func body(content: Content) -> some View {
        content
            .background(
                index.isMultiple(of: 2)
                    ? Color.clear
                    : DesignSystem.Colors.cardBackground.opacity(0.3)
            )
    }
}

extension View {
    func alternatingBackground(index: Int) -> some View {
        modifier(AlternatingBackground(index: index))
    }
}

// MARK: - Content Break

/// Visual break between major content blocks
/// Creates intentional pause without heavy dividers
struct ContentBreak: View {
    var body: some View {
        Spacer()
            .frame(height: VisualRhythm.sectionBreathingRoom)
    }
}

// MARK: - Tier Transition

/// Smooth visual transition between content tiers
struct TierTransition: View {
    let from: ContentTier
    let to: ContentTier

    var body: some View {
        VStack(spacing: 0) {
            // Breathing room proportional to tier difference
            Spacer()
                .frame(height: transitionHeight)

            // Subtle divider for major transitions
            if shouldShowDivider {
                SectionDivider(opacity: 0.2)
            }
        }
    }

    private var transitionHeight: CGFloat {
        let diff = abs(from.rawValue - to.rawValue)
        return CGFloat(diff) * 8 + 12
    }

    private var shouldShowDivider: Bool {
        // Show divider when transitioning to/from reference tier
        from == .reference || to == .reference ||
        // Or when jumping more than one tier
        abs(from.rawValue - to.rawValue) > 1
    }
}

// MARK: - Previews

#Preview("Section Header - Primary") {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader(title: "Game Story", tier: .primary)
        Text("Primary content with generous spacing...")
            .font(.body)
    }
    .padding()
}

#Preview("Section Divider") {
    VStack {
        Text("Content above")
        SectionDivider()
        Text("Content below")
    }
    .padding()
}

#Preview("Compressed Preview") {
    CompressedSectionPreview(
        title: "Player Stats",
        subtitle: "12 players",
        isExpanded: .constant(false),
        preview: {
            HStack {
                Text("Top: J. Tatum 32 PTS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        },
        expanded: {
            Text("Full stats table here...")
                .padding()
        }
    )
    .padding()
}
