import SwiftUI
@testable import ScrollDownSports

struct SnapshotHost<Content: View>: View {
    let width: CGFloat
    let minHeight: CGFloat?
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
    let colorScheme: ColorScheme
    let dynamicTypeSize: DynamicTypeSize
    @ViewBuilder let content: Content

    init(
        width: CGFloat,
        minHeight: CGFloat? = nil,
        horizontalSizeClass: UserInterfaceSizeClass? = nil,
        verticalSizeClass: UserInterfaceSizeClass? = nil,
        colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
        dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.minHeight = minHeight
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        self.colorScheme = colorScheme
        self.dynamicTypeSize = dynamicTypeSize
        self.content = content()
    }

    var body: some View {
        content
            .snapshotEnvironment(
                colorScheme: colorScheme,
                dynamicTypeSize: dynamicTypeSize,
                horizontalSizeClass: horizontalSizeClass,
                verticalSizeClass: verticalSizeClass
            )
            .environment(
                \.sportsLayoutMetrics,
                SportsLayoutMetrics(
                    availableWidth: width,
                    availableHeight: minHeight,
                    horizontalSizeClass: horizontalSizeClass,
                    verticalSizeClass: verticalSizeClass,
                    dynamicTypeSize: dynamicTypeSize
                )
            )
            .frame(width: width, alignment: .topLeading)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
