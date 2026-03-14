//
//  PulsingDotView.swift
//  ScrollDown
//
//  Reusable live indicator with repeating opacity/scale animation.
//

import SwiftUI

struct PulsingDotView: View {
    var color: Color = .red
    var size: CGFloat = 6

    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.5 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
