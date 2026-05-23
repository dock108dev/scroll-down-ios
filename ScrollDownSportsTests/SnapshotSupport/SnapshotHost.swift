import SwiftUI

struct SnapshotHost<Content: View>: View {
    let width: CGFloat
    let colorScheme: ColorScheme
    let dynamicTypeSize: DynamicTypeSize
    @ViewBuilder let content: Content

    init(
        width: CGFloat,
        colorScheme: ColorScheme = SnapshotEnvironment.colorScheme,
        dynamicTypeSize: DynamicTypeSize = SnapshotEnvironment.dynamicTypeSize,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.colorScheme = colorScheme
        self.dynamicTypeSize = dynamicTypeSize
        self.content = content()
    }

    var body: some View {
        content
            .snapshotEnvironment(colorScheme: colorScheme, dynamicTypeSize: dynamicTypeSize)
            .frame(width: width, alignment: .topLeading)
            .fixedSize(horizontal: false, vertical: true)
    }
}
