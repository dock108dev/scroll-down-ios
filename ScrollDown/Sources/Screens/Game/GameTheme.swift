import SwiftUI
import UIKit

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
