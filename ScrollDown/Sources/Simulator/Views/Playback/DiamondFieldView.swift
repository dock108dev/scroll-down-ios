//
//  DiamondFieldView.swift
//  ScrollDown
//
//  Animated baseball diamond with player silhouettes on bases.
//  Uses SwiftUI Canvas for the field and overlaid silhouettes.
//

import SwiftUI

struct DiamondFieldView: View {
    let frame: SimFrame

    // Field geometry relative to view
    private let fieldCenter = CGPoint(x: 0.5, y: 0.65)
    private let diamondSize: CGFloat = 0.35

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w * fieldCenter.x
            let cy = h * fieldCenter.y
            let size = min(w, h) * diamondSize

            let homePlate = CGPoint(x: cx, y: cy + size)
            let firstBase = CGPoint(x: cx + size, y: cy)
            let secondBase = CGPoint(x: cx, y: cy - size)
            let thirdBase = CGPoint(x: cx - size, y: cy)
            let mound = CGPoint(x: cx, y: cy + size * 0.15)

            ZStack {
                // Outfield grass
                Ellipse()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: w * 0.9, height: h * 0.7)
                    .position(x: cx, y: cy - size * 0.1)

                // Infield dirt
                diamondPath(home: homePlate, first: firstBase, second: secondBase, third: thirdBase)
                    .fill(Color.brown.opacity(0.12))
                diamondPath(home: homePlate, first: firstBase, second: secondBase, third: thirdBase)
                    .stroke(Color.white.opacity(0.4), lineWidth: 2)

                // Base paths (white lines)
                Path { path in
                    path.move(to: homePlate)
                    path.addLine(to: firstBase)
                    path.addLine(to: secondBase)
                    path.addLine(to: thirdBase)
                    path.addLine(to: homePlate)
                }
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)

                // Bases (squares)
                baseSquare(at: firstBase, occupied: frame.runnersOnBase[0])
                baseSquare(at: secondBase, occupied: frame.runnersOnBase[1])
                baseSquare(at: thirdBase, occupied: frame.runnersOnBase[2])

                // Home plate (pentagon)
                homePlatePath(at: homePlate)
                    .fill(Color.white)
                    .frame(width: 14, height: 14)

                // Pitcher's mound
                Circle()
                    .fill(Color.brown.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .position(mound)

                // Silhouettes
                // Pitcher
                playerSilhouette(
                    at: mound,
                    state: frame.pitcherSilhouette,
                    color: SimulatorTheme.homeColor,
                    label: "P"
                )

                // Batter
                playerSilhouette(
                    at: CGPoint(x: homePlate.x + 20, y: homePlate.y),
                    state: frame.batterSilhouette,
                    color: SimulatorTheme.awayColor,
                    label: frame.outcome.emoji.isEmpty ? "AB" : frame.outcome.emoji
                )

                // Runners on base
                if frame.runnersOnBase[0] {
                    playerSilhouette(
                        at: CGPoint(x: firstBase.x - 10, y: firstBase.y + 10),
                        state: .running,
                        color: SimulatorTheme.awayColor.opacity(0.8),
                        label: ""
                    )
                }
                if frame.runnersOnBase[1] {
                    playerSilhouette(
                        at: CGPoint(x: secondBase.x, y: secondBase.y + 14),
                        state: .running,
                        color: SimulatorTheme.awayColor.opacity(0.8),
                        label: ""
                    )
                }
                if frame.runnersOnBase[2] {
                    playerSilhouette(
                        at: CGPoint(x: thirdBase.x + 10, y: thirdBase.y + 10),
                        state: .running,
                        color: SimulatorTheme.awayColor.opacity(0.8),
                        label: ""
                    )
                }

                // Outs indicator
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < frame.outs ? Color.red : Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                }
                .position(x: cx, y: h - 20)

                // Outcome flash
                if frame.outcome.isHit {
                    Text(frame.outcome.emoji)
                        .font(.title.weight(.bold))
                        .foregroundStyle(SimulatorTheme.awayColor)
                        .position(x: cx, y: cy - size * 0.5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Sub-views

    private func baseSquare(at point: CGPoint, occupied: Bool) -> some View {
        Rectangle()
            .fill(occupied ? Color.yellow : Color.white)
            .frame(width: 12, height: 12)
            .rotationEffect(.degrees(45))
            .shadow(color: occupied ? .yellow.opacity(0.6) : .clear, radius: 6)
            .position(point)
    }

    private func playerSilhouette(at point: CGPoint, state: SilhouetteState, color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            // Head
            Circle()
                .fill(color)
                .frame(width: silhouetteSize(state), height: silhouetteSize(state))

            // Body
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(0.8))
                .frame(width: silhouetteSize(state) * 0.7, height: silhouetteSize(state) * 1.2)

            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color)
            }
        }
        .scaleEffect(silhouetteScale(state))
        .rotationEffect(silhouetteRotation(state))
        .position(point)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: state)
    }

    private func silhouetteSize(_ state: SilhouetteState) -> CGFloat {
        switch state {
        case .celebrating: return 14
        case .running: return 11
        default: return 12
        }
    }

    private func silhouetteScale(_ state: SilhouetteState) -> CGFloat {
        switch state {
        case .celebrating: return 1.2
        case .dejected: return 0.85
        case .swinging: return 1.1
        default: return 1.0
        }
    }

    private func silhouetteRotation(_ state: SilhouetteState) -> Angle {
        switch state {
        case .swinging: return .degrees(-15)
        case .dejected: return .degrees(5)
        default: return .degrees(0)
        }
    }

    // MARK: - Path Helpers

    private func diamondPath(home: CGPoint, first: CGPoint, second: CGPoint, third: CGPoint) -> Path {
        Path { path in
            path.move(to: home)
            path.addLine(to: first)
            path.addLine(to: second)
            path.addLine(to: third)
            path.closeSubpath()
        }
    }

    private func homePlatePath(at point: CGPoint) -> Path {
        Path { path in
            path.move(to: CGPoint(x: point.x, y: point.y - 7))
            path.addLine(to: CGPoint(x: point.x + 7, y: point.y - 2))
            path.addLine(to: CGPoint(x: point.x + 5, y: point.y + 5))
            path.addLine(to: CGPoint(x: point.x - 5, y: point.y + 5))
            path.addLine(to: CGPoint(x: point.x - 7, y: point.y - 2))
            path.closeSubpath()
        }
    }
}
