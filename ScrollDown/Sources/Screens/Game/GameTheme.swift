import SwiftUI
import UIKit

// MARK: - Design System

/// Unified design constants for consistent visual language
/// All values are intentional and should be used consistently throughout the app
enum DesignSystem {
    
    // MARK: - Corner Radii
    // Tightened by ~15% for sharper, more premium feel
    
    enum Radius {
        /// Large cards (section cards, main containers)
        static let card: CGFloat = 10
        /// Medium elements (timeline rows, stat rows, nested cards)
        static let element: CGFloat = 8
        /// Small elements (chips, tags, tooltips)
        static let small: CGFloat = 5
    }
    
    // MARK: - Spacing
    // Tightened by ~15% to reduce "floatiness"
    
    enum Spacing {
        /// Between major sections
        static let section: CGFloat = 14
        /// Between cards/rows in a list
        static let list: CGFloat = 6
        /// Internal card padding
        static let cardPadding: CGFloat = 12
        /// Internal element padding
        static let elementPadding: CGFloat = 10
        /// Between text elements
        static let text: CGFloat = 3
        /// Tight spacing
        static let tight: CGFloat = 2
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static var color: Color { GameTheme.cardShadow }
        static let radius: CGFloat = 6
        static let y: CGFloat = 2
        
        /// Subtle shadow for nested elements
        static let subtleRadius: CGFloat = 3
        static let subtleY: CGFloat = 1
    }
    
    // MARK: - Borders
    
    static let borderColor = Color(.systemGray4) // Slightly more visible
    static let borderWidth: CGFloat = 0.5
    
    // MARK: - Typography
    
    enum Typography {
        static let sectionTitle = Font.subheadline.weight(.semibold)
        static let sectionSubtitle = Font.caption2
        static let rowTitle = Font.footnote
        static let rowMeta = Font.caption2
        static let statValue = Font.caption
        static let statLabel = Font.caption2.weight(.semibold)
    }
    
    // MARK: - Text Contrast Tiers
    // Three distinct tiers for proper hierarchy

    enum TextColor {
        /// Primary text: key numbers, player names, headlines (90-100% opacity)
        static let primary = Color.primary
        /// Secondary text: labels, metadata (65-75% opacity)
        static let secondary = Color(.label).opacity(0.7)
        /// Tertiary text: hints, placeholders, subdued info (50% opacity)
        static let tertiary = Color(.label).opacity(0.50)
        /// Score highlight: blue in light mode, red in dark mode for emphasis
        static let scoreHighlight = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 255/255, green: 85/255, blue: 85/255, alpha: 1) // Vibrant red for dark mode
                : UIColor(red: 30/255, green: 100/255, blue: 200/255, alpha: 1) // Clear blue for light mode
        })
    }
    
    // MARK: - Interaction Accent
    // ONLY for navigation and focus states — NOT for team identity
    
    enum Accent {
        /// Interaction accent - tabs, active states, navigation
        static let primary = Color(.systemBlue)
        /// Accent at reduced opacity for tab backgrounds
        static let background = Color(.systemBlue).opacity(0.12)
    }
    
    // MARK: - Dual-Team Color System
    // Two peer colors for left/right comparison — neither is "accent"
    // Think broadcast graphics, not marketing
    // Dark mode: brighter purple, softer teal for better visibility

    enum TeamColors {
        // Default colors when team not found
        static let teamA = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 160/255, green: 130/255, blue: 255/255, alpha: 1)
                : UIColor.systemIndigo
        })
        static var teamABackground: Color { teamA.opacity(0.15) }
        static var teamABar: Color { teamA.opacity(0.8) }

        static let teamB = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 100/255, green: 200/255, blue: 180/255, alpha: 1)
                : UIColor.systemTeal
        })
        static var teamBBackground: Color { teamB.opacity(0.15) }
        static var teamBBar: Color { teamB.opacity(0.8) }

        /// Get team-specific color by team name
        static func color(for teamName: String) -> Color {
            TeamColorProvider.color(for: teamName)
        }

        /// Get team color for matchup contexts where both teams appear side by side.
        /// Pass `isHome: true` for the home team — it yields to neutral on color clash.
        /// The away team always keeps its original color.
        static func matchupColor(for teamName: String, against opponentName: String, isHome: Bool) -> Color {
            TeamColorProvider.matchupColor(for: teamName, against: opponentName, yieldsOnClash: isHome)
        }
    }

    // MARK: - Team Color Provider
    /// Resolves team colors from server cache, falling back to system indigo
    enum TeamColorProvider {

        static func color(for teamName: String) -> Color {
            // Check server-provided cache first
            if let colors = TeamColorCache.shared.color(for: teamName) {
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark ? colors.dark : colors.light
                })
            }
            // Default to system indigo
            return Color(uiColor: .systemIndigo)
        }

        /// Returns the team color for matchup display.
        /// `yieldsOnClash`: when true, this team's color is replaced with neutral if it clashes.
        /// Away team should pass false (keeps color), home team should pass true (yields).
        static func matchupColor(for teamName: String, against opponentName: String, yieldsOnClash: Bool) -> Color {
            guard yieldsOnClash else {
                return color(for: teamName)
            }
            let teamColor = resolvedColorPair(for: teamName)
            let opponentColor = resolvedColorPair(for: opponentName)

            return Color(uiColor: UIColor { traits in
                let isDark = traits.userInterfaceStyle == .dark
                let a = isDark ? teamColor.dark : teamColor.light
                let b = isDark ? opponentColor.dark : opponentColor.light
                if colorDistance(a, b) < 0.12 {
                    return isDark ? .white : .black
                }
                return a
            })
        }

        // MARK: - Color Similarity

        /// Resolve the (light, dark) UIColor pair for a team name
        private static func resolvedColorPair(for teamName: String) -> (light: UIColor, dark: UIColor) {
            if let colors = TeamColorCache.shared.color(for: teamName) {
                return colors
            }
            return (light: .systemIndigo, dark: .systemIndigo)
        }

        /// Normalized Euclidean distance between two UIColors in RGB space (0.0–1.0)
        private static func colorDistance(_ a: UIColor, _ b: UIColor) -> CGFloat {
            var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
            var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
            a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            let dr = r1 - r2, dg = g1 - g2, db = b1 - b2
            // max possible distance is sqrt(3) ≈ 1.73; normalize to 0–1
            return sqrt(dr * dr + dg * dg + db * db) / 1.732
        }
    }
    
    // MARK: - Colors
    
    enum Colors {
        static var cardBackground: Color { GameTheme.cardBackground }
        static let elevatedBackground = Color(.systemGray6)
        static let rowBackground = Color(.systemBackground)
        static let alternateRowBackground = Color(.systemGray6).opacity(0.4)
        
        /// Primary accent color for major inflection points
        /// Used sparingly - only for key moments that deserve visual emphasis
        static var accent: Color { GameTheme.accentColor }
        
        /// Away team badge (Team A - indigo)
        static let awayBadge = TeamColors.teamABackground
        /// Home team badge (Team B - teal)
        static let homeBadge = TeamColors.teamBBackground
        /// Neutral badge for non-team contexts
        static let neutralBadge = Color(.systemGray5)
    }
}

// MARK: - Game Theme

enum GameTheme {
    // Primary accent - confident blue
    static let accentColor = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 80/255, green: 140/255, blue: 220/255, alpha: 1)
            : UIColor(red: 45/255, green: 100/255, blue: 190/255, alpha: 1)
    })
    
    // Subtle warm tint for backgrounds
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 248/255, green: 248/255, blue: 250/255, alpha: 1)
    })
    
    // Card backgrounds with very subtle warmth
    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : .white
    })
    
    // Subtle top gradient overlay for depth
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(white: 0.08, alpha: 1)
                        : UIColor(red: 245/255, green: 247/255, blue: 250/255, alpha: 1)
                }),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
    }
    
    static let cardBorder = Color(.systemGray5)
    
    // Refined shadow - softer, more natural
    static let cardShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.25)
            : UIColor(white: 0, alpha: 0.08)
    })
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowYOffset: CGFloat = 2
    
    // Elevated card shadow for interactive elements
    static let elevatedShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.35)
            : UIColor(white: 0, alpha: 0.12)
    })
    static let elevatedShadowRadius: CGFloat = 12
    static let elevatedShadowYOffset: CGFloat = 4
}
