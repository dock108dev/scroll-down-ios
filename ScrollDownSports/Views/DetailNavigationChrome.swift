import SwiftUI

struct DetailStickyNavigationBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sportsLayoutMetrics) private var layout

    let title: String
    let progressLabel: String?
    let endLabel: String
    let returnLabel: String?
    let onTop: () -> Void
    let onEnd: () -> Void
    let onReturn: () -> Void

    init(
        title: String,
        progressLabel: String? = nil,
        endLabel: String,
        returnLabel: String?,
        onTop: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        onReturn: @escaping () -> Void
    ) {
        self.title = title
        self.progressLabel = progressLabel
        self.endLabel = endLabel
        self.returnLabel = returnLabel
        self.onTop = onTop
        self.onEnd = onEnd
        self.onReturn = onReturn
    }

    var body: some View {
        let density = DetailChromeDensity.resolve(
            dynamicTypeSize: dynamicTypeSize,
            availableWidth: layout.detailContentWidth,
            contentWeight: contentWeight
        )

        Group {
            switch density {
            case .regular:
                regularLayout
            case .compact:
                compactLayout
            case .stacked:
                stackedLayout
            case .accessibility:
                accessibilityLayout
            }
        }
        .overlay(alignment: .topLeading) {
            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(stickyAccessibilityLabel)
                .accessibilityIdentifier("detail.stickyNav")
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 7) {
            if let returnLabel {
                returnButton(label: returnLabel, compact: true)
                contextProgressCluster(lineLimit: 1, progressLabel: progressLabel)
            } else {
                contextProgressCluster(lineLimit: 2, progressLabel: progressLabel)

                Spacer(minLength: 0)

                topButton(label: "Top", compact: true, includesIcon: true)
            }

            Spacer(minLength: 0)

            endButton(label: endLabel, compact: true, includesIcon: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(SportsTheme.Colors.paperRaised, in: Capsule())
        .overlay {
            Capsule().strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
    }

    private var compactLayout: some View {
        HStack(spacing: 7) {
            if let returnLabel {
                returnButton(label: DetailChromeLabelFormatter.shortReturnLabel(returnLabel), compact: true)
                contextProgressCluster(
                    lineLimit: 1,
                    progressLabel: progressLabel.map(DetailChromeLabelFormatter.shortProgressLabel)
                )
            } else {
                contextProgressCluster(
                    lineLimit: 1,
                    progressLabel: progressLabel.map(DetailChromeLabelFormatter.shortProgressLabel)
                )

                Spacer(minLength: 0)

                topButton(label: "Top", compact: true, includesIcon: true)
            }

            Spacer(minLength: 0)

            endButton(label: DetailChromeLabelFormatter.shortEndLabel(endLabel), compact: true, includesIcon: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(SportsTheme.Colors.paperRaised, in: Capsule())
        .overlay {
            Capsule().strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
    }

    private var stackedLayout: some View {
        VStack(alignment: .leading, spacing: 7) {
            contextProgressStack(lineLimit: 1, progressLabel: progressLabel.map(DetailChromeLabelFormatter.shortProgressLabel))

            HStack(spacing: 8) {
                if let returnLabel {
                    returnButton(label: DetailChromeLabelFormatter.shortReturnLabel(returnLabel), compact: false)
                        .frame(maxWidth: .infinity)
                } else {
                    topButton(label: "Top", compact: false, includesIcon: true)
                        .frame(maxWidth: .infinity)
                }

                endButton(label: DetailChromeLabelFormatter.shortEndLabel(endLabel), compact: false, includesIcon: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                .strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            contextProgressStack(lineLimit: 2, progressLabel: progressLabel)

            if let returnLabel {
                returnButton(label: returnLabel, compact: false)
                    .frame(maxWidth: .infinity)
            } else {
                topButton(label: "Top", compact: false, includesIcon: true)
                    .frame(maxWidth: .infinity)
            }

            endButton(label: endLabel, compact: false, includesIcon: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(SportsTheme.Colors.paperRaised, in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                .strokeBorder(SportsTheme.Colors.hairline.opacity(0.7), lineWidth: 1)
        }
    }

    @ViewBuilder
    private func contextProgressCluster(lineLimit: Int, progressLabel: String?) -> some View {
        if AppEnvironment.isRunningUITests {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(.leading)

                if let progressLabel {
                    Text(progressLabel)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(1)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func contextProgressStack(lineLimit: Int, progressLabel: String?) -> some View {
        if AppEnvironment.isRunningUITests {
            Color.clear
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(lineLimit)
                    .fixedSize(horizontal: false, vertical: true)

                if let progressLabel {
                    Text(progressLabel)
                        .font(SportsTheme.Typography.metadata)
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .lineLimit(1)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func returnButton(label: String, compact: Bool) -> some View {
        Button {
            SportsFeedback.impact()
            onReturn()
        } label: {
            if compact {
                Label(label, systemImage: "arrow.uturn.backward")
                    .lineLimit(1)
            } else {
                Label(label, systemImage: "arrow.uturn.backward")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.sportsControl(tone: .neutral, compact: compact))
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(returnLabel ?? label)
        .accessibilityIdentifier("detail.stickyNav.return")
    }

    private func topButton(label: String, compact: Bool, includesIcon: Bool) -> some View {
        Button {
            SportsFeedback.selection()
            onTop()
        } label: {
            if includesIcon {
                Label(label, systemImage: "arrow.up.to.line")
                    .lineLimit(1)
                    .frame(maxWidth: compact ? nil : .infinity)
            } else {
                Text(label)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.sportsControl(tone: .neutral, compact: compact))
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityIdentifier("detail.stickyNav.top")
    }

    private func endButton(label: String, compact: Bool, includesIcon: Bool) -> some View {
        Button {
            SportsFeedback.selection()
            onEnd()
        } label: {
            if includesIcon {
                Label(label, systemImage: "arrow.down.to.line")
                    .lineLimit(1)
                    .frame(maxWidth: compact ? nil : .infinity)
            } else {
                Text(label)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.sportsControl(tone: .neutral, compact: compact))
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(endLabel)
        .accessibilityIdentifier("detail.stickyNav.end")
    }

    private var stickyAccessibilityLabel: String {
        var parts = [title]
        if let progressLabel = progressLabel?.nilIfBlank {
            parts.append(progressLabel)
        }
        return parts.joined(separator: ", ")
    }

    private var contentWeight: CGFloat {
        var weight: CGFloat = 1
        if returnLabel != nil {
            weight += 0.25
        }
        if endLabel.count > 6 {
            weight += 0.20
        }
        if let progressLabel, progressLabel.count > 8 {
            weight += 0.12
        }
        if title.count > 22 {
            weight += 0.20
        }
        return weight
    }
}

struct NewPlaysAffordance: View {
    let count: Int
    let onJumpLatest: () -> Void

    var body: some View {
        Button {
            SportsFeedback.impact()
            onJumpLatest()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.down.to.line")
                    .font(SportsTheme.Typography.metadata)
                    .accessibilityHidden(true)
                Text(count == 1 ? "1 new" : "\(count) new")
                    .font(SportsTheme.Typography.metadata)
                Text("·")
                    .font(SportsTheme.Typography.metadata)
                    .opacity(0.8)
                    .accessibilityHidden(true)
                Text("jump latest")
                    .font(SportsTheme.Typography.metadata)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .fill(SportsTheme.Tone.newPlay.accent)
            )
            .shadow(color: .black.opacity(0.14), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityLabel(count == 1 ? "1 new play. Jump to latest" : "\(count) new plays. Jump to latest")
        .accessibilityIdentifier("detail.newPlaysAffordance")
    }
}
