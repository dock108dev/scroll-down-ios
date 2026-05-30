import SwiftUI

struct WidthAwareContent<Content: View>: View {
    @State private var measuredWidth: CGFloat = 0

    let fallbackWidth: CGFloat
    private let content: (CGFloat) -> Content

    init(fallbackWidth: CGFloat, @ViewBuilder content: @escaping (CGFloat) -> Content) {
        self.fallbackWidth = fallbackWidth
        self.content = content
    }

    var body: some View {
        content(measuredWidth > 0 ? measuredWidth : fallbackWidth)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: AvailableWidthPreferenceKey.self, value: proxy.size.width)
                }
            }
            .onPreferenceChange(AvailableWidthPreferenceKey.self) { measuredWidth = $0 }
    }
}

private struct AvailableWidthPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
