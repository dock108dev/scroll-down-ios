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
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?

    func body(content: Content) -> some View {
        content
            .environment(\.locale, SnapshotEnvironment.locale)
            .environment(\.calendar, SnapshotEnvironment.calendar)
            .environment(\.timeZone, SnapshotEnvironment.timeZone)
            .environment(\.colorScheme, colorScheme)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
            .environment(\.layoutDirection, SnapshotEnvironment.layoutDirection)
            .environment(\.horizontalSizeClass, horizontalSizeClass)
            .environment(\.verticalSizeClass, verticalSizeClass)
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

extension View {
    func snapshotEnvironment(
        colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
        dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize,
        horizontalSizeClass: UserInterfaceSizeClass? = nil,
        verticalSizeClass: UserInterfaceSizeClass? = nil
    ) -> some View {
        modifier(
            SnapshotEnvironmentModifier(
                colorScheme: colorScheme,
                dynamicTypeSize: dynamicTypeSize,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
        )
    }
}
