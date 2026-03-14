//
//  PitcherProfileView.swift
//  ScrollDown
//
//  4-axis spider/radar chart for pitcher profile (K, BB, Contact, Power).
//

import SwiftUI

struct PitcherProfileView: View {
    let pitcher: PitcherProfileInfo
    let profile: [String: Double]
    let teamName: String
    let color: Color

    private let axes = ["strikeout", "walk", "single", "hr"]
    private let axisLabels = ["K Rate", "BB Rate", "Contact", "HR Rate"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pitcher.name ?? "Starter")
                        .font(.subheadline.weight(.semibold))
                    Text(teamName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let ip = pitcher.avgIp {
                    Text(String(format: "%.1f avg IP", ip))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Spider chart
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = min(geo.size.width, geo.size.height) / 2 - 24

                ZStack {
                    // Grid rings
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { ring in
                        radarPath(values: Array(repeating: ring, count: 4), center: center, radius: radius)
                            .stroke(SimulatorTheme.radarStroke.opacity(0.3), lineWidth: 0.5)
                    }

                    // Axis lines
                    ForEach(0..<4, id: \.self) { i in
                        let angle = angleFor(index: i)
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: pointAt(angle: angle, radius: radius, center: center))
                        }
                        .stroke(SimulatorTheme.radarStroke.opacity(0.3), lineWidth: 0.5)
                    }

                    // Data polygon
                    radarPath(values: normalizedValues, center: center, radius: radius)
                        .fill(color.opacity(0.2))
                    radarPath(values: normalizedValues, center: center, radius: radius)
                        .stroke(color, lineWidth: 2)

                    // Data points
                    ForEach(0..<4, id: \.self) { i in
                        let angle = angleFor(index: i)
                        let r = radius * normalizedValues[i]
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .position(pointAt(angle: angle, radius: r, center: center))
                    }

                    // Labels
                    ForEach(0..<4, id: \.self) { i in
                        let angle = angleFor(index: i)
                        let labelPos = pointAt(angle: angle, radius: radius + 16, center: center)
                        Text(axisLabels[i])
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .position(labelPos)
                    }
                }
            }
            .frame(height: 180)

            // Stat values
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    let key = axes[i]
                    if let val = profile[key] {
                        VStack(spacing: 2) {
                            Text(axisLabels[i])
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.3f", val))
                                .font(.caption.weight(.medium).monospacedDigit())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var normalizedValues: [Double] {
        // Normalize each axis to 0-1 range using reasonable baseball ranges
        let ranges: [(min: Double, max: Double)] = [
            (0.10, 0.40),  // K rate
            (0.03, 0.15),  // BB rate
            (0.15, 0.35),  // single rate
            (0.01, 0.08)   // HR rate
        ]
        return axes.enumerated().map { i, key in
            let val = profile[key] ?? 0
            let r = ranges[i]
            return min(1, max(0, (val - r.min) / (r.max - r.min)))
        }
    }

    private func angleFor(index: Int) -> Double {
        Double(index) * (.pi * 2.0 / 4.0) - .pi / 2
    }

    private func pointAt(angle: Double, radius: Double, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
        )
    }

    private func radarPath(values: [Double], center: CGPoint, radius: Double) -> Path {
        Path { path in
            for (i, val) in values.enumerated() {
                let angle = angleFor(index: i)
                let point = pointAt(angle: angle, radius: radius * val, center: center)
                if i == 0 { path.move(to: point) }
                else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}
