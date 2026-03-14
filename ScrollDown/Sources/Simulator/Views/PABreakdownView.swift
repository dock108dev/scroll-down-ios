//
//  PABreakdownView.swift
//  ScrollDown
//
//  Animated ring/donut chart for PA outcome probabilities using Circle().trim().
//

import SwiftUI

struct PABreakdownView: View {
    let probabilities: [String: Double]
    let teamName: String
    let color: Color

    @State private var animationProgress: Double = 0

    private var segments: [(label: String, value: Double, color: Color)] {
        let keyOrder = ["hr", "triple", "double", "single", "walk", "strikeout"]
        let colorMap: [String: Color] = [
            "hr": SimulatorTheme.hrColor,
            "triple": SimulatorTheme.tripleColor,
            "double": SimulatorTheme.doubleColor,
            "single": SimulatorTheme.singleColor,
            "walk": SimulatorTheme.walkColor,
            "strikeout": SimulatorTheme.strikeoutColor
        ]

        var result: [(label: String, value: Double, color: Color)] = []
        var otherValue: Double = 0

        for key in keyOrder {
            if let val = probabilities[key], val > 0 {
                result.append((label: key.capitalized, value: val, color: colorMap[key] ?? SimulatorTheme.otherOutColor))
            }
        }

        // Remaining keys go into "Other"
        for (key, val) in probabilities where !keyOrder.contains(key) && val > 0 {
            otherValue += val
        }
        if otherValue > 0 {
            result.append((label: "Other", value: otherValue, color: SimulatorTheme.otherOutColor))
        }

        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("\(teamName) PA Breakdown")
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 20) {
                // Donut chart
                ZStack {
                    ForEach(Array(segmentData.enumerated()), id: \.offset) { index, seg in
                        Circle()
                            .trim(from: seg.start * animationProgress, to: seg.end * animationProgress)
                            .stroke(seg.color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: 100, height: 100)

                // Legend
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(segments, id: \.label) { seg in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(seg.color)
                                .frame(width: 8, height: 8)
                            Text(seg.label)
                                .font(.caption2)
                            Spacer()
                            Text(String(format: "%.1f%%", seg.value * 100))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animationProgress = 1
            }
        }
    }

    private var segmentData: [(start: Double, end: Double, color: Color)] {
        let total = segments.reduce(0.0) { $0 + $1.value }
        guard total > 0 else { return [] }
        var current: Double = 0
        return segments.map { seg in
            let fraction = seg.value / total
            let start = current
            current += fraction
            return (start: start, end: current, color: seg.color)
        }
    }
}
