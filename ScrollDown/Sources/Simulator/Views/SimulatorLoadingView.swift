//
//  SimulatorLoadingView.swift
//  ScrollDown
//
//  Baseball orbiting a diamond path while simulating.
//

import SwiftUI

struct SimulatorLoadingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Diamond path (visual only)
            diamondShape
                .stroke(SimulatorTheme.homeColor.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))

            // Base markers
            ForEach(0..<4, id: \.self) { i in
                let point = diamondPoint(for: i)
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 10, height: 10)
                    .position(point)
            }

            // Orbiting baseball
            let orbitalPoint = orbitingPoint(progress: rotation / 360.0)
            Text("⚾")
                .font(.title)
                .position(orbitalPoint)
                .shadow(color: SimulatorTheme.homeColor.opacity(0.4), radius: 8)

            // Center text
            VStack(spacing: 4) {
                Text("Simulating")
                    .font(.caption.weight(.medium))
                Text("10,000 games")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }

    // MARK: - Diamond Geometry

    private let center = CGPoint(x: 100, y: 100)
    private let size: CGFloat = 60

    private func diamondPoint(for base: Int) -> CGPoint {
        switch base {
        case 0: return CGPoint(x: center.x, y: center.y + size) // home
        case 1: return CGPoint(x: center.x + size, y: center.y) // first
        case 2: return CGPoint(x: center.x, y: center.y - size) // second
        case 3: return CGPoint(x: center.x - size, y: center.y) // third
        default: return center
        }
    }

    private var diamondShape: Path {
        Path { path in
            for i in 0..<4 {
                let p = diamondPoint(for: i)
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    private func orbitingPoint(progress: Double) -> CGPoint {
        let p = progress.truncatingRemainder(dividingBy: 1.0)
        let segment = p * 4
        let segIndex = Int(segment)
        let segFraction = segment - Double(segIndex)

        let from = diamondPoint(for: segIndex % 4)
        let to = diamondPoint(for: (segIndex + 1) % 4)

        return CGPoint(
            x: from.x + (to.x - from.x) * segFraction,
            y: from.y + (to.y - from.y) * segFraction
        )
    }
}
