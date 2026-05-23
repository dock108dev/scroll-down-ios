import SwiftUI

enum SnapshotEnvironment {
    static let locale = Locale(identifier: "en_US_POSIX")
    static let calendar = Calendar(identifier: .gregorian)
    static let timeZone = TimeZone(secondsFromGMT: 0)!
    static let colorScheme = ColorScheme.light
    static let dynamicTypeSize = DynamicTypeSize.medium
    static let layoutDirection = LayoutDirection.leftToRight
}

struct SnapshotEnvironmentModifier: ViewModifier {
    let colorScheme: ColorScheme
    let dynamicTypeSize: DynamicTypeSize

    func body(content: Content) -> some View {
        content
            .environment(\.locale, SnapshotEnvironment.locale)
            .environment(\.calendar, SnapshotEnvironment.calendar)
            .environment(\.timeZone, SnapshotEnvironment.timeZone)
            .environment(\.colorScheme, colorScheme)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
            .environment(\.layoutDirection, SnapshotEnvironment.layoutDirection)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

extension View {
    func snapshotEnvironment(
        colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
        dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize
    ) -> some View {
        modifier(SnapshotEnvironmentModifier(colorScheme: colorScheme, dynamicTypeSize: dynamicTypeSize))
    }
}
