import SwiftUI
import UIKit

struct HomeStickyHeader: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.sportsLayoutMetrics) private var layout

    var body: some View {
        FilterHeader(viewModel: viewModel)
            .sportsReadableContent()
            .padding(.top, layout.stickyHeaderTopPadding)
            .padding(.bottom, layout.stickyHeaderBottomPadding)
            .background(SportsTheme.Colors.paper)
            .overlay(alignment: .bottom) {
                Divider()
                    .overlay(SportsTheme.Colors.hairline)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home.stickyHeader")
    }
}

private struct FilterHeader: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.sportsLayoutMetrics) private var layout
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @FocusState private var isTeamSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: HomeFilterLayout.shelfVerticalSpacing) {
            if usesInlineControls {
                HStack(alignment: .center, spacing: HomeFilterLayout.controlSpacing) {
                    leagueControl
                        .frame(width: leagueControlWidth, alignment: .leading)
                    teamSearchField
                        .frame(minWidth: HomeFilterLayout.inlineTeamSearchMinimumWidth, maxWidth: teamSearchMaxWidth)
                    Spacer(minLength: 0)
                    updatedMetadata
                }
            } else if usesCompactControlRow {
                HStack(alignment: .center, spacing: HomeFilterLayout.controlSpacing) {
                    leagueControl
                        .frame(width: HomeFilterLayout.compactLeagueMenuWidth, alignment: .leading)
                    teamSearchField
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                updatedMetadata
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                leagueControl
                    .frame(maxWidth: leagueControlMaxWidth, alignment: .leading)
                teamSearchField
                    .frame(maxWidth: teamSearchMaxWidth, alignment: .leading)
                updatedMetadata
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var leagueControl: some View {
        switch leagueFilterPresentation {
        case .menu:
            leagueMenu
        case .segmented:
            leagueSegmentedPicker
        }
    }

    private var leagueMenu: some View {
        Menu {
            ForEach(LeagueFilter.allCases) { league in
                Button {
                    viewModel.league = league
                } label: {
                    if viewModel.league == league {
                        Label(league.menuTitle, systemImage: "checkmark")
                    } else {
                        Text(league.menuTitle)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text("League")
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                Text(viewModel.league.displayName)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
            .font(HomeFilterLayout.controlFont)
            .modifier(HomeShelfControlChrome())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.leaguePicker")
        .accessibilityLabel("League")
        .accessibilityValue(viewModel.league.displayName)
    }

    private var leagueSegmentedPicker: some View {
        Picker("League", selection: $viewModel.league) {
            ForEach(LeagueFilter.allCases) { league in
                Text(league.segmentedTitle).tag(league)
            }
        }
        .pickerStyle(.segmented)
        .font(HomeFilterLayout.controlFont)
        .frame(minHeight: HomeFilterLayout.controlMinHeight)
        .accessibilityIdentifier("home.leaguePicker")
    }

    private var teamSearchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.bold))
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .accessibilityHidden(true)

            TextField("Filter by team", text: $viewModel.teamQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isTeamSearchFocused)
                .font(HomeFilterLayout.controlFont)
                .lineLimit(1)
                .accessibilityLabel("Filter by team")
                .accessibilityIdentifier("home.teamFilter")
                .onSubmit {
                    isTeamSearchFocused = false
                }

            if !viewModel.teamQuery.isEmpty {
                Button {
                    viewModel.teamQuery = ""
                    SportsFeedback.selection()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(SportsTheme.Colors.secondaryInk)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear team filter")
            }
        }
        .modifier(
            HomeShelfControlChrome(
                stroke: teamSearchStroke,
                lineWidth: isTeamSearchFocused ? 1.4 : SportsTheme.Stroke.standard,
                backgroundOpacity: isTeamSearchFocused ? 1 : 0.82
            )
        )
        .animation(.snappy(duration: 0.16), value: isTeamSearchFocused)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isTeamSearchFocused = false
                }
                .accessibilityIdentifier("home.teamFilter.done")
            }
        }
    }

    @ViewBuilder
    private var updatedMetadata: some View {
        if let lastUpdated = viewModel.lastUpdated {
            Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                .font(HomeFilterLayout.metadataFont)
                .foregroundStyle(SportsTheme.Colors.secondaryInk.opacity(0.86))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
    }

    private var usesInlineControls: Bool {
        layout.homeContentWidth >= 640 && !dynamicTypeSize.isAccessibilitySize
    }

    private var usesCompactControlRow: Bool {
        leagueFilterPresentation == .menu
            && !dynamicTypeSize.isAccessibilitySize
            && layout.homeContentWidth >= HomeFilterLayout.compactRowMinimumWidth
    }

    private var leagueFilterPresentation: LeagueFilterPresentation {
        LeagueFilterPresentationResolver.presentation(
            availableWidth: layout.homeContentWidth,
            isInline: usesInlineControls,
            dynamicTypeSize: dynamicTypeSize,
            verticalSizeClass: verticalSizeClass
        )
    }

    private var leagueControlWidth: CGFloat {
        switch leagueFilterPresentation {
        case .menu:
            return HomeFilterLayout.inlineLeagueMenuWidth
        case .segmented:
            return LeagueFilterPresentationResolver.requiredSegmentedWidth(dynamicTypeSize: dynamicTypeSize)
        }
    }

    private var leagueControlMaxWidth: CGFloat {
        switch leagueFilterPresentation {
        case .menu:
            return usesInlineControls ? HomeFilterLayout.inlineLeagueMenuWidth : .infinity
        case .segmented:
            if usesInlineControls {
                return LeagueFilterPresentationResolver.requiredSegmentedWidth(dynamicTypeSize: dynamicTypeSize)
            }
            return .infinity
        }
    }

    private var teamSearchMaxWidth: CGFloat {
        usesInlineControls ? 360 : .infinity
    }

    private var teamSearchStroke: Color {
        if isTeamSearchFocused {
            return SportsTheme.Colors.ink.opacity(0.42)
        }
        return SportsTheme.Stroke.subdued()
    }
}

private struct HomeShelfControlChrome: ViewModifier {
    var stroke = SportsTheme.Stroke.subdued()
    var lineWidth = SportsTheme.Stroke.standard
    var backgroundOpacity = 0.82

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .frame(minHeight: HomeFilterLayout.controlMinHeight, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                SportsTheme.Colors.paperInset.opacity(backgroundOpacity),
                in: RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SportsTheme.Radius.control, style: .continuous)
                    .stroke(stroke, lineWidth: lineWidth)
            }
            .contentShape(Rectangle())
    }
}

private enum HomeFilterLayout {
    static let controlMinHeight: CGFloat = 44
    static let controlSpacing: CGFloat = 8
    static let shelfVerticalSpacing: CGFloat = 5
    static let inlineControlSpacing = controlSpacing
    static let inlineTeamSearchMinimumWidth: CGFloat = 180
    static let inlineLeagueMenuWidth: CGFloat = 176
    static let compactLeagueMenuWidth: CGFloat = 136
    static let compactRowMinimumWidth: CGFloat = 300
    static let stackedSegmentedMinimumWidth: CGFloat = 560
    static let controlFont = Font.subheadline.weight(.semibold)
    static let metadataFont = Font.caption2.weight(.semibold)
}

private enum LeagueFilterPresentation: Equatable {
    case segmented
    case menu
}

private enum LeagueFilterPresentationResolver {
    private static let segmentHorizontalPadding: CGFloat = 12
    private static let segmentDividerWidth: CGFloat = 1
    private static let safetyMargin: CGFloat = 24

    static func presentation(
        availableWidth: CGFloat,
        isInline: Bool,
        dynamicTypeSize: DynamicTypeSize,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> LeagueFilterPresentation {
        if dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact {
            return .menu
        }

        if !isInline && availableWidth < HomeFilterLayout.stackedSegmentedMinimumWidth {
            return .menu
        }

        let effectiveLeagueWidth = isInline
            ? availableWidth - HomeFilterLayout.inlineControlSpacing - HomeFilterLayout.inlineTeamSearchMinimumWidth
            : availableWidth

        if max(0, effectiveLeagueWidth) < requiredSegmentedWidth(dynamicTypeSize: dynamicTypeSize) {
            return .menu
        }

        return .segmented
    }

    static func requiredSegmentedWidth(dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let labelWidths = LeagueFilter.allCases.reduce(CGFloat.zero) { total, league in
            total + textWidth(league.segmentedTitle, dynamicTypeSize: dynamicTypeSize)
        }
        let segmentCount = CGFloat(LeagueFilter.allCases.count)

        return labelWidths
            + segmentCount * segmentHorizontalPadding * 2
            + max(0, segmentCount - 1) * segmentDividerWidth
            + safetyMargin
    }

    private static func textWidth(_ text: String, dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let font = UIFont.preferredFont(
            forTextStyle: .subheadline,
            compatibleWith: UITraitCollection(preferredContentSizeCategory: contentSizeCategory(for: dynamicTypeSize))
        )
        return ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }

    private static func contentSizeCategory(for dynamicTypeSize: DynamicTypeSize) -> UIContentSizeCategory {
        switch dynamicTypeSize {
        case .xSmall:
            return .extraSmall
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .xLarge:
            return .extraLarge
        case .xxLarge:
            return .extraExtraLarge
        case .xxxLarge:
            return .extraExtraExtraLarge
        case .accessibility1:
            return .accessibilityMedium
        case .accessibility2:
            return .accessibilityLarge
        case .accessibility3:
            return .accessibilityExtraLarge
        case .accessibility4:
            return .accessibilityExtraExtraLarge
        case .accessibility5:
            return .accessibilityExtraExtraExtraLarge
        @unknown default:
            return .large
        }
    }
}
