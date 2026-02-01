import SwiftUI

// MARK: - Card Discipline System
/// Establishes strict rules for card usage so cards regain meaning
/// and narrative feels embedded in the page, not wrapped in UI chrome

// MARK: - Card Usage Contract

/// Defines when cards are appropriate
/// Cards mean: Optional, Interactive, Collapsible, Deep-dive, Reference-oriented
/// If content doesn't meet one of these, it MUST NOT use a card
enum CardIntent {
    /// User can choose to explore (Momentum, Player Impact)
    case optionalExploration

    /// Content is interactive (expandable tables, toggleable views)
    case interactive

    /// Content can collapse to save space
    case collapsible

    /// Deep reference data (full PBP, stat tables)
    case reference

    /// Content the user is expected to read by default - NO CARD
    case embedded
}

// MARK: - Layout Configuration

enum CardDisciplineLayout {
    // MARK: - Embedded Content Spacing

    /// Space between narrative paragraphs
    static let paragraphSpacing: CGFloat = 24

    /// Space between narrative sections (larger conceptual breaks)
    static let sectionSpacing: CGFloat = 40

    /// Space before/after framing elements
    static let framingElementSpacing: CGFloat = 12

    // MARK: - Transition Zones

    /// Extra vertical space when transitioning from embedded → carded content
    static let transitionZoneHeight: CGFloat = 32

    /// Divider opacity for transition zones
    static let transitionDividerOpacity: Double = 0.15

    // MARK: - Carded Content

    /// Tighter internal padding than narrative
    static let cardInternalPadding: CGFloat = 12

    /// Card background opacity (subtle contrast)
    static let cardBackgroundOpacity: Double = 0.6

    /// Card corner radius
    static let cardCornerRadius: CGFloat = 10
}

// MARK: - Embedded Content Container

/// For content the user is expected to read by default
/// NO card, NO rounded rectangle, NO shadow, NO background fill
/// This content IS the page
struct EmbeddedContent<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CardDisciplineLayout.paragraphSpacing) {
            content
        }
        // No card chrome - content renders directly on page background
    }
}

// MARK: - Embedded Paragraph

/// Single paragraph of embedded narrative content
/// Text on background, comfortable margins, separated by spacing not containers
struct EmbeddedParagraph<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        // No borders, no elevation, no background
    }
}

// MARK: - Framing Element

/// One-line editorial context that feels like a marginal note
/// Examples: "Why this game mattered", game significance tags
struct FramingElement: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.tertiary)
            }

            Text(text)
                .font(.caption)
                .foregroundColor(DesignSystem.TextColor.secondary)
                .italic()
        }
        .padding(.vertical, CardDisciplineLayout.framingElementSpacing)
        // No card chrome - marginal note style
    }
}

// MARK: - Transition Zone

/// Visual pause when moving from embedded narrative → carded content
/// Preserves reading flow by not abruptly switching container styles
struct TransitionZone: View {
    var showDivider: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: CardDisciplineLayout.transitionZoneHeight / 2)

            if showDivider {
                Rectangle()
                    .fill(DesignSystem.borderColor.opacity(CardDisciplineLayout.transitionDividerOpacity))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }

            Spacer()
                .frame(height: CardDisciplineLayout.transitionZoneHeight / 2)
        }
    }
}

// MARK: - Optional Card Container

/// Card for optional exploration content
/// Communicates: "You can open this, but you don't have to"
struct OptionalCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @Binding var isExpanded: Bool
    let content: Content

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
        VStack(alignment: .leading, spacing: 0) {
            // Card header - tappable
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.footnote.weight(.semibold))
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
                .padding(CardDisciplineLayout.cardInternalPadding)
                .contentShape(Rectangle())
            }
            .buttonStyle(InteractiveRowButtonStyle())

            // Expanded content
            if isExpanded {
                content
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground.opacity(CardDisciplineLayout.cardBackgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: CardDisciplineLayout.cardCornerRadius))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Reference Card Container

/// Card for dense reference data
/// Signals: "This is here if you want receipts"
struct ReferenceCard<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 0) {
            // Minimal header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(DesignSystem.TextColor.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
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

// MARK: - Inline Annotation

/// For inline play expansions (footnotes) - no card chrome
/// Indented, visually subordinate, clearly an annotation
struct InlineAnnotation<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            content
        }
        .padding(.leading, 16) // Indented from narrative
        // No card chrome - these are annotations, not sections
    }
}

// MARK: - Section Spacer

/// Creates conceptual separation using spacing alone
/// Replaces heavy chrome with intentional whitespace
struct SectionSpacer: View {
    enum Size {
        case small   // Between related items
        case medium  // Between subsections
        case large   // Between major sections

        var height: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 24
            case .large: return 40
            }
        }
    }

    let size: Size

    init(_ size: Size = .medium) {
        self.size = size
    }

    var body: some View {
        Spacer()
            .frame(height: size.height)
    }
}

// MARK: - Previews

#Preview("Embedded Content") {
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            EmbeddedContent {
                EmbeddedParagraph {
                    Text("The Warriors surged ahead with a devastating 12-2 run sparked by Curry's back-to-back threes.")
                        .textStyle(.narrative)
                }

                EmbeddedParagraph {
                    Text("Miami responded with a methodical offensive approach, working inside to Bam Adebayo.")
                        .textStyle(.narrative)
                }
            }

            TransitionZone(showDivider: true)

            OptionalCard(
                title: "Player Stats",
                subtitle: "12 players",
                isExpanded: .constant(false)
            ) {
                Text("Stats content here...")
                    .padding()
            }
        }
        .padding()
    }
}

#Preview("Framing Element") {
    VStack(alignment: .leading, spacing: 20) {
        FramingElement(text: "Why this game mattered", icon: "star")
        FramingElement(text: "Season-defining performance")
    }
    .padding()
}

#Preview("Transition Zones") {
    ScrollView {
        VStack(spacing: 0) {
            Text("Embedded narrative content...")
                .textStyle(.narrative)
                .padding()

            TransitionZone()

            OptionalCard(
                title: "Optional Section",
                isExpanded: .constant(false)
            ) {
                Text("Card content")
            }
            .padding(.horizontal)

            SectionSpacer(.medium)

            ReferenceCard(
                title: "Reference Data",
                isExpanded: .constant(false)
            ) {
                Text("Reference content")
            }
            .padding(.horizontal)
        }
    }
}
