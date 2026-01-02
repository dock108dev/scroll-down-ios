import SwiftUI
import UIKit

enum HomeTheme {
    static let accentColor = Color(red: 0.18, green: 0.41, blue: 0.87)
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondarySystemBackground
            : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
    })
    static let cardBackground = Color(.systemBackground)
    static let cardShadow = Color.black.opacity(0.08)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowYOffset: CGFloat = 3
    static let cardCornerRadius: CGFloat = 18
}
