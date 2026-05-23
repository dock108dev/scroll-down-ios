import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    FilterHeader(viewModel: viewModel)
                        .padding(.bottom, 4)

                    if viewModel.loading && viewModel.games.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                    } else if let error = viewModel.errorMessage, viewModel.games.isEmpty {
                        ErrorState(message: error) {
                            Task { await viewModel.refresh() }
                        }
                        .frame(maxWidth: .infinity, minHeight: 220)
                    } else if visibleGameCount == 0 && !hasTodaySection {
                        EmptyState()
                            .frame(maxWidth: .infinity, minHeight: 220)
                    } else {
                        ForEach(viewModel.filteredTimelineSections) { section in
                            TimelineDayHeader(section: section)
                                .id(section.id)
                                .padding(.top, section.isToday ? 8 : 16)

                            if section.games.isEmpty {
                                if section.isToday {
                                    TodayEmptyRow()
                                }
                            } else {
                                ForEach(section.games) { game in
                                    NavigationLink {
                                        GameDetailView(gameId: game.id, summary: game)
                                    } label: {
                                        GameRowView(game: game)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemTeal).opacity(0.08),
                        Color(.systemOrange).opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                guard !AppEnvironment.isRunningTests else { return }
                await viewModel.refresh()
                viewModel.startAutoRefresh()
            }
            .onDisappear {
                viewModel.stopAutoRefresh()
            }
            .onChange(of: viewModel.league) { _, _ in
                Task { await viewModel.refresh() }
            }
            .onChange(of: viewModel.anchorToken) { _, _ in
                scrollToToday(proxy)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.loading)
                }
            }
        }
    }

    private var visibleGameCount: Int {
        viewModel.filteredTimelineSections.reduce(0) { $0 + $1.games.count }
    }

    private var hasTodaySection: Bool {
        viewModel.filteredTimelineSections.contains { $0.isToday }
    }

    private func scrollToToday(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.35)) {
                proxy.scrollTo(viewModel.todaySectionID, anchor: .top)
            }
        }
    }
}

private struct FilterHeader: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("League", selection: $viewModel.league) {
                ForEach(LeagueFilter.allCases) { league in
                    Text(league.rawValue).tag(league)
                }
            }
            .pickerStyle(.segmented)

            TextField("Filter by team", text: $viewModel.teamQuery)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct GameRowView: View {
    let game: GameSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(leagueColor)
                .frame(width: 4)
                .padding(.vertical, 3)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(game.leagueCode.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(leagueColor)
                    Text(DateFormatters.timeOnly.string(from: game.gameDate))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    if let liveText {
                        Text(liveText)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(Color(.systemRed), in: Capsule())
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 3) {
                    TeamLine(abbreviation: game.awayTeamAbbr, name: game.awayTeam)
                    TeamLine(abbreviation: game.homeTeamAbbr, name: game.homeTeam)
                }

                HStack(spacing: 6) {
                    Image(systemName: game.isPregame ? "calendar" : "sparkles")
                        .font(.caption.weight(.semibold))
                    Text(footnoteText)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(leagueColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var liveText: String? {
        game.isLiveGame ? "LIVE" : nil
    }

    private var footnoteText: String {
        if game.isLiveGame {
            return [game.currentPeriodLabel, game.gameClock].compactMap { $0 }.joined(separator: " ").nilIfEmpty ?? "In progress"
        }
        if game.isPregame {
            return "Scheduled"
        }
        return "Catch up"
    }

    private var leagueColor: Color {
        switch game.leagueCode.uppercased() {
        case "MLB": return Color(.systemGreen)
        case "NBA": return Color(.systemOrange)
        case "NHL": return Color(.systemTeal)
        case "NFL": return Color(.systemIndigo)
        case "NCAAB": return Color(.systemPurple)
        case "NCAAF": return Color(.systemBrown)
        default: return Color(.systemBlue)
        }
    }
}

private struct TeamLine: View {
    let abbreviation: String?
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Text(abbreviation ?? shortName)
                .font(.subheadline.weight(.black))
                .monospaced()
                .foregroundStyle(.primary)
                .frame(width: 44, alignment: .leading)
            Text(name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var shortName: String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}

private struct TimelineDayHeader: View {
    let section: HomeTimelineSection

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(section.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(section.isToday ? Color(.systemTeal) : .primary)
            Text(section.subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .textCase(nil)
        .padding(.top, 12)
    }
}

private struct TodayEmptyRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .foregroundStyle(Color(.systemTeal))
            Text("No games on today's slate for these filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.75), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No games in this window",
            systemImage: "calendar.badge.exclamationmark",
            description: Text("Try another league or team filter.")
        )
    }
}

private struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "Unable to load games",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
