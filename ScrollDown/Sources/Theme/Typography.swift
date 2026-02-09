import SwiftUI

// MARK: - Typography System
/// Deliberate typography system for narrative-first reading
/// Establishes trust through intentional hierarchy without custom fonts

// MARK: - Text Style Definitions

/// Four explicit text roles - never use system defaults interchangeably
enum TextStyle {
    // MARK: - Narrative Text (Primary Reading)
    /// Used for: Game Flow paragraphs, narrative summaries, inline explanations
    /// Feels like a book or article, not a system label
    case narrative
    case narrativeEmphasis  // For highlighted moments

    // MARK: - Section Headers (Orientation)
    /// Used for: Game Flow header, Momentum/Player Impact headers
    /// Headers orient - they do not shout
    case sectionHeader
    case subSectionHeader

    // MARK: - System Labels (UI Structure)
    /// Used for: Button labels, section affordances, table headers
    /// Labels support navigation, not reading
    case label
    case labelSmall

    // MARK: - Metadata (Contextual, De-emphasized)
    /// Used for: Time remaining, score changes, quarter indicators, stat units
    /// Readable but ignorable
    case metadata
    case metadataSmall

    // MARK: - Score Display
    /// Used for: Score numbers in headers and inline
    case scoreDisplay
    case scoreLarge
}

// MARK: - Typography Configuration

/// Centralized typography configuration
/// All spacing and font decisions in one place
enum TypographyConfig {
    // MARK: - Line Heights (as multipliers of font size)

    /// Narrative text: slightly tighter than system default (1.25-1.3×)
    static let narrativeLineHeight: CGFloat = 5.0

    /// Headers: tighter for compact appearance
    static let headerLineHeight: CGFloat = 3.0

    /// Labels: minimal line height
    static let labelLineHeight: CGFloat = 2.0

    /// Metadata: tightest spacing
    static let metadataLineHeight: CGFloat = 1.5

    // MARK: - Letter Spacing (tracking)

    /// Headers get subtle increased letter spacing
    static let headerTracking: CGFloat = 0.3

    /// Labels use slight tracking for clarity
    static let labelTracking: CGFloat = 0.2

    // MARK: - Paragraph Spacing

    /// Space between paragraphs (more than line spacing)
    static let paragraphSpacing: CGFloat = 16

    /// Space after section headers
    static let headerBottomSpacing: CGFloat = 12

    /// Space before section headers
    static let headerTopSpacing: CGFloat = 24
}

// MARK: - Typography View Modifier

/// Applies text style with proper font, weight, color, and spacing
struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    let color: Color?

    init(style: TextStyle, color: Color? = nil) {
        self.style = style
        self.color = color
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .fontWeight(weight)
            .foregroundColor(foregroundColor)
            .lineSpacing(lineSpacing)
            .tracking(tracking)
    }

    private var font: Font {
        switch style {
        case .narrative:
            return .body
        case .narrativeEmphasis:
            return .body
        case .sectionHeader:
            return .subheadline
        case .subSectionHeader:
            return .footnote
        case .label:
            return .subheadline
        case .labelSmall:
            return .caption
        case .metadata:
            return .caption
        case .metadataSmall:
            return .caption2
        case .scoreDisplay:
            return .subheadline.monospacedDigit()
        case .scoreLarge:
            return .title2.monospacedDigit()
        }
    }

    private var weight: Font.Weight {
        switch style {
        case .narrative:
            return .regular
        case .narrativeEmphasis:
            return .medium
        case .sectionHeader:
            return .semibold
        case .subSectionHeader:
            return .semibold
        case .label:
            return .medium
        case .labelSmall:
            return .medium
        case .metadata:
            return .regular
        case .metadataSmall:
            return .regular
        case .scoreDisplay:
            return .semibold
        case .scoreLarge:
            return .bold
        }
    }

    private var foregroundColor: Color {
        if let color { return color }

        switch style {
        case .narrative, .narrativeEmphasis:
            return DesignSystem.TextColor.primary
        case .sectionHeader:
            return DesignSystem.TextColor.primary
        case .subSectionHeader:
            return DesignSystem.TextColor.secondary
        case .label, .labelSmall:
            return DesignSystem.TextColor.secondary
        case .metadata, .metadataSmall:
            return DesignSystem.TextColor.tertiary
        case .scoreDisplay:
            return DesignSystem.TextColor.primary
        case .scoreLarge:
            return DesignSystem.TextColor.primary
        }
    }

    private var lineSpacing: CGFloat {
        switch style {
        case .narrative, .narrativeEmphasis:
            return TypographyConfig.narrativeLineHeight
        case .sectionHeader, .subSectionHeader:
            return TypographyConfig.headerLineHeight
        case .label, .labelSmall:
            return TypographyConfig.labelLineHeight
        case .metadata, .metadataSmall:
            return TypographyConfig.metadataLineHeight
        case .scoreDisplay, .scoreLarge:
            return 0
        }
    }

    private var tracking: CGFloat {
        switch style {
        case .sectionHeader, .subSectionHeader:
            return TypographyConfig.headerTracking
        case .label, .labelSmall:
            return TypographyConfig.labelTracking
        default:
            return 0
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply a text style with optional color override
    func textStyle(_ style: TextStyle, color: Color? = nil) -> some View {
        modifier(TextStyleModifier(style: style, color: color))
    }
}

// MARK: - Styled Text Views

/// Pre-styled text view for narrative content
struct NarrativeText: View {
    let text: String
    var isEmphasis: Bool = false

    init(_ text: String, emphasis: Bool = false) {
        self.text = text
        self.isEmphasis = emphasis
    }

    var body: some View {
        Text(text)
            .textStyle(isEmphasis ? .narrativeEmphasis : .narrative)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Pre-styled section header
struct SectionHeaderText: View {
    let text: String
    var isSubsection: Bool = false

    init(_ text: String, subsection: Bool = false) {
        self.text = text
        self.isSubsection = subsection
    }

    var body: some View {
        Text(text)
            .textStyle(isSubsection ? .subSectionHeader : .sectionHeader)
            .padding(.top, isSubsection ? 12 : TypographyConfig.headerTopSpacing)
            .padding(.bottom, isSubsection ? 8 : TypographyConfig.headerBottomSpacing)
    }
}

/// Pre-styled metadata text
struct MetadataText: View {
    let text: String
    var isSmall: Bool = false

    init(_ text: String, small: Bool = false) {
        self.text = text
        self.isSmall = small
    }

    var body: some View {
        Text(text)
            .textStyle(isSmall ? .metadataSmall : .metadata)
    }
}

/// Pre-styled label text
struct LabelText: View {
    let text: String
    var isSmall: Bool = false

    init(_ text: String, small: Bool = false) {
        self.text = text
        self.isSmall = small
    }

    var body: some View {
        Text(text)
            .textStyle(isSmall ? .labelSmall : .label)
    }
}

/// Pre-styled score display
struct ScoreText: View {
    let score: Int
    var isLarge: Bool = false
    var teamColor: Color?

    init(_ score: Int, large: Bool = false, teamColor: Color? = nil) {
        self.score = score
        self.isLarge = large
        self.teamColor = teamColor
    }

    var body: some View {
        Text("\(score)")
            .textStyle(isLarge ? .scoreLarge : .scoreDisplay, color: teamColor)
    }
}

// MARK: - Paragraph Container

/// Container for narrative paragraphs with proper spacing
struct NarrativeParagraph<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.bottom, TypographyConfig.paragraphSpacing)
    }
}

// MARK: - Previews

#Preview("Typography Styles") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Narrative
            VStack(alignment: .leading, spacing: 8) {
                Text("Narrative Text")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                NarrativeText("The Warriors surged ahead with a devastating 12-2 run sparked by Curry's back-to-back threes. The Lakers called timeout trailing by double digits for the first time in the game.")

                NarrativeText("This moment marked a turning point in the fourth quarter.", emphasis: true)
            }

            Divider()

            // Section Headers
            VStack(alignment: .leading, spacing: 8) {
                Text("Section Headers")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                SectionHeaderText("Game Flow")
                SectionHeaderText("Player Impact", subsection: true)
            }

            Divider()

            // Labels
            VStack(alignment: .leading, spacing: 8) {
                Text("Labels")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                LabelText("View 6 plays")
                LabelText("Quarter 4", small: true)
            }

            Divider()

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                Text("Metadata")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                MetadataText("Q4 2:45 – 1:30")
                MetadataText("12 PTS · 4 REB · 2 AST", small: true)
            }

            Divider()

            // Scores
            VStack(alignment: .leading, spacing: 8) {
                Text("Scores")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ScoreText(108, teamColor: DesignSystem.TeamColors.teamA)
                    Text("-")
                    ScoreText(105, teamColor: DesignSystem.TeamColors.teamB)
                }

                ScoreText(112, large: true)
            }
        }
        .padding()
    }
}

#Preview("Narrative Paragraph Flow") {
    ScrollView {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderText("Game Flow")

            NarrativeParagraph {
                MetadataText("Q1 12:00 – 8:30", small: true)
                    .padding(.bottom, 4)

                NarrativeText("The game opened with a flurry of activity as both teams tested each other's defenses. Golden State came out aggressive, pushing the pace and creating opportunities in transition.")
            }

            NarrativeParagraph {
                MetadataText("Q1 8:30 – 4:00", small: true)
                    .padding(.bottom, 4)

                NarrativeText("Miami responded with a methodical offensive approach, working the ball inside to Bam Adebayo who dominated the paint with a series of powerful post moves.", emphasis: true)
            }

            NarrativeParagraph {
                MetadataText("Q1 4:00 – 0:00", small: true)
                    .padding(.bottom, 4)

                NarrativeText("The quarter closed with the Warriors holding a slim two-point advantage, setting the stage for an increasingly physical second period.")
            }
        }
        .padding()
    }
}
