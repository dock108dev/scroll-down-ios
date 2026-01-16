import SwiftUI
import UIKit

enum HomeTheme {
    // Primary accent - confident blue
    static let accentColor = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 80/255, green: 140/255, blue: 220/255, alpha: 1)
            : UIColor(red: 45/255, green: 100/255, blue: 190/255, alpha: 1)
    })
    
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemBackground
            : UIColor(red: 248/255, green: 248/255, blue: 250/255, alpha: 1)
    })
    
    static let cardBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : .white
    })
    
    // Refined shadow
    static let cardShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.25)
            : UIColor(white: 0, alpha: 0.08)
    })
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowYOffset: CGFloat = 2
    static let cardCornerRadius: CGFloat = 12
}
