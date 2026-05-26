import SwiftUI

struct HomeViewportSizePreferenceKey: PreferenceKey {
    static let defaultValue = CGSize.zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

struct HomeViewportSizeReader: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: HomeViewportSizePreferenceKey.self, value: geometry.size)
        }
    }
}

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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @FocusState private var isTeamSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if usesInlineControls {
                HStack(alignment: .center, spacing: 10) {
                    leagueControl
                        .frame(maxWidth: leagueControlMaxWidth, alignment: .leading)
                    teamSearchField
                        .frame(maxWidth: teamSearchMaxWidth, alignment: .leading)
                    Spacer(minLength: 0)
                }
            } else {
                leagueControl
                    .frame(maxWidth: leagueControlMaxWidth, alignment: .leading)
                teamSearchField
                    .frame(maxWidth: teamSearchMaxWidth, alignment: .leading)
            }

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var leagueControl: some View {
        if usesLeagueMenu {
            Menu {
                ForEach(LeagueFilter.allCases) { league in
                    Button {
                        viewModel.league = league
                    } label: {
                        if viewModel.league == league {
                            Label(league.rawValue, systemImage: "checkmark")
                        } else {
                            Text(league.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.league.rawValue)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: HomeFilterLayout.controlMinHeight)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.sportsControl(tone: .scoreboard, compact: true))
            .accessibilityIdentifier("home.leaguePicker")
            .accessibilityLabel("League")
            .accessibilityValue(viewModel.league.rawValue)
        } else {
            Picker("League", selection: $viewModel.league) {
                ForEach(LeagueFilter.allCases) { league in
                    Text(league.rawValue).tag(league)
                }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: HomeFilterLayout.controlMinHeight)
            .accessibilityIdentifier("home.leaguePicker")
        }
    }

    private var teamSearchField: some View {
        TextField("Filter by team", text: $viewModel.teamQuery)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($isTeamSearchFocused)
            .font(SportsTheme.Typography.teamName)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(minHeight: HomeFilterLayout.controlMinHeight, alignment: .leading)
            .background(
                SportsTheme.Colors.paperRaised,
                in: RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: SportsTheme.Radius.card, style: .continuous)
                    .stroke(SportsTheme.Stroke.subdued(), lineWidth: SportsTheme.Stroke.standard)
            }
            .accessibilityLabel("Filter by team")
            .accessibilityIdentifier("home.teamFilter")
            .onSubmit {
                isTeamSearchFocused = false
            }
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

    private var usesInlineControls: Bool {
        layout.homeContentWidth >= 640 && !dynamicTypeSize.isAccessibilitySize
    }

    private var usesLeagueMenu: Bool {
        dynamicTypeSize.isAccessibilitySize
            || verticalSizeClass == .compact
            || layout.homeContentWidth < 360
            || (horizontalSizeClass == .compact && layout.availableWidth > 430)
    }

    private var leagueControlMaxWidth: CGFloat {
        if usesLeagueMenu {
            if dynamicTypeSize.isAccessibilitySize {
                return 220
            }
            return usesInlineControls ? 180 : 132
        }
        return usesInlineControls ? 300 : .infinity
    }

    private var teamSearchMaxWidth: CGFloat {
        usesInlineControls ? 360 : .infinity
    }
}

private enum HomeFilterLayout {
    static let controlMinHeight: CGFloat = 44
}

struct PinnedSectionView<Row: View>: View {
    let section: HomePinnedSection
    let row: (HomeGameItem) -> Row
    @Environment(\.sportsLayoutMetrics) private var layout

    var body: some View {
        VStack(alignment: .leading, spacing: layout.rowSpacing) {
            HomeSectionHeader(
                title: section.title,
                subtitle: "Saved and live-tracked games",
                systemImage: "pin.fill",
                accent: SportsTheme.Tone.pinned.accent
            )
                .id("pinned")
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("home.section.pinned")

            ForEach(section.games) { item in
                row(item)
            }
        }
        .padding(.top, 6)
    }
}

struct TimelineSectionView<Row: View>: View {
    let section: HomeTimelineFeedSection
    let hasActiveFilters: Bool
    let clearFilters: () -> Void
    let row: (HomeGameItem) -> Row
    @Environment(\.sportsLayoutMetrics) private var layout

    var body: some View {
        VStack(alignment: .leading, spacing: layout.rowSpacing) {
            HomeSectionHeader(title: section.title, subtitle: "Last 72 hours", systemImage: "clock.arrow.circlepath")
                .id("timeline")
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("home.section.timeline")

            if section.dateSections.isEmpty {
                TodayEmptyRow(hasActiveFilters: hasActiveFilters, clearFilters: clearFilters)
            } else {
                ForEach(section.dateSections) { dateSection in
                    NestedDateHeader(section: dateSection)
                        .id(dateSection.id)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("home.dateSection.\(dateSection.id)")
                        .padding(.top, 4)

                    ForEach(dateSection.games) { item in
                        row(item)
                    }
                }
            }
        }
        .padding(.top, 6)
    }
}

private struct HomeSectionHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var accent: Color = SportsTheme.Tone.newPlay.accent

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SportsTheme.Typography.sectionTitle)
                    .foregroundStyle(SportsTheme.Colors.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NestedDateHeader: View {
    let section: HomeTimelineSection

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(section.title)
                .font(SportsTheme.Typography.teamName)
                .foregroundStyle(SportsTheme.Colors.ink)
                .lineLimit(2)
            Text(section.subtitle)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .textCase(nil)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TodayEmptyRow: View {
    let hasActiveFilters: Bool
    let clearFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .foregroundStyle(SportsTheme.Tone.neutral.accent)
                    .accessibilityHidden(true)
                Text("No games on today's slate for these filters.")
                    .font(.subheadline)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }

            if hasActiveFilters {
                Button("Clear filters") {
                    SportsFeedback.selection()
                    clearFilters()
                }
                .buttonStyle(.sportsControl(tone: .scoreboard, compact: true))
                .controlSize(.small)
            } else {
                Text("Pull to refresh or browse earlier games below.")
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.eventCard)
    }
}

struct FilteredEmptyState: View {
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "No games match these filters",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Clear filters to return to today's slate.")
            )
            Button("Clear filters") {
                SportsFeedback.selection()
                clearFilters()
            }
            .buttonStyle(.sportsControl(tone: .scoreboard, filled: true))
        }
    }
}

struct InlineErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(SportsTheme.Tone.critical.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("Showing last known games")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SportsTheme.Colors.ink)
                Text(message)
                    .font(SportsTheme.Typography.metadata)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
                Button("Retry") {
                    SportsFeedback.impact()
                    retry()
                }
                .buttonStyle(.sportsControl(tone: .critical, compact: true))
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.eventCard, accent: SportsTheme.Tone.critical.accent)
    }
}

struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "Unable to load games",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
            Button("Retry") {
                SportsFeedback.impact()
                retry()
            }
            .buttonStyle(.sportsControl(tone: .critical, filled: true))
        }
    }
}
