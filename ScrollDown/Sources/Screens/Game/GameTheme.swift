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
        // Fallback colors when team not found
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
    }

    // MARK: - Team Color Provider
    /// Maps actual team names to their brand colors
    enum TeamColorProvider {
        // Light mode / Dark mode color pairs
        private static let nbaColors: [String: (light: UIColor, dark: UIColor)] = [
            // Atlantic
            "Boston Celtics": (rgb(0, 122, 51), rgb(0, 155, 58)),
            "Brooklyn Nets": (rgb(0, 0, 0), rgb(100, 100, 100)),
            "New York Knicks": (rgb(0, 107, 182), rgb(245, 132, 38)),
            "Philadelphia 76ers": (rgb(0, 107, 182), rgb(237, 23, 76)),
            "Toronto Raptors": (rgb(206, 17, 65), rgb(206, 17, 65)),
            // Central
            "Chicago Bulls": (rgb(206, 17, 65), rgb(206, 17, 65)),
            "Cleveland Cavaliers": (rgb(134, 0, 56), rgb(253, 187, 48)),
            "Detroit Pistons": (rgb(200, 16, 46), rgb(29, 66, 138)),
            "Indiana Pacers": (rgb(0, 45, 98), rgb(253, 187, 48)),
            "Milwaukee Bucks": (rgb(0, 71, 27), rgb(240, 235, 210)),
            // Southeast
            "Atlanta Hawks": (rgb(225, 68, 52), rgb(196, 214, 0)),
            "Charlotte Hornets": (rgb(29, 17, 96), rgb(0, 120, 140)),
            "Miami Heat": (rgb(152, 0, 46), rgb(249, 160, 27)),
            "Orlando Magic": (rgb(0, 125, 197), rgb(196, 206, 211)),
            "Washington Wizards": (rgb(0, 43, 92), rgb(227, 24, 55)),
            // Northwest
            "Denver Nuggets": (rgb(13, 34, 64), rgb(255, 198, 39)),
            "Minnesota Timberwolves": (rgb(12, 35, 64), rgb(35, 97, 146)),
            "Oklahoma City Thunder": (rgb(0, 125, 195), rgb(239, 59, 36)),
            "Portland Trail Blazers": (rgb(224, 58, 62), rgb(99, 102, 106)),
            "Utah Jazz": (rgb(0, 43, 92), rgb(249, 160, 27)),
            // Pacific
            "Golden State Warriors": (rgb(29, 66, 138), rgb(255, 199, 44)),
            "LA Clippers": (rgb(200, 16, 46), rgb(29, 66, 148)),
            "Los Angeles Clippers": (rgb(200, 16, 46), rgb(29, 66, 148)),
            "LA Lakers": (rgb(85, 37, 130), rgb(253, 185, 39)),
            "Los Angeles Lakers": (rgb(85, 37, 130), rgb(253, 185, 39)),
            "Phoenix Suns": (rgb(29, 17, 96), rgb(229, 95, 32)),
            "Sacramento Kings": (rgb(91, 43, 130), rgb(99, 113, 122)),
            // Southwest
            "Dallas Mavericks": (rgb(0, 83, 188), rgb(0, 43, 92)),
            "Houston Rockets": (rgb(206, 17, 65), rgb(196, 206, 211)),
            "Memphis Grizzlies": (rgb(93, 118, 169), rgb(18, 23, 63)),
            "New Orleans Pelicans": (rgb(0, 22, 65), rgb(225, 58, 62)),
            "San Antonio Spurs": (rgb(196, 206, 211), rgb(6, 25, 34)),
        ]

        private static let nhlColors: [String: (light: UIColor, dark: UIColor)] = [
            // Metropolitan
            "Carolina Hurricanes": (rgb(206, 17, 38), rgb(162, 170, 173)),
            "Columbus Blue Jackets": (rgb(0, 38, 84), rgb(206, 17, 38)),
            "New Jersey Devils": (rgb(0, 0, 0), rgb(206, 17, 38)),
            "New York Islanders": (rgb(0, 83, 155), rgb(244, 125, 48)),
            "New York Rangers": (rgb(0, 56, 168), rgb(206, 17, 38)),
            "Philadelphia Flyers": (rgb(247, 73, 2), rgb(0, 0, 0)),
            "Pittsburgh Penguins": (rgb(0, 0, 0), rgb(252, 181, 20)),
            "Washington Capitals": (rgb(200, 16, 46), rgb(4, 30, 66)),
            // Atlantic
            "Boston Bruins": (rgb(0, 0, 0), rgb(252, 181, 20)),
            "Buffalo Sabres": (rgb(0, 38, 84), rgb(252, 181, 20)),
            "Detroit Red Wings": (rgb(206, 17, 38), rgb(255, 255, 255)),
            "Florida Panthers": (rgb(4, 30, 66), rgb(200, 16, 46)),
            "Montreal Canadiens": (rgb(175, 30, 45), rgb(25, 33, 104)),
            "Ottawa Senators": (rgb(0, 0, 0), rgb(200, 16, 46)),
            "Tampa Bay Lightning": (rgb(0, 40, 104), rgb(255, 255, 255)),
            "Toronto Maple Leafs": (rgb(0, 32, 91), rgb(255, 255, 255)),
            // Central
            "Arizona Coyotes": (rgb(140, 38, 51), rgb(226, 214, 181)),
            "Chicago Blackhawks": (rgb(207, 10, 44), rgb(0, 0, 0)),
            "Colorado Avalanche": (rgb(111, 38, 61), rgb(35, 97, 146)),
            "Dallas Stars": (rgb(0, 104, 71), rgb(143, 143, 140)),
            "Minnesota Wild": (rgb(21, 71, 52), rgb(175, 35, 36)),
            "Nashville Predators": (rgb(255, 184, 28), rgb(4, 30, 66)),
            "St. Louis Blues": (rgb(0, 47, 135), rgb(252, 181, 20)),
            "Winnipeg Jets": (rgb(4, 30, 66), rgb(0, 76, 151)),
            // Pacific
            "Anaheim Ducks": (rgb(252, 76, 2), rgb(0, 0, 0)),
            "Calgary Flames": (rgb(200, 16, 46), rgb(241, 190, 72)),
            "Edmonton Oilers": (rgb(4, 30, 66), rgb(252, 76, 2)),
            "Los Angeles Kings": (rgb(17, 17, 17), rgb(162, 170, 173)),
            "San Jose Sharks": (rgb(0, 109, 117), rgb(234, 114, 0)),
            "Seattle Kraken": (rgb(0, 22, 40), rgb(153, 217, 217)),
            "Vancouver Canucks": (rgb(0, 32, 91), rgb(10, 134, 61)),
            "Vegas Golden Knights": (rgb(51, 63, 66), rgb(185, 151, 91)),
        ]

        // MARK: College Teams (NCAAB / NCAAF)
        private static let collegeColors: [String: (light: UIColor, dark: UIColor)] = {
            // Palette — approximate brand colors with dark-mode-friendly variants
            func c(_ r: Int, _ g: Int, _ b: Int) -> UIColor {
                UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
            }
            let purple   = (c(100, 40, 160),  c(170, 130, 255))
            let blue     = (c(0, 100, 200),   c(80, 160, 255))
            let navy     = (c(0, 32, 91),     c(100, 150, 220))
            let crimson  = (c(165, 0, 22),    c(230, 90, 100))
            let maroon   = (c(100, 20, 30),   c(200, 100, 110))
            let gold     = (c(185, 155, 15),  c(255, 210, 80))
            let red      = (c(200, 16, 46),   c(240, 100, 100))
            let green    = (c(0, 120, 50),    c(80, 200, 120))
            let brown    = (c(120, 70, 30),   c(190, 140, 90))
            let black    = (c(30, 30, 30),    c(170, 170, 170))
            let orange   = (c(230, 120, 0),   c(255, 170, 70))
            let teal     = (c(0, 128, 128),   c(80, 210, 200))
            let gray     = (c(128, 128, 128), c(170, 170, 170))
            let scarlet  = (c(187, 0, 0),     c(240, 100, 100))
            let cardinal = (c(150, 0, 30),    c(240, 100, 100))
            let garnet   = (c(130, 0, 30),    c(230, 90, 100))

            return [
                "Abilene Christian": purple,
                "Air Force": blue,
                "Akron": navy,
                "Alabama": crimson,
                "Alabama A&M": maroon,
                "Alabama State": gold,
                "Albany": purple,
                "Alcorn State": purple,
                "American": red,
                "Appalachian State": green,
                "Arizona": red,
                "Arizona State": maroon,
                "Arkansas": red,
                "Arkansas State": red,
                "Army": black,
                "Auburn": navy,
                "Austin Peay": red,
                "Ball State": red,
                "Baylor": green,
                "Bellarmine": purple,
                "Belmont": red,
                "Bethune Cookman": maroon,
                "Binghamton": green,
                "Boise State": blue,
                "Boston College": maroon,
                "Boston University": red,
                "Bowling Green": brown,
                "Bradley": red,
                "Brown": brown,
                "Bryant": green,
                "Bucknell": orange,
                "Buffalo": blue,
                "Butler": navy,
                "BYU": navy,
                "Cal Poly": green,
                "Cal State Bakersfield": blue,
                "Cal State Fullerton": navy,
                "Cal State Northridge": red,
                "California": navy,
                "California Baptist": navy,
                "Campbell": orange,
                "Canisius": gold,
                "Central Arkansas": purple,
                "Central Connecticut": blue,
                "Central Florida": black,
                "Central Michigan": maroon,
                "Charleston": maroon,
                "Charleston Southern": blue,
                "Charlotte": green,
                "Chattanooga": gold,
                "Chicago State": green,
                "Cincinnati": red,
                "Clemson": orange,
                "Cleveland State": green,
                "Coastal Carolina": teal,
                "Colgate": maroon,
                "Colorado": black,
                "Colorado State": green,
                "Columbia": blue,
                "Connecticut": navy,
                "Coppin State": blue,
                "Cornell": red,
                "Creighton": blue,
                "Dartmouth": green,
                "Davidson": red,
                "Dayton": red,
                "Delaware": blue,
                "Delaware State": red,
                "Denver": crimson,
                "DePaul": blue,
                "Detroit Mercy": navy,
                "Drake": blue,
                "Drexel": navy,
                "Duke": blue,
                "Duquesne": red,
                "East Carolina": purple,
                "East Tennessee State": navy,
                "Eastern Illinois": blue,
                "Eastern Kentucky": maroon,
                "Eastern Michigan": green,
                "Eastern Washington": red,
                "Elon": maroon,
                "Evansville": purple,
                "Fairfield": red,
                "Fairleigh Dickinson": navy,
                "Florida": orange,
                "Florida A&M": green,
                "Florida Atlantic": red,
                "Florida Gulf Coast": green,
                "Florida International": blue,
                "Florida State": garnet,
                "Fordham": maroon,
                "Fresno State": red,
                "Furman": purple,
                "George Mason": green,
                "George Washington": navy,
                "Georgetown": navy,
                "Georgia": red,
                "Georgia Southern": navy,
                "Georgia State": blue,
                "Georgia Tech": gold,
                "Gonzaga": navy,
                "Grand Canyon": purple,
                "Hampton": blue,
                "Hartford": red,
                "Harvard": crimson,
                "Hawaii": green,
                "Hawai'i": green,
                "High Point": purple,
                "Hofstra": blue,
                "Holy Cross": purple,
                "Houston": red,
                "Houston Christian": orange,
                "Howard": blue,
                "Idaho": gold,
                "Idaho State": orange,
                "Illinois": orange,
                "Illinois State": red,
                "Incarnate Word": red,
                "Indiana": crimson,
                "Indiana State": blue,
                "Iona": maroon,
                "Iowa": black,
                "Iowa State": cardinal,
                "IUPUI": red,
                "Jackson State": blue,
                "Jacksonville": green,
                "Jacksonville State": red,
                "James Madison": purple,
                "Kansas": blue,
                "Kansas State": purple,
                "Kennesaw State": gold,
                "Kent State": navy,
                "Kentucky": blue,
                "La Salle": blue,
                "Lamar": red,
                "Liberty": red,
                "Lipscomb": purple,
                "Little Rock": maroon,
                "Long Beach State": black,
                "Long Island": blue,
                "Longwood": blue,
                "Louisiana": red,
                "Louisiana Monroe": maroon,
                "Louisiana Tech": blue,
                "Louisville": red,
                "Loyola Chicago": maroon,
                "Loyola Marymount": crimson,
                "Loyola Maryland": green,
                "LSU": purple,
                "Maine": blue,
                "Manhattan": green,
                "Marist": red,
                "Marquette": blue,
                "Marshall": green,
                "Maryland": red,
                "McNeese": blue,
                "Memphis": blue,
                "Mercer": orange,
                "Merrimack": blue,
                "Miami (OH)": red,
                "Michigan": blue,
                "Michigan State": green,
                "Middle Tennessee": blue,
                "Minnesota": maroon,
                "Mississippi": navy,
                "Mississippi State": maroon,
                "Mississippi Valley State": green,
                "Missouri": black,
                "Missouri State": maroon,
                "Monmouth": blue,
                "Montana": maroon,
                "Montana State": blue,
                "Morehead State": blue,
                "Morgan State": orange,
                "Mount St Mary's": blue,
                "Murray State": navy,
                "Navy": navy,
                "Nebraska": red,
                "Nevada": navy,
                "New Hampshire": blue,
                "New Mexico": red,
                "New Mexico State": crimson,
                "New Orleans": blue,
                "Niagara": purple,
                "Nicholls": red,
                "Norfolk State": green,
                "North Alabama": purple,
                "North Carolina": blue,
                "North Carolina A&T": blue,
                "North Carolina Central": maroon,
                "North Dakota": green,
                "North Dakota State": green,
                "North Florida": blue,
                "North Texas": green,
                "Northeastern": red,
                "Northern Arizona": blue,
                "Northern Colorado": navy,
                "Northern Illinois": red,
                "Northern Iowa": purple,
                "Northern Kentucky": gold,
                "Northwestern": purple,
                "Northwestern State": purple,
                "NC State": red,
                "Notre Dame": navy,
                "Oakland": gold,
                "Ohio": green,
                "Ohio State": scarlet,
                "Oklahoma": crimson,
                "Oklahoma State": orange,
                "Old Dominion": navy,
                "Ole Miss": navy,
                "Oral Roberts": navy,
                "Oregon": green,
                "Oregon State": orange,
                "Pacific": orange,
                "Penn": red,
                "Penn State": navy,
                "Pepperdine": blue,
                "Pittsburgh": blue,
                "Portland": purple,
                "Portland State": green,
                "Prairie View A&M": purple,
                "Presbyterian": blue,
                "Princeton": orange,
                "Providence": gray,
                "Purdue": gold,
                "Quinnipiac": navy,
                "Radford": red,
                "Rhode Island": blue,
                "Rice": blue,
                "Richmond": red,
                "Rider": crimson,
                "Robert Morris": navy,
                "Rutgers": scarlet,
                "Sacramento State": green,
                "Sacred Heart": red,
                "Sam Houston": orange,
                "Sam Houston State": orange,
                "Samford": red,
                "San Diego": blue,
                "San Diego State": red,
                "San Francisco": green,
                "San Jose State": blue,
                "Santa Clara": crimson,
                "Seattle": red,
                "Seton Hall": navy,
                "Siena": green,
                "SIU Edwardsville": red,
                "SMU": red,
                "South Alabama": blue,
                "South Carolina": garnet,
                "South Carolina State": maroon,
                "South Dakota": red,
                "South Dakota State": blue,
                "South Florida": green,
                "Southeast Missouri State": red,
                "Southeastern Louisiana": green,
                "Southern": blue,
                "Southern Illinois": maroon,
                "Southern Miss": gold,
                "Southern Utah": red,
                "St. Bonaventure": brown,
                "St. Francis": red,
                "St Johns": red,
                "St. Joseph's": crimson,
                "St. Peter's": blue,
                "St. Thomas": purple,
                "Stanford": cardinal,
                "Stephen F. Austin": purple,
                "Stetson": green,
                "Stonehill": purple,
                "Stony Brook": red,
                "Syracuse": orange,
                "Tarleton State": purple,
                "TCU": purple,
                "Temple": crimson,
                "Tennessee": orange,
                "Tennessee State": blue,
                "Tennessee Tech": purple,
                "Texas": orange,
                "Texas A&M": maroon,
                "Texas A&M Commerce": blue,
                "Texas A&M Corpus Christi": blue,
                "Texas Southern": maroon,
                "Texas State": maroon,
                "Texas Tech": red,
                "Toledo": navy,
                "Towson": gold,
                "Troy": crimson,
                "Tulane": green,
                "Tulsa": blue,
                "UAB": green,
                "UC Davis": navy,
                "UC Irvine": blue,
                "UC Riverside": blue,
                "UC San Diego": navy,
                "UC Santa Barbara": blue,
                "UCF": black,
                "UCLA": blue,
                "UMass": maroon,
                "UMass Lowell": blue,
                "UMBC": gold,
                "UNC Asheville": blue,
                "UNC Greensboro": navy,
                "UNC Wilmington": teal,
                "UNLV": red,
                "USC": cardinal,
                "USC Upstate": green,
                "UT Arlington": blue,
                "UT Martin": orange,
                "UT Rio Grande Valley": orange,
                "Utah": red,
                "Utah State": navy,
                "Utah Valley": green,
                "UTEP": orange,
                "UTSA": orange,
                "Valparaiso": brown,
                "Vanderbilt": gold,
                "Vermont": green,
                "Villanova": navy,
                "VCU": gold,
                "Virginia": navy,
                "Virginia Tech": maroon,
                "VMI": red,
                "Wagner": green,
                "Wake Forest": gold,
                "Washington": purple,
                "Washington State": crimson,
                "Weber State": purple,
                "West Virginia": blue,
                "Western Carolina": purple,
                "Western Illinois": purple,
                "Western Kentucky": red,
                "Western Michigan": brown,
                "Wichita State": gold,
                "William & Mary": green,
                "Winthrop": crimson,
                "Wisconsin": cardinal,
                "Wofford": gold,
                "Wright State": green,
                "Wyoming": brown,
                "Xavier": blue,
                "Yale": blue,
                "Youngstown State": red,
            ]
        }()

        private static func rgb(_ r: Int, _ g: Int, _ b: Int) -> UIColor {
            UIColor(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
        }

        /// College keys sorted longest-first so "Alabama A&M" matches before "Alabama"
        private static let collegeSortedKeys: [String] = collegeColors.keys.sorted { $0.count > $1.count }

        static func color(for teamName: String) -> Color {
            // Exact match first (NBA, NHL, and college names without mascots)
            if let colors = nbaColors[teamName] ?? nhlColors[teamName] ?? collegeColors[teamName] {
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark ? colors.dark : colors.light
                })
            }
            // Prefix match for college teams whose API names include mascots
            // e.g. "Iowa Hawkeyes" → "Iowa", "Alabama A&M Bulldogs" → "Alabama A&M"
            if let key = collegeSortedKeys.first(where: { teamName.hasPrefix($0) }),
               let colors = collegeColors[key] {
                return Color(uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark ? colors.dark : colors.light
                })
            }
            // Fallback to system indigo
            return Color(uiColor: .systemIndigo)
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
