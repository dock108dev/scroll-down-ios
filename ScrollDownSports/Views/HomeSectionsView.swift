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

                    if let emptyState = dateSection.emptyState, dateSection.games.isEmpty {
                        FutureEmptyRow(
                            emptyState: emptyState,
                            hasActiveFilters: hasActiveFilters,
                            clearFilters: clearFilters
                        )
                    } else {
                        ForEach(dateSection.games) { item in
                            row(item)
                                .id(item.homeAnchorID)
                        }
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
                    .foregroundStyle(SportsTheme.Tone.neutral.foreground)
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
        .accessibilityIdentifier("home.empty.timeline")
    }
}

private struct FutureEmptyRow: View {
    let emptyState: HomeTimelineEmptyState
    let hasActiveFilters: Bool
    let clearFilters: () -> Void

    private var title: String {
        switch emptyState {
        case .laterToday:
            return hasActiveFilters ? "No matching games later today." : "No games later today."
        case .upcoming:
            return hasActiveFilters ? "No matching upcoming games." : "No upcoming games."
        }
    }

    private var detail: String {
        switch emptyState {
        case .laterToday:
            if hasActiveFilters {
                return "Clear filters to check the full remaining slate."
            }
            return "Upcoming games will appear here when the schedule is available."
        case .upcoming:
            if hasActiveFilters {
                return "Clear filters to check every scheduled matchup."
            }
            return "Pull to refresh for the next scheduled slate."
        }
    }

    private var accessibilityID: String {
        switch emptyState {
        case .laterToday:
            return "home.empty.laterToday"
        case .upcoming:
            return "home.empty.upcoming"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(SportsTheme.Tone.neutral.foreground)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(SportsTheme.Colors.secondaryInk)
            }

            Text(detail)
                .font(SportsTheme.Typography.metadata)
                .foregroundStyle(SportsTheme.Colors.secondaryInk)

            if hasActiveFilters {
                Button("Clear filters") {
                    SportsFeedback.selection()
                    clearFilters()
                }
                .buttonStyle(.sportsControl(tone: .scoreboard, compact: true))
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sportsSurface(.eventCard)
        .accessibilityIdentifier(accessibilityID)
    }
}

struct NoGamesEmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No games available",
            systemImage: "calendar",
            description: Text("Pull to refresh or check back when the next slate is available.")
        )
        .accessibilityIdentifier("home.empty.noGames")
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
        .accessibilityIdentifier("home.empty.filtered")
    }
}

struct InlineErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(SportsTheme.Tone.critical.foreground)
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
        .accessibilityIdentifier("home.error.inline")
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
        .accessibilityIdentifier("home.empty.error")
    }
}
